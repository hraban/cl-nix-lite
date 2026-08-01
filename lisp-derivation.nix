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

{
  callPackage,
  pkgs,
  lib,
  lisp,
}:

let
  utils = callPackage ./utils.nix { };

  # Use strings to avoid interning keyword symbols and polluting the namespace
  lispAsdfOp = { operation, system }: "(${operation} ${builtins.toJSON system})";

  # CLISP directly translates require calls to a filename, without case
  # conversion, and of course with CL being uppercase by default i.e. (require
  # :asdf) being (require :ASDF), whether that works or not depends on the case
  # sensitivity of your filesystem. Not ideal. So use a string here to ensure we
  # can find the (lowercase) asdf.lisp.
  asdfOpScript =
    operation:
    if builtins.isString operation then
      asdfOpScript ([ operation ])
    else
      name: system:
      builtins.toFile (lib.strings.sanitizeDerivationName "asdf-build-${name}.lisp") ''
        (require "asdf")
        ${builtins.concatStringsSep "\n" (
          map lispAsdfOp (lib.cartesianProduct { inherit operation system; })
        )}
      '';

  # [a] -> [a] -> Boolean
  #
  # Whether the first argument is a weak superset of the second argument.
  isSuperset = a: lib.all (x: builtins.elem x a);

  # Build a lisp derivation from this source, for the specific given
  # systems. When two separate packages include the same src, but both for a
  # different system, it resolves to the same derivation.
  lispDerivation = lib.extendMkDerivation {
    constructDrv = pkgs.stdenv.mkDerivation;
    excludeDrvArgNames = [
      "lispDependencies"
      "lispCheckDependencies"
      "lispBuildOp"
      "lispSystem"
      "lispSystems"
    ];
    extendDrvArgs =
      finalAttrs:
      args@{
        # Extra directories to add to the ASDF search path for systems.
        # Shouldn’t be necessary—only use this to fix external packages you
        # don’t control.  For your own packages, I recommend putting all the
        # .asds in your root directory.
        lispAsdPath ? [ ],
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
        lispBuildOp ? (
          [ "asdf:make" ] ++ lib.optionals (lisp.name == "ecl") [ "asdf:operate 'asdf:lib-op" ]
        ),
        src,
        ...
      }:
      assert (args ? lispSystem) != (args ? lispSystems);
      let
        lispDependencies =
          (args.lispDependencies or [ ])
          # lispCheckDependencies is deprecated and will be removed in a
          # future version.  Do not use.
          ++ lib.optionals (finalAttrs.doCheck or false) (args.lispCheckDependencies or [ ]);
        lispSystems = args.lispSystems or [ args.lispSystem ];
        myOrigSrc = utils.derivPath src;
        name = args.name or (lib.concatStringsSep "_" finalAttrs.lispSystems);
        getDepsShallow = drv: drv.passthru._origLispDependencies or [ ];
        deps =
          let
            foldSrc = drv: init: lib.foldl' f init (getDepsShallow drv);
            f =
              # acc: { srcPath :: derivation }
              # x: derivation
              # returns: { srcPath :: derivation }
              acc: x:
              let
                depth = foldSrc x acc;
                key = x.passthru._origSrc;
                depthNode = depth.${key};
                depthSystems = depthNode.lispSystems or [ ];
              in
              assert (depth ? ${key}) -> (depthNode == src) != (depthNode ? lispSystems);
              depth
              // {
                ${key} =
                  if ((!(depth ? ${key})) || (isSuperset x.lispSystems depthSystems)) then
                    x
                  else if (isSuperset depthSystems x.lispSystems) then
                    depthNode
                  else
                    x.overrideAttrs (old: {
                      src = depthNode;
                      lispSystems = lib.uniqueStrings (old.lispSystems ++ depthSystems);
                    });
              };
          in
          foldSrc finalAttrs { ${myOrigSrc} = src; };
        myDeps = builtins.attrValues (builtins.removeAttrs deps [ myOrigSrc ]);
        # All derivations I depend on, directly or indirectly, without me. Sort
        # deterministically to avoid rebuilding the same derivation just because
        # the order of dependencies was different (in the envvar).
        allDepsPaths = lib.pipe myDeps [
          (map (d: [ (builtins.toString d) ] ++ (map (x: "${d}/${x}") (d.lispAsdPath or [ ]))))
          lib.flatten
          lib.naturalSort
        ];
        # The search path for ASDF at build time. Includes the build
        # directory. Must be :-join’ed and eval’ed before use. NOT for run time.
        # Do not bake this into the final derivation.
        buildTimeAsdPath = [
          "$PWD"
        ]
        ++ (map (x: "$PWD/${x}") (finalAttrs.lispAsdPath or [ ]))
        ++ allDepsPaths;
      in
      {
        __structuredAttrs = args.__structuredAttrs or true;
        inherit name lispAsdPath lispSystems;
        src = deps.${myOrigSrc};
        passthru = {
          lisp = lisp;
          _origLispDependencies = lispDependencies;
          _origLispSystems = lispSystems;
          _origSrc = myOrigSrc;
          # Legacy, will be removed in next version
          enableCheck = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
        }
        // args.passthru or { };
        # Store .fasl files next to the respective .lisp file
        env = {
          ASDF_OUTPUT_TRANSLATIONS = "/:/";
        }
        // args.env or { };
        # Set this as a separate phase because I’m scared of shell escaping and
        # spaces in hooks. Technically this works if I just add it as a raw
        # preConfigure or preBuild hook, but I’d rather take an extra step and
        # expose a single identifier as a function to execute.
        setAsdfPathPhase = ''
          export CL_SOURCE_REGISTRY="''${CL_SOURCE_REGISTRY+$CL_SOURCE_REGISTRY:}${builtins.concatStringsSep ":" buildTimeAsdPath}"
        '';
        preConfigurePhases = args.preConfigurePhases or [ ] ++ [ "setAsdfPathPhase" ];
        buildPhase =
          args.buildPhase or ''
            runHook preBuild

            ${lisp.call (asdfOpScript lispBuildOp name finalAttrs.lispSystems)}

            runHook postBuild
          '';
        installPhase =
          args.installPhase or ''
            runHook preInstall

            cp -R "." "$out"

            runHook postInstall
          '';
        checkPhase =
          args.checkPhase or ''
            runHook preCheck

            ${lisp.call (asdfOpScript "asdf:test-system" name finalAttrs.lispSystems)}

            runHook postCheck
          '';
        # Put this one at the very end because we don’t override the
        # user-specified shellHook; we extend it, if it exists. So this is a
        # non-destructive operation.
        shellHook =
          let
            allDepsNames = utils.normaliseStrings (utils.flatMap (d: d.lispSystems) myDeps);
            allDepsHumanReadable = lib.concatStringsSep ", " allDepsNames;
          in
          args.shellHook or ''
            eval "$setAsdfPathPhase"
            >&2 cat <<EOF
            Lisp dependencies available to ASDF: ${allDepsHumanReadable}.
            (see \$CL_SOURCE_REGISTRY for full paths.)

            Example:

                $ ${lisp.name}
                > (require "asdf")${
                  if allDepsNames != [ ] then
                    "
    > (asdf:load-system ${builtins.toJSON (builtins.head allDepsNames)})"
                  else
                    ""
                }

            The working directory's systems are also available, if any.
            EOF
          ''
          + (args.shellHook or "");
        # Always include the lisp we used in the nativeBuildInputs, mostly for
        # shellHook purposes: having it here puts it automatically on the PATH
        # of a devshell. This is definitely what you want, particularly for
        # flakes which are likely to be running a few SBCL versions behind, or
        # users without global SBCL installed in the first place.
        nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ lisp.deriv ];
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
        buildInputs = (args.buildInputs or [ ]) ++ myDeps;
        meta = (args.meta or { }) // {
          # Being aggressive about finding a broken flag in my dependencies
          # helps surfacing it early enough for a wrapping tryEval to catch
          # it. See the implementation of the “test-all” example and try
          # e.g. to mark alexandria as broken; that should “work”, meaning you
          # shouldn’t get eval errors, just fewer packages is all. This fixes
          # that. I don’t know /exactly/ why, but it can’t hurt.
          broken = (args.meta.broken or false) || (builtins.any (d: d.meta.broken or false) myDeps);
        };
      };
  };

  # If a single src derivation specifies multiple lisp systems, you can use this
  # helper to define them.
  lispMultiDerivation =
    args:
    lib.mapAttrs (
      name: system:
      let
        namearg = lib.optionalAttrs (!((system ? lispSystem) && (system ? lispSystems))) {
          lispSystem = name;
        };
      in
      # Default system name is the derivation name in the containing ‘systems’
      # attrset, but can be overridden if the Lisp name is incompatible with Nix
      # identifiers.
      lispDerivation ((removeAttrs args [ "systems" ]) // namearg // system)
    ) args.systems;

  # Get a binary executable lisp which can load the given systems from ASDF
  # without any extra setup necessary.
  lispWithSystems =
    systems:
    lispDerivation {
      inherit (lisp.deriv) name;
      lispSystems = [ "" ];
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
  lispScript =
    {
      name,
      src,
      dependencies ? [ ],
      ...
    }@args:
    pkgs.stdenv.mkDerivation (
      {
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
        }
        // (args.meta or { });
      }
      // (builtins.removeAttrs args [ "dependencies" ])
    );
in
{
  inherit
    lispDerivation
    lispMultiDerivation
    lispWithSystems
    lispScript
    ;
}
