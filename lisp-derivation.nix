# Copyright © 2022–2024  Hraban Luyat
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

{ pkgs
, callPackage
, lisp
}:

with {
  inherit (pkgs) lib;
};
with pkgs.lib;
with callPackage ./utils.nix {};

let
  # Use strings to avoid interning keyword symbols and polluting the namespace
  lispAsdfOp = { operation, system }: "(${operation} ${builtins.toJSON system})";

  # CLISP directly translates require calls to a filename, without case
  # conversion, and of course with CL being uppercase by default i.e. (require
  # :asdf) being (require :ASDF), whether that works or not depends on the case
  # sensitivity of your filesystem. Not ideal. So use a string here to ensure we
  # can find the (lowercase) asdf.lisp.
  asdfOpScript = operation:
    if b.isString operation
    then asdfOpScript ([ operation ])
    else name: system: builtins.toFile (lib.strings.sanitizeDerivationName "asdf-build-${name}.lisp") ''
      (require "asdf")
      ${b.concatStringsSep "\n"
        (map lispAsdfOp (a.cartesianProduct { inherit operation system; }))}
    '';
in

rec {
  # Build a lisp derivation from this source, for the specific given
  # systems. When two separate packages include the same src, but both for a
  # different system, it resolves to the same derivation.
  lispDerivation = {
    # The system(s) defined by this derivation
    lispSystem ? null,
    lispSystems ? null,
    # The lisp dependencies FOR this derivation
    lispDependencies ? [],
    lispCheckDependencies ? [],
    CL_SOURCE_REGISTRY ? "",
    # If you were to build this from source. Not necessarily the final src of
    # the actual derivation; that depends on the dependency chain.
    src,
    doCheck ? false,

    # Example:
    #
    # - lispBuildOp = "asdf:make",
    # - lispBuildOp = "asdf:load-system",
    # - lispBuildOp = "asdf:operate 'asdf:load-op",
    # - lispBuildOp = "asdf:operate 'asdf:compile-bundle-op",
    # - lispBuildOp = "asdf:operate 'asdf:monolithic-deliver-asd-op"
    #
    # If you control the source, though, you are much better off configuring the
    # defsystem in the .asd to do the right thing when called as ‘make’.
    # Finally, a list of strings indicates multiple ASDF operations to execute
    # sequentially. The default is to call ‘make’ (for compatibility with the
    # defsystem’s :build-operation directive in the .asd file), and additionally
    # the 'asdf:lib-op operation on ECL (particularly for ECL to create a
    # library .a file which can be loaded by future dependents).
    lispBuildOp ? ([ "asdf:make" ] ++
                   optionals (lisp.name == "ecl") [ "asdf:operate 'asdf:lib-op" ]),

    # Extra directories to add to the ASDF search path for systems. Shouldn’t be
    # necessary—only use this to fix external packages you don’t control. For
    # your own packages, I urge you to put all the .asds in your root
    # directory. This argument is localized, i.e. it can be either a literal
    # value, or it can be a 1-arg function accepting a list of systems for which
    # this final derivation is being built, and return any value it wants
    # depending on that list.
    lispAsdPath ? [],

    # As the name suggests:
    # - this is a private arg for internal recursion purposes -- do not use
    # - this indicates whether I want to deduplicate myself. It is used to
    #   terminate the self deduplication recursion without segfaulting.
    _lispDontDeduplicate ? false,

    ...
  } @ args:
    let
      # Normalised value of the systems argument to this derivation. All
      # internal access to that arg ("what system(s) am I loaded with?") should
      # be through this value.
      lispSystemsArg =
        # Mutually exclusive args but one is required. XOR. Tested lazily on
        # actual use only.
        assert (lispSystem == null) != (lispSystems == null);
        args.lispSystems or [ args.lispSystem ];

      ancestry = ancestryWalker {
        inherit me;
        key = drv: derivPath drv.origSrc;
        dependencies = lispDependencies ++ (optionals doCheck lispCheckDependencies);
        # (There is probably a neater, more idiomatic way to do this overriding
        # business.)
        merge = other:
          # CAREFUL!! You can merge recursively! That means the body of this
          # function must not evaluate any properties that cause any recursive
          # properties to be evaluated. This only works because Nix is lazily
          # evaluated.
          # Not technically necessary but it makes for slightly cleaner API.
          assert isLispDeriv other;
          assert derivPath _lispOrigSrc == derivPath other.origSrc;
          let
            # The new arguments that define this merged derivation: which
            # systems do you build, and are you in check mode y/n? The
            # dependencies are automatically inferred when necessary.

            # Don’t get the lispSystems from the original args: we want to
            # know what the final, real collection of lisp system names was
            # that was used for this derivation.
            newLispSystems = normaliseStrings (lispSystems' ++ other.lispSystems);
            newDoCheck = doCheck || other.args.doCheck or false;
          in
            # Only build a new one if it improves on both existing derivations.
            if newDoCheck == other.doCheck && newLispSystems == other.lispSystems
            then other.overrideAttrs (_: { inherit _lispOrigSystems; })
            else if newLispSystems == lispSystems' && (
              # There is no improvement to be had here: I already contain all
              # the final lisp systems, and other is already my src, ergo this
              # would just be a pointless (and eventually infinite)
              # recursion. This happens when a test depends on itself (without
              # test).
              src == other ||
              # N.B.: Only propagate ME if I have equal doCheck to other. This
              # is subtly different from newDoCheck == doCheck. It solves the
              # problem where a doCheck = true depends (transitively) on itself
              # with doCheck false: that should /not/ be deduplicated, because
              # some dependency in the middle clearly depends on me (with
              # doCheck = false), so if I deduplicate I will end up re-building
              # my non-test files here, which will cause a rebuild in that
              # already-built-dependency.
              doCheck == other.doCheck
            )
            then me
            else
              # Patches are removed because I assume the source to already have
              # been patched by now. For it is myself.
              lispDerivation ((removeAttrs args ["patches" "lispSystem"]) // {
                # By this point, we assume that this top level derivation
                # contains all its own recursive self-dependencies and doesn’t
                # need any more deduplication.
                _lispDontDeduplicate = true;
                # These args are "carried over" from the original, “human”
                # invocation of lispDerivation. These args are safe across
                # deduplication.
                inherit _lispOrigSystems _lispOrigSrc;
                lispDependencies = l.unique (lispDependencies ++ other.args.lispDependencies or []);
                lispCheckDependencies = l.unique (lispCheckDependencies ++ other.args.lispCheckDependencies or []);
                doCheck = newDoCheck;
                lispSystems = newLispSystems;
                # Important: we assume all the other args are automatically
                # compatible for the new derivation, notably buildPhase,
                # patches, etc. This means you can’t define two separate
                # systems from the same source (foo-b and foo-c) and give each
                # a distinct buildPhase--rather, you must define a single
                # buildPhase as a function which takes an array of system
                # names as an arg, and decides based on that arg what to
                # do. There is special support for this in the lispDerivation.

                # And now for the pièce de résistence:
                src = other;
              });
      };

      # All derivations I depend on, directly or indirectly, without me. Sort
      # deterministically to avoid rebuilding the same derivation just because
      # the order of dependencies was different (in the envvar).
      allDepsPaths = pipe ancestry.deps [
        (map (d: [ (b.toString d) ] ++ (map (x: "${d}/${x}") (d.lispAsdPath or []))))
        flatten
        l.naturalSort
      ];

      # The search path for ASDF at build time. Includes the build
      # directory. Must be :-join’ed and eval’ed before use. NOT for “release”
      # time! Do not bake this into the final derivation.
      buildTimeAsdPath =
        [ "$PWD" ] ++
        # Must localize the path first because it depends on which systems are
        # being built
        (map (x: "$PWD/${x}") (localizedArgs.lispAsdPath or [])) ++
        allDepsPaths;

      ####
      #### THE FINAL DERIVATION
      ####

      # I use naturalSort because it’s an easy way to sort a list strings in Nix
      # but any sort will do. What’s important is that this is deterministically
      # sorted.
      lispSystems' = normaliseStrings lispSystemsArg;
      # Clean out the arguments to this function which aren’t deriv props. Leave
      # in the systems because it’s a useful and harmless prop.
      derivArgs = removeAttrs args ["lispDependencies" "lispCheckDependencies" "lispSystem" "_lispDontDeduplicate" "_lispOrigSrc"];
      pname = args.pname or "${b.concatStringsSep "_" lispSystems'}";

      # Add here all "standard" derivation args which are system
      # dependent. Meaning these can be either strings as per, or functions, in
      # which case they will be called with the set of systems enabled for this
      # derivation. This is used to fix auto deduplication (unioning / joining)
      # of lisp derivations.
      stdArgs = [
        # Standard args that are not phases
        "setupHooks"
        "patches"
        "outputs"
        "shellHook"
        "makeFlags"
        "meta"

        # All dependencies
        "depsBuildBuild"
        "nativeBuildInputs"
        "depsBuildTarget"
        "depsHostHost"
        "buildInputs"
        "depsTargetTarget"
        "depsBuildBuildPropagated"
        "propagatedNativeBuildInputs"
        "depsBuildTargetPropagated"
        "depsHostHostPropagated"
        "propagatedBuildInputs"
        "depsTargetTargetPropagated"

        # Am I forgetting anything?

        # And a custom property which is also useful to vary per system
        "lispAsdPath"

        # All the phases
        "preUnpack"
        "unpackPhase"
        "postUnpack"

        "prePatch"
        "patchPhase"
        "postPatch"

        "preConfigure"
        "configurePhase"
        "postConfigure"

        "preBuild"
        "buildPhase"
        "postBuild"

        "preCheck"
        "checkPhase"
        "postCheck"

        "preInstall"
        "installPhase"
        "postInstall"

        "preFixup"
        "fixupPhase"
        "postFixup"

        "preDist"
        "distPhase"
        "postDist"
      ];
      localizedArgs = a.mapAttrs (_: callIfFunc lispSystems') (optionalKeys stdArgs args);

      # Secret arg to track how we were originally invoked by the end user. This
      # only matters for tests: for regular builds, you want to ‘make’
      # everything, but for tests you specifically really only want to test the
      # specific system that was originally requested. This matters because
      # tracking test dependencies can become tricky. Don’t forget that merging
      # transitively dependent lisp systems for the same source repository into
      # a single derivation is only really a convenience feature to help marry
      # Nix and ASDF; it is not in fact something that the user necessarily
      # cares about.
      _lispOrigSystems = args._lispOrigSystems or lispSystems';
      _lispOrigSrc = args._lispOrigSrc or src;

      # The final derivation: me. Technically this is used as INPUT to the
      # deduplicator, so you would think this isn’t really the "final" me, but
      # because of lazy evaluation, it actually ALSO is the “final me”. As in:
      # the one that is used for input, doesn’t survive, so you can safely
      # assume that if you’re referring to this “me”, that (by definition)
      # you’re talking to the “final” one, with deduplicated dependencies and
      # all. It’s a mind-bend, welcome to lazy evaluation.
      me = pkgs.stdenv.mkDerivation (derivArgs // {
        lispSystems = lispSystems';
        name = args.name or "system-${pname}";
        passthru = (derivArgs.passthru or {}) // {
          inherit
            ancestry
            # Give others access to the args with which I was built
            args;
          # The original, non-deduplicated src we were called with
          origSrc = _lispOrigSrc;
          enableCheck = if doCheck
                        then me
                        else lispDerivation (args // { doCheck = true; });
          # Helper attribute for outsiders who want access to the underlying
          # search path. This path only contains the dependencies. Putting this
          # in passthru, not the derivation itself, to stay conservative for
          # now. It might be useful as a first-class derivation property but I’m
          # not sure yet.
          asdSearchPath = allDepsPaths;
        };
        # Store .fasl files next to the respective .lisp file
        ASDF_OUTPUT_TRANSLATIONS = "/:/";
        # Set this as a separate phase because I’m scared of shell escaping and
        # spaces in hooks. Technically this works if I just add it as a raw
        # preConfigure or preBuild hook, but I’d rather take an extra step and
        # expose a single identifier as a function to execute.
        setAsdfPathPhase = ''
          export CL_SOURCE_REGISTRY="''${CL_SOURCE_REGISTRY+$CL_SOURCE_REGISTRY:}${b.concatStringsSep ":" buildTimeAsdPath}"
        '';
        preConfigurePhases = [ "setAsdfPathPhase" ];
        # Like lisp-modules-new, pre-build every package independently.
        #
        # Reason to do this: packages like libuv contain quite complex build
        # steps, and letting the final derivation do all the work becomes
        # untenable.
        #
        # Client is free to override this if they know better.
        buildPhase = ''
          runHook preBuild

          ${lisp.call (asdfOpScript lispBuildOp pname lispSystems')}

          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall

          cp -R "." "$out"

          runHook postInstall
        '';
        checkPhase = ''
          runHook preCheck

          ${lisp.call (asdfOpScript "asdf:test-system" pname _lispOrigSystems)}

          runHook postCheck
        '';
      } // localizedArgs // {
        meta = (localizedArgs.meta or {}) // {
          # Being aggressive about finding a broken flag in my dependencies
          # helps surfacing it early enough for a wrapping tryEval to catch
          # it. See the implementation of the “test-all” example and try
          # e.g. to mark alexandria as broken; that should “work”, meaning you
          # shouldn’t get eval errors, just fewer packages is all. This fixes
          # that. I don’t know /exactly/ why, but it can’t hurt.
          broken = (localizedArgs.meta.broken or false) ||
                   (builtins.any (d: d.meta.broken or false) ancestry.deps);
        };
        # Always include the lisp we used in the nativeBuildInputs, mostly for
        # shellHook purposes: having it here puts it automatically on the PATH
        # of a devshell. This is definitely what you want, particularly for
        # flakes which are likely to be running a few SBCL versions behind, or
        # users without global SBCL installed in the first place.
        nativeBuildInputs = (localizedArgs.nativeBuildInputs or []) ++ [ lisp.deriv ];
        # Put this one at the very end because we don’t override the
        # user-specified shellHook; we extend it, if it exists. So this is a
        # non-destructive operation.
        shellHook = let
          allDepsNames = pipe ancestry.deps [
            (flatMap (d: d.lispSystems))
            normaliseStrings
          ];
          allDepsHumanReadable = s.concatStringsSep ", " allDepsNames;
        in ''
eval "$setAsdfPathPhase"
>&2 cat <<EOF
Lisp dependencies available to ASDF: ${allDepsHumanReadable}.
(see \$CL_SOURCE_REGISTRY for full paths.)

Example:

    $ ${lisp.name}
    > (require "asdf")${if allDepsNames != [] then "
    > (asdf:load-system ${builtins.toJSON (builtins.head allDepsNames)})" else ""}

The working directory's systems are also available, if any.
EOF
'' + (localizedArgs.shellHook or "");
        # WIP! To use stdenv features (e.g. shell hooks) in lisp derivations,
        # they must be registered as buildInputs, otherwise stdenv’s setup
        # script can’t find them. This is highly WIP and POC while I learn more
        # about how stdenv works, exactly. It’s quite tricky. Never mind cross
        # compilation!
        # TODO: This is a sign that we probably need to change
        # “lispDependencies” to a more generic structure of
        # e.g. lispBuildInputs, lispNativeBuildInputs, etc etc, and
        # automatically map these onto their non-lisp counterparts. Or maybe go
        # even more radical and extract any known lisp derivation from the
        # buildInputs etc arrays, and automatically resolve their entire
        # dependency graph? One way or another, something needs to change,
        # because defaulting everything to buildInputs is clearly wrong. I would
        # probably also need to figure out what cross compilation actually means
        # in the land of lisp, and write some example derivations.
        buildInputs = (localizedArgs.buildInputs or []) ++ ancestry.deps;
      });

    in
      if !_lispDontDeduplicate
      then ancestry.me
      else me;

  # If a single src derivation specifies multiple lisp systems, you can use this
  # helper to define them.
  lispMultiDerivation = args: a.mapAttrs (name: system:
    let
      namearg = a.optionalAttrs (! system ? lispSystems) { lispSystem = name; };
    in
      # Default system name is the derivation name in the containing ‘systems’
      # attrset, but can be overridden if the Lisp name is incompatible with Nix
      # identifiers.
      lispDerivation ((removeAttrs args ["systems"]) // namearg // system)
  ) args.systems;

  # Get a binary executable lisp which can load the given systems from ASDF
  # without any extra setup necessary.
  lispWithSystems = systems: lispDerivation {
    inherit (lisp.deriv) name;
    lispSystem = "";
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    src = builtins.toFile "mock" "source";
    dontUnpack = true;
    dontBuild = true;
    lispDependencies = systems;
    # This wrapper is necessary because Nix is just a build environment that
    # delivers executables. Once the binary is built, Nix doesn’t control its
    # environment when it is started--it’s a regular binary. Meaning: we can’t
    # somehow set these envvars in some config, like you could do with
    # e.g. Docker. To set envvars on a binary /at runtime/, you must create a
    # wrapper that does this. Enter ‘makeWrapper’ et al.  N.B.: The final
    # wrapper is a bash script which isn’t ideal for startup speed. This is a
    # good argument for using asdf registry configuration files rather than a
    # big baked envvar.
    installPhase = ''
      mkdir -p $out/bin
      for f in ${lisp.deriv}/bin/*; do
        if [[ -x "$f" && -f "$f" ]]; then
          # ASDF_.. is set, not suffixed, because it is an opaque string, not a
          # search path.
          makeBinaryWrapper $f $out/bin/$(basename $f) \
            ''${CL_SOURCE_REGISTRY+--suffix CL_SOURCE_REGISTRY : $CL_SOURCE_REGISTRY} \
            --set ASDF_OUTPUT_TRANSLATIONS $ASDF_OUTPUT_TRANSLATIONS
        fi
      done
    '';
  };

  # A one-off, simple single-file lisp script with dependencies preloaded.
  #
  # Usage:
  #
  # In your Nix:
  #
  #   lispScript { name = "foo"; dependencies = [ alexandria ]; src = ./foo.lisp; }
  #
  # In foo.lisp:
  #
  #   #!/usr/bin/env sbcl --script
  #
  #   (require "asdf")
  #   (asdf:load-system "alexandria")
  #
  #   (defpackage #:foo
  #     (:use #:cl)
  #     (:local-nicknames (#:alex #:alexandria)))
  #
  #   (in-package #:foo)
  #
  #   (format T "Hello: ~{~A~^, ~}~%" (alex:iota 9))
  #
  # This will create a derivation with in its output a single executable file,
  # /bin/foo, which you can invoke directly. That makes it compatible to declare
  # it e.g. as an entry in a flake’s .outputs.packages.<...>.foo.
  lispScript = { name, src, dependencies ? [], ... }@args: pkgs.stdenv.mkDerivation ({
    dontUnpack = true;
    buildInputs = [ (lispWithSystems dependencies) ];
    installPhase = ''
      runHook preInstall

      # This is the most reliable way to get a predictable folder structure with
      # obvious permissions set etc
      mkdir -p "$out/bin"
      cat "$src" > "$out/bin/${name}"
      chmod +x "$out/bin/${name}"

      runHook postInstall
    '';
    meta = {
      mainProgram = name;
    } // (args.meta or {});
  } // (builtins.removeAttrs args [ "dependencies" ]));
}
