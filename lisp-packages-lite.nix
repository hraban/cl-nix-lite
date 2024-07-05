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
  inputs
, pkgs
}:

with {
  inherit (pkgs) lib;
};

rec {
  lispPackagesLite = lispPackagesLiteFor pkgs.sbcl; # The King ❤️
  # The lisp is a function which takes a file and returns a shell invocation
  # calling that file, then exiting. Or just a derivation of a known Lisp,
  # e.g. lisp = pkgs.sbcl.
  lispPackagesLiteFor = lisp': lib.recurseIntoAttrs (lib.makeScope pkgs.newScope (self:
    with self;
    with callPackage ./utils.nix {};
    with {
      lisp = makeLisp lisp';
    };
    with callPackage ./lisp-derivation.nix { inherit lisp; };

    let
      lispify = name: lispDependencies:
        lispDerivation {
          inherit lispDependencies;
          lispSystem = name; # convention
          src = inputs.${name};
        };
    in {
    inherit lispDerivation lispMultiDerivation lispWithSystems lispScript;

    "1am" = lispify "1am" [];

    inherit (lispMultiDerivation {
      src = inputs."3bmd";
      systems = {
        "3bmd" = {
          lispDependencies = [ alexandria esrap split-sequence ];
          lispCheckDependencies = [ self."3bmd-ext-code-blocks" fiasco ];
        };
        "3bmd-ext-code-blocks" = {
          lispDependencies = [ self."3bmd" alexandria colorize split-sequence ];
        };
        "3bmd-ext-tables" = {
          lispDependencies = [
            self."3bmd"
          ];
        };
      };
    }) "3bmd"
       "3bmd-ext-code-blocks"
       "3bmd-ext-tables";

    "3d-math" = lispDerivation {
      lispDependencies = [ documentation-utils type-templates ];
      lispCheckDependencies = [ parachute ];
      src = inputs."3d-math";
      # For ABCL, if that would fix it: _JAVA_OPTIONS="-Xmx4g";
      env = lib.optionalAttrs (lisp.name == "sbcl") {
        NIX_SBCL_DYNAMIC_SPACE_SIZE = "4gb";
      };
      lispSystem = "3d-math";
      # Compiling this on CLISP hangs forever.
      # On ECL:
      # * The declaration (DECLARE (FTYPE (FUNCTION ((OR IVEC4 DVEC4 VEC4 IVEC3 DVEC3 VEC3 IVEC2 DVEC2 VEC2)) (VALUES (OR I32 F64 F32) &OPTIONAL)) VX)) was found in a bad place.
      meta.broken = b.elem lisp.name [ "clisp" "ecl" "abcl" ];
    };

    "3d-vectors" = lispDerivation {
      lispDependencies = [ documentation-utils ];
      lispCheckDependencies = [ parachute ];
      src = inputs."3d-vectors";
      lispSystem = "3d-vectors";
    };

    inherit (lispMultiDerivation {
      src = inputs."40ants-doc";
      systems = {
        "40ants-doc" = {
          lispDependencies = [
            cl-ppcre
            commondoc-markdown
            named-readtables
            pythonic-string-reader
            slynk
            str
            swank
          ];
          lispCheckDependencies = [
            rove
            self."40ants-doc-full"
          ];
        };
        "40ants-doc-full" = {
          lispDependencies = [
            self."40ants-doc"
            cl-fad
            commondoc-markdown
            dexador
            docs-builder
            fare-utils
            jonathan
            lass
            pythonic-string-reader
            slynk
            spinneret
            stem
            str
            swank
            tmpdir
            trivial-extract
            xml-emitter
          ];
        };
      };
    }) "40ants-doc" "40ants-doc-full";

    "40ants-asdf-system" = lispDerivation {
      lispSystem = "40ants-asdf-system";
      src = inputs."40ants-asdf-system";
      # Depends on a modern ASDF. SBCL’s built-in ASDF crashes this. Explicitly
      # listing self. here to avoid grabbing nixpkgs.asdf.
      lispDependencies = [ self.asdf ];
      lispCheckDependencies = [ rove ];
    };

    access = lispDerivation {
      lispSystem = "access";
      src = inputs.access;
      lispDependencies = [ alexandria closer-mop iterate cl-ppcre ];
      lispCheckDependencies = [ lisp-unit2 ];
    };

    acclimation = lispify "acclimation" [];

    alexandria = lispDerivation {
      lispSystem = "alexandria";
      src = inputs.alexandria;
      # Contrary to what its .asd file suggests, Alexandria now requires rt even
      # on SBCL. This is recent (introduced after v1.4).
      lispCheckDependencies = [ rt ];
    };

    alien-ring = lispify "alien-ring" [ cffi trivial-gray-streams ];

    anaphora = lispDerivation {
      lispSystem = "anaphora";
      lispCheckDependencies = [ rt ];
      src = inputs.anaphora;
    };

    anypool = lispDerivation {
      src = inputs.anypool;
      lispSystem = "anypool";
      lispDependencies = [ bordeaux-threads cl-speedy-queue ];
      lispCheckDependencies = [ rove ];
    };

    archive = lispify "archive" [ trivial-gray-streams cl-fad ];

    inherit (lispMultiDerivation {
      src = inputs.arnesi;
      systems = {
        arnesi = {
          lispDependencies = [ collectors ];
          lispCheckDependencies = [ fiveam ];
        };
        arnesi-cl-ppcre-extras = {
          lispSystem = "arnesi/cl-ppcre-extras";
          lispDependencies = [ arnesi cl-ppcre ];
        };
        arnesi-slime-extras = {
          lispSystem = "arnesi/slime-extras";
          lispDependencies = [ arnesi swank ];
        };
      };
      # #<PACKAGE CHARSET> has no external symbol with name "UTF-16"
      meta.broken = lisp.name == "clisp";
    }) arnesi arnesi-cl-ppcre-extras arnesi-slime-extras;

    array-utils = lispDerivation {
      lispSystem = "array-utils";
      lispCheckDependencies = [ parachute ];
      src = inputs.array-utils;
    };

    arrow-macros = lispDerivation {
      lispSystem = "arrow-macros";

      src = inputs.arrow-macros;

      lispDependencies = [ alexandria ];
      lispCheckDependencies = [ fiveam ];
    };

    asdf = lispDerivation {
      # Sometimes a dependent project will try and build asdf/defsystems. I’m
      # not exactly clear on when this happens but it’s fixed by just always
      # precompiling it here.
      lispSystems = [ "asdf" "asdf/defsystem" ];
      src = inputs.asdf;
    };

    asdf-flv = lispDerivation {
      lispSystem = "net.didierverna.asdf-flv";
      src = inputs.asdf-flv;
    };

    asdf-system-connections = lispify "asdf-system-connections" [];

    assoc-utils = lispDerivation {
      lispSystem = "assoc-utils";
      src = inputs.assoc-utils;
      lispCheckDependencies = [ prove ];
    };

    atomics = lispDerivation {
      lispSystem = "atomics";
      src = inputs.atomics;
      lispDependencies = [ documentation-utils ];
      lispCheckDependencies = [ parachute ];
      # CLISP is not supported by the Atomics library.
      # The CAS operation is not supported by Armed Bear Common Lisp in Atomics.
      # This is most likely due to lack of support by the implementation.
      # If you think this is in error, and the implementation does expose
      # the necessary operators, please file an issue at
      #   https://github.com/shinmera/atomics/issues
      meta.broken = b.elem lisp.name [ "abcl" "clisp" ];
    };

    inherit (lispMultiDerivation {
      src = inputs.babel;

      systems = {
        babel = {
          lispDependencies = [ alexandria trivial-features ];
          lispCheckDependencies = [ hu_dwim_stefil ];
        };
        babel-streams = {
          lispDependencies = [ alexandria babel trivial-gray-streams ];
          lispCheckDependencies = [ hu_dwim_stefil ];
        };
      };
    }) babel babel-streams;

    blackbird = lispDerivation {
      lispSystem = "blackbird";
      src = inputs.blackbird;
      lispDependencies = [ vom ];
      lispCheckDependencies = [ cl-async fiveam ];
    };

    bordeaux-threads = lispDerivation rec {
      lispDependencies = [
        alexandria
        global-vars
        trivial-features
        trivial-garbage
      ];
      lispCheckDependencies = [ fiveam ];
      buildInputs = [ pkgs.libuv ];
      lispSystem = "bordeaux-threads";
      src = inputs.bordeaux-threads;
      meta.broken = lisp.name == "clisp" || (lisp.name == "sbcl" && !lisp.deriv.threadSupport);
    };

    inherit (lispMultiDerivation rec {
      src = inputs.cffi;
      patches = ./patches/clffi-libffi-no-darwin-carevout.patch;
      systems = {
        cffi = {
          lispDependencies = [ alexandria babel trivial-features ];
          lispCheckDependencies = [ cffi-grovel bordeaux-threads rt ];
          # I don’t know if cffi-libffi is external but it doesn’t seem to be
          # so just leave it for now.
        };
        cffi-grovel = {
          # cffi-grovel depends on cffi-toolchain. Just specifying it as an
          # exported system works because cffi-toolchain is specified in this
          # same source derivation.
          lispSystems = [ "cffi-grovel" "cffi-toolchain" ];
          lispDependencies = [ alexandria cffi trivial-features ];
          lispCheckDependencies = [ bordeaux-threads rt ];
        };
      };
      # lisp-modules-new doesn’t specify GCC and somehow it works fine. Is
      # there an accidental transitive dependency, there? Is that because GCC is
      # included through mkDerivation, and its setupHook is automatically
      # triggered? Or how is this solved? Additionally, this only seems to be
      # used by a pretty incidental make call, because the only rule that uses
      # GCC just happens to be at the top, making it the default make
      # target. Not sure if this is the ideal way to “build” this package.
      # Note: Technically this will always be required because cffi-grovel
      # depends on cffi bare, but it’s a good litmus test for the system.
      nativeBuildInputs = with pkgs; [
        pkg-config
        gcc
      ];
      propagatedBuildInputs = with pkgs; l.optionals stdenv.isDarwin [
        # On Darwin, osicat needed access to the libtool package. I have a
        # feeling that’s because of CFFI, and CFFI should provide it, but
        # honestly I don’t know if this is the right place. Maybe I should just
        # make osicat define this as a nativeBuildInput?
        xcbuild
      ];
      buildInputs = systems: l.optionals (b.elem "cffi" systems) [ pkgs.libffi ];
      # This is broken on Darwin because libcffi rewrites the import path in a
      # way that’s incompatible with pkgconfig. It should be "if darwin AND (not
      # pkg-config)".

      setupHooks = systems: l.optionals (b.elem "cffi" systems) [(
        if pkgs.hostPlatform.isDarwin
        # LD_.. only works with CFFI on Mac, but not with
        # sb-alien:load-shared-object. DYLD_.. works with both.
        then builtins.toFile "cffi-setup-hook-darwin.sh" (builtins.replaceStrings
          [ "LD_LIBRARY_PATH" ]
          [ "DYLD_LIBRARY_PATH" ]
          (builtins.readFile ./cffi-setup-hook.sh ))
        else ./cffi-setup-hook.sh
      )];
      meta = systems: a.optionalAttrs (b.elem "cffi" systems) {
        # CFFI requires CLISP compiled with dynamic FFI support, which only
        # enabled on Linux. And it’s supposed to work with ABCL but I don’t know
        # how, so I’m marking this broken for now.
        broken = ! (lisp.name == "clisp" -> pkgs.stdenv.isLinux) ||
                 lisp.name == "abcl";
      };
    }) cffi cffi-grovel;

    calispel = lispDerivation {
      lispSystem = "calispel";
      src = inputs.calispel;
      lispDependencies = [ jpl-queues bordeaux-threads ];
      lispCheckDependencies = [ eager-future2 ];
    };

    chipz = lispify "chipz" [ ];

    chunga = lispify "chunga" [ trivial-gray-streams ];

    inherit (lispMultiDerivation {
      src = inputs.coalton;
      systems = {
        coalton = {
          lispDependencies = [
            alexandria
            concrete-syntax-tree
            eclector
            eclector-concrete-syntax-tree
            float-features
            fset
            named-readtables
            split-sequence
            trivia
            trivial-garbage
          ];
          lispCheckDependencies = [
            fiasco
            coalton-examples
          ];
        };
        coalton-examples = {
          lispSystems = [
            "coalton-json"
            "quil-coalton"
            "small-coalton-programs"
            "thih-coalton"
          ];
          lispDependencies = [ coalton json-streams ];
          lispCheckDependencies = [ fiasco ];
        };
        coalton-benchmarks = {
          lispSystem = "coalton/benchmarks";
          lispDependencies = [
            coalton
            trivial-benchmark
            yason
          ];
        };
        coalton-doc = {
          lispSystem = "coalton/doc";
          lispDependencies = [
            coalton
            html-entities
            yason
          ];
        };
      };
      # Technically coalton is always a dependency so any derivation will always
      # include coalton so this could just hard-code the list, but I like to be
      # explicit about it for the sake of clarity.
      propagatedBuildInputs = systems: l.optionals (b.elem "coalton" systems) [
        # Actual dependencies
        pkgs.mpfr
        pkgs.libuv
        # For the dynamic loading setup hook, even though we don’t even use
        # CFFI. Needs better UX.
        cffi
      ];
      preBuild = let
        testDirectories = [
          "$PWD/examples/coalton-json"
          "$PWD/examples/quil-coalton"
          "$PWD/examples/small-coalton-programs"
          "$PWD/examples/thih"
        ];
        testPaths = b.concatStringsSep ":" testDirectories;
      in ''
        export CL_SOURCE_REGISTRY="${testPaths}:$CL_SOURCE_REGISTRY"
      '';
      meta = {
        # Broken since the last update and I can’t exactly figure out why.
        broken = true;
      };
    }) coalton coalton-benchmarks coalton-doc coalton-examples;

    circular-streams = lispDerivation {
      lispSystem = "circular-streams";
      src = inputs.circular-streams;
      lispDependencies = [ fast-io trivial-gray-streams ];
      lispCheckDependencies = [ cl-test-more flexi-streams ];
    };

    cl-annot = lispDerivation {
      lispSystem = "cl-annot";
      src = inputs.cl-annot;
      lispDependencies = [ alexandria ];
      lispCheckDependencies = [ cl-test-more ];
    };

    cl-ansi-text = lispDerivation {
      lispSystem = "cl-ansi-text";
      src = inputs.cl-ansi-text;
      lispDependencies = [ alexandria cl-colors2 ];
      lispCheckDependencies = [ fiveam ];
    };

    inherit (lispMultiDerivation rec {
      name = "cl-async";

      src = inputs.cl-async;

      systems = {
        cl-async = {
          # ECL wants an archive file (.a) for every dependent /system/ (not
          # just source derivation) when it creates a binary for an
          # application. Since cl-async has this cl-async-base system
          # internally, if it doesn’t exist ECL will create a cl-async-base.a
          # file at build time of a dependent system, which obviously leads to a
          # nix store read-only violation. What I hate about this: it’s a
          # violation of the entire cl-nix-lite premise of “you don’t have to
          # declare internal systems, just external ones”, only for the sake of
          # ECL. Am I going to have to do this for every package now? I’m not
          # looking forward to it. On the other hand: who cares? As always, I’ll
          # just fix it here for now and see where this takes me further down
          # the road. - hraban 2023-10
          lispSystems = [ "cl-async" "cl-async-base" "cl-async-util" ];
          lispDependencies = [
            babel
            bordeaux-threads
            cffi
            cffi-grovel
            cl-libuv
            cl-ppcre
            fast-io
            static-vectors
            trivial-features
            trivial-gray-streams
            vom
          ];
        };

        cl-async-repl = {
          lispDependencies = [ bordeaux-threads cl-async ];
        };

        cl-async-ssl = {
          lispDependencies = [ cffi cl-async vom ];
        };
      };

      propagatedBuildInputs = systems: l.optionals (builtins.elem "cl-async-ssl" systems) [
        pkgs.openssl
      ];
    }) cl-async cl-async-repl cl-async-ssl;

    cl-base64 = lispDerivation rec {
      lispSystem = "cl-base64";
      version = "577683b18fd880b82274d99fc96a18a710e3987a";
      src = inputs.cl-base64;
      lispCheckDependencies = [ ptester kmrcl ];
    };

    cl-change-case = lispDerivation {
      lispSystem = "cl-change-case";
      src = inputs.cl-change-case;
      lispDependencies = [
        cl-ppcre
        cl-ppcre-unicode
      ];
      lispCheckDependencies = [ fiveam ];
    };

    cl-colors = lispDerivation {
      lispSystem = "cl-colors";
      lispCheckDependencies = [ lift ];
      lispDependencies = [ alexandria let-plus ];
      src = inputs.cl-colors;
    };

    cl-colors2 = lispDerivation {
      lispSystem = "cl-colors2";
      src = inputs.cl-colors2;
      lispDependencies = [ alexandria cl-ppcre parse-number ];
      lispCheckDependencies = [ clunit2 ];
    };

    inherit (lispMultiDerivation {
      src = inputs.cl-containers;
      systems = {
        cl-containers = {
          lispDependencies = [ metatilities-base ];
          lispCheckDependencies = [ lift ];
        };
        # This is an infectious dependency which, if available on the search
        # path at all, will cause cl-containers to start compiling some extra of
        # its files. This must of course happen at build time of cl-containers,
        # otherwise it happens in the nix store which will fail. So if if you
        # are a dependent of cl-containers and you, or any of your dependencies,
        # depend on asdf-system-connections, you must include this version of
        # cl-containers lest you get a build error.
        "cl-containers/with-asdf-system-connections" = {
          lispSystems = [
            "cl-containers/with-moptilities"
            "cl-containers/with-utilities"
            "cl-containers/with-variates"
          ];
          lispDependencies = [
            cl-containers
            asdf-system-connections
            moptilities
            metatilities-base
            cl-variates
          ];
        };
      };
    }) cl-containers "cl-containers/with-asdf-system-connections";

    cl-cookie = lispDerivation {
      lispSystem = "cl-cookie";
      src = inputs.cl-cookie;
      lispDependencies = [ alexandria cl-ppcre proc-parse local-time quri ];
      lispCheckDependencies = [ prove ];
    };

    cl-coveralls = lispDerivation {
      lispSystem = "cl-coveralls";
      lispCheckDependencies = [ prove ];
      lispDependencies = [
        alexandria
        cl-ppcre
        dexador
        flexi-streams
        ironclad
        jonathan
        lquery
        split-sequence
      ];
      src = inputs.cl-coveralls;
    };

    cl-custom-hash-table = lispDerivation {
      src = inputs.cl-custom-hash-table;
      lispSystem = "cl-custom-hash-table";
      lispCheckDependencies = [ hu_dwim_stefil ];
    };

    cl-difflib = lispify "cl-difflib" [ ];

    cl-dot = lispDerivation {
      lispSystem = "cl-dot";
      src = inputs.cl-dot;
      propagatedBuildInputs = [ pkgs.graphviz ];
      # https://github.com/michaelw/cl-dot/issues/42
      meta.broken = lisp.name == "clisp";
    };

    cl-fad = lispDerivation {
      lispSystem = "cl-fad";
      src = inputs.cl-fad;
      lispDependencies = [ alexandria bordeaux-threads ];
      lispCheckDependencies = [ cl-ppcre unit-test ];
      # The assertion (PATH:= (PATH:CATDIR #P"/a/" #P"/b/" #P"c/" #P"d/" #P"e" #P"f/") #P"/b/c/./d/f/") failed.
      meta.broken = lisp.name == "abcl";
    };

    cl-gopher = lispify "cl-gopher" [
      usocket
      flexi-streams
      drakma
      bordeaux-threads
      quri
    ];

    cl-html-diff = lispify "cl-html-diff" [ cl-difflib ];

    cl-interpol = lispDerivation {
      lispSystem = "cl-interpol";
      src = inputs.cl-interpol;
      lispDependencies = [ cl-unicode named-readtables ];
      lispCheckDependencies = [ flexi-streams ];
    };

    cl-isaac = lispDerivation {
      lispSystem = "cl-isaac";
      src = inputs.cl-isaac;
      lispCheckDependencies = [ parachute trivial-features ];
    };

    cl-js = lispDerivation {
      lispSystem = "cl-js";
      src = inputs.js;
      lispDependencies = [ parse-js cl-ppcre ];
    };

    cl-json = lispDerivation {
      lispSystem = "cl-json";
      lispCheckDependencies = [ fiveam ];
      src = inputs.cl-json;
    };

    cl-libuv = lispDerivation rec {
      lispDependencies = [ alexandria cffi cffi-grovel ];
      propagatedBuildInputs = [ pkgs.libuv ];
      lispSystem = "cl-libuv";
      src = inputs.cl-libuv;
    };

    inherit (lispMultiDerivation {
      src = inputs.cl-libxml2;
      systems = {
        cl-libxml2 = {
          lispSystems = [ "cl-libxml2" "xfactory" "xoverlay" ];
          lispDependencies = [
            iterate
            cffi
            puri
            flexi-streams
            alexandria
            garbage-pools
            metabang-bind
          ];
          lispCheckDependencies = [ lift ];
        };
        # Defined as a separate Nix derivation because it has complicated and
        # fragile build steps, and as far as I can tell QL doesn’t even export
        # this at all. Consider this derivation experimental for now. It’d be nice
        # if it actually worked, of course.
        cl-libxslt = {
          lispDependencies = [ cl-libxml2 ];
        };
      };
      makeFlags = [
        "CC=cc"
      ];
      buildInputs = systems:
        (l.optional (b.elem "cl-libxml2" systems) pkgs.libxml2) ++
        (l.optional (b.elem "cl-libxslt" systems) pkgs.libxslt);
      outputs = systems:
        [ "out" ] ++
        l.optional (b.elem "cl-libxslt" systems) "lib";
      # This :force t isn’t necessary, and it breaks tests
      postUnpack = ''
        (cd "$sourceRoot"; sed -i  -e "s/ :force t//" *.asd)
      '';
      preBuild = systems:
        s.optionalString (b.elem "cl-libxslt" systems) (
          let
            libname = "cllibxml2${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}";
          in ''
            LIBNAME=${libname} make -C foreign
            mkdir -p $lib
            cp -r foreign/${libname} $lib/
            # No need to special case this for Darwin (DYLD_..) because
            # we're using cffi which picks up LD_ on both Linux and
            # Darwin.
            addToSearchPath "LD_LIBRARY_PATH" "$lib"
          ''
        );
    }) cl-libxml2 cl-libxslt;

    cl-locale = lispDerivation {
      src = inputs.cl-locale;
      lispDependencies = [ anaphora arnesi cl-annot cl-syntax cl-syntax-annot ];
      lispCheckDependencies = [ flexi-streams prove ];
      lispSystem = "cl-locale";
    };

    cl-markdown = lispDerivation {
      lispSystem = "cl-markdown";
      src = inputs.cl-markdown;
      lispDependencies = [
        asdf-system-connections
        anaphora
        self."cl-containers/with-asdf-system-connections"
        cl-ppcre
        dynamic-classes
        metabang-bind
        metatilities-base
      ];
      lispCheckDependencies = [ lift trivial-shell ];
      # “There is no class named ABSTRACT-CONTAINER.”
      meta.broken = lisp.name == "abcl";
    };

    cl-mimeparse = lispDerivation {
      lispDependencies = [ cl-ppcre parse-number ];
      lispCheckDependencies = [ rt ];
      src = inputs.cl-mimeparse;
      lispSystem = "cl-mimeparse";
    };

    cl-mock = lispDerivation {
      src = inputs.cl-mock;
      lispSystem = "cl-mock";
      lispDependencies = [
        alexandria
        bordeaux-threads
        closer-mop
        trivia
      ];
      lispCheckDependencies = [
        fiveam
      ];
    };

    "cl+ssl" = lispDerivation {
      lispSystem = "cl+ssl";
      src = inputs."cl+ssl";
      lispDependencies = [
        alexandria
        bordeaux-threads
        cffi
        flexi-streams
        trivial-features
        trivial-garbage
        trivial-gray-streams
        usocket
      ];
      lispCheckDependencies = [
        bordeaux-threads
        cl-coveralls
        fiveam
        trivial-sockets
        usocket
      ];
      propagatedBuildInputs = [ pkgs.openssl ];
    };

    inherit (lispMultiDerivation rec {
      src = inputs.cl-ppcre;
      systems = {
        cl-ppcre = {
          lispCheckDependencies = [ flexi-streams ];
        };
        cl-ppcre-unicode = {
          lispDependencies = [ cl-ppcre cl-unicode ];
          lispCheckDependencies = [ flexi-streams ];
        };
      };
    }) cl-ppcre cl-ppcre-unicode;

    cl-prevalence = lispDerivation {
      lispSystem = "cl-prevalence";
      src = inputs.cl-prevalence;
      lispDependencies = [
        moptilities
        s-xml
        s-sysdeps
      ];
      lispCheckDependencies = [ fiveam find-port ];
    };

    cl-qrencode = lispDerivation {
      lispSystem = "cl-qrencode";
      src = inputs.cl-qrencode;
      lispDependencies = [ zpng ];
      lispCheckDependencies = [ lisp-unit ];
    };

    cl-quickcheck = lispify "cl-quickcheck" [ ];

    cl-reactive = lispDerivation {
      src = inputs.cl-reactive;
      lispSystem = "cl-reactive";
      lispDependencies = [
        bordeaux-threads
        closer-mop
        trivial-garbage
        anaphora
      ];
      lispCheckDependencies = [
        nst
      ];
      meta.broken = builtins.elem lisp.name [
        # Attempt to define a subclass of built-in-class FUNCTION.
        "abcl"
        # Class #<The BUILT-IN-CLASS FUNCTION> is not a valid superclass for #<The CLOS:FUNCALLABLE-STANDARD-CLASS CL-REACTIVE::SIGNAL-FUNCTION>
        "ecl"
      ];
    };

    cl-redis = lispDerivation {
      lispSystem = "cl-redis";
      lispDependencies = [
        babel
        cl-ppcre
        flexi-streams
        rutils
        usocket
      ];
      lispCheckDependencies = [ bordeaux-threads should-test ];
      src = inputs.cl-redis;
    };

    cl-slice = lispDerivation {
      lispSystem = "cl-slice";
      src = inputs.cl-slice;
      lispDependencies = [ alexandria anaphora let-plus ];
      lispCheckDependencies = [ clunit ];
    };

    cl-sqlite = lispDerivation {
      src = inputs.cl-sqlite;
      lispDependencies = [ iterate cffi ];
      lispCheckDependencies = [ fiveam bordeaux-threads ];
      propagatedBuildInputs = [ pkgs.sqlite ];
      lispSystem = "sqlite";
    };

    cl-speedy-queue = lispify "cl-speedy-queue" [ ];

    cl-strings = lispDerivation {
      lispSystem = "cl-strings";
      src = inputs.cl-strings;
      lispCheckDependencies = [ prove ];
    };

    inherit (lispMultiDerivation {
      src = inputs.cl-syntax;

      systems = {
        cl-syntax = {
          lispDependencies = [ named-readtables trivial-types ];
        };
        cl-syntax-annot = {
          lispDependencies = [ cl-syntax cl-annot ];
        };
        cl-syntax-interpol = {
          lispDependencies = [ cl-syntax cl-interpol ];
        };
      };
    }) cl-syntax cl-syntax-annot cl-syntax-interpol;

    cl-test-more = prove;

    cl-tld = lispify "cl-tld" [ ];

    cl-tls = lispify "cl-tls" [ ironclad alexandria fast-io cl-base64 ];

    cl-unicode = lispDerivation {
      lispSystem = "cl-unicode";
      src = inputs.cl-unicode;
      lispDependencies = [ cl-ppcre flexi-streams ];
    };

    # The official location for this source is
    # "https://www.common-lisp.net/project/cl-utilities/cl-utilities-latest.tar.gz"
    # but I’m not a huge fan of including a "latest.tar.gz" in a Nix
    # derivation. That being said: it hasn’t been changed since 2006, so maybe
    # that is a better resource.
    cl-utilities = lispDerivation {
      lispSystem = "cl-utilities";
      src = inputs.cl-utilities;
    };

    inherit (lispMultiDerivation {
      src = inputs.cl-variates;
      systems = {
        cl-variates = {
          lispCheckDependencies = [ lift ];
        };
        "cl-variates/with-metacopy" = {
          lispDependencies = [
            cl-variates
            asdf-system-connections
            metacopy
          ];
        };
      };
      meta = systems: a.optionalAttrs (b.elem "cl-variates/with-metacopy" systems) {
        broken = b.elem lisp.name [
          # The function get-structure is not yet implemented for Armed Bear Common Lisp 1.9.2 on AARCH64.
          "abcl"
          # *** - The function get-structure is not yet implemented for CLISP 2.49.92
          "clisp"
          # ;;; The function get-structure is not yet implemented for ECL 21.2.1 on arm64.
          "ecl"
        ];
      };
    }) cl-variates "cl-variates/with-metacopy";

    cl-who = lispDerivation {
      lispSystem = "cl-who";
      src = inputs.cl-who;
      lispCheckDependencies = [ flexi-streams ];
    };

    inherit (lispMultiDerivation {
      src = inputs.clack;

      systems = {
        # TODO: This is a complex package with lots of derivations and check
        # dependencies. Fill in as necessary. I’ve only filled in what I need
        # right now.
        clack = {
          lispDependencies = [
            alexandria
            bordeaux-threads
            lack
            swank
            usocket
          ];
        };
        clack-handler-hunchentoot = {
          lispDependencies = [
            alexandria
            bordeaux-threads
            clack-socket
            flexi-streams
            hunchentoot
            split-sequence
          ];
          lispCheckDependencies = [ clack-test ];
        };
        clack-socket = {};
        clack-test = {
          lispDependencies = [
            bordeaux-threads
            clack
            clack-handler-hunchentoot
            dexador
            flexi-streams
            http-body
            ironclad
            rove
            usocket
          ];
        };
      };
    }) clack clack-handler-hunchentoot clack-socket clack-test;

    closer-mop = lispify "closer-mop" [ ];

    clss = lispify "clss" [ array-utils plump ];

    clunit = lispify "clunit" [ ];

    clunit2 = lispify "clunit2" [ ];

    collectors = lispDerivation {
      lispSystem = "collectors";
      lispDependencies = [ alexandria closer-mop symbol-munger ];
      lispCheckDependencies = [ lisp-unit2 ];
      src = inputs.collectors;
    };

    colorize = lispify "colorize" [ alexandria html-encode split-sequence ];

    common-doc = lispDerivation {
      src = inputs.common-doc;
      # These all use practically the same dependencies. Light-weight enough that
      # it’s not worth the hassle to split them up, IMO.
      lispSystems = [
        "common-doc"
        "common-doc-graphviz"
        "common-doc-gnuplot"
        "common-doc-include"
        "common-doc-tex"
      ];
      lispDependencies = [
        alexandria
        anaphora
        closer-mop
        local-time
        quri
        split-sequence
        trivial-shell
        trivial-types
      ];
      lispCheckDependencies = [ fiveam ];
    };

    common-html = lispDerivation {
      src = inputs.common-html;
      lispSystems = ["common-html"];
      lispDependencies = [ common-doc plump anaphora alexandria ];
      lispCheckDependencies = [ fiveam ];
    };

    commondoc-markdown = lispDerivation {
      lispSystem = "commondoc-markdown";
      src = inputs.commondoc-markdown;
      lispDependencies = [
        self."3bmd"
        self."3bmd-ext-code-blocks"
        self."3bmd-ext-tables"
        common-doc
        common-html
        str
        ironclad
        f-underscore
      ];
      lispCheckDependencies = [ hamcrest rove ];
    };

    concrete-syntax-tree = lispDerivation {
      lispDependencies = [ acclimation ];
      src = inputs.concrete-syntax-tree;
      lispSystem = "concrete-syntax-tree";
      lispAsdPath = [ "Lambda-list" ];
      preBuild = ''
        echo '(:source-registry-cache ' > .cl-source-registry.cache
        find . -name '*.asd' -exec printf '"%s" ' {} \; >> .cl-source-registry.cache
        echo ')' >> .cl-source-registry.cache
      '';
    };

    contextl = lispDerivation {
      lispDependencies = [ closer-mop lw-compat ];
      src = inputs.contextl;
      lispSystems = [
        "contextl"

        # These two packages have clashing symbol exports, they can’t be loaded in
        # the same image. That’s fair, but lispDerivation doesn’t currently
        # support that, so I need to figure out whether I want to support that,
        # or, if not, how to allow packages like this to work around it. I guess
        # using overrides?
        # "dynamic-wind"
      ];
    };

    data-lens = lispDerivation {
      lispDependencies = [ cl-ppcre alexandria serapeum ];
      lispSystems = [ "data-lens" "data-lens/beta/transducers" ];
      lispCheckDependencies = [ fiveam string-case ];
      src = inputs.data-lens;
    };

    inherit (lispMultiDerivation {
      src = inputs.cl-dbi;

      systems = {
        dbi = {
          lispDependencies = [ bordeaux-threads split-sequence closer-mop ];
          lispCheckDependencies = [
            alexandria
            rove
            trivial-types
          ];
        };
      };
    }) dbi;

    deflate = lispify "deflate" [];

    dexador = lispDerivation {
      lispSystem = "dexador";
      src = inputs.dexador;
      lispDependencies = [
        alexandria
        babel
        bordeaux-threads
        chipz
        chunga
        cl-base64
        cl-cookie
        self."cl+ssl"
        cl-ppcre
        fast-http
        fast-io
        quri
        trivial-garbage
        trivial-gray-streams
        trivial-mimes
        usocket
      ] ++ lib.optionals pkgs.hostPlatform.isWindows [
        flexi-streams
      ];
      lispCheckDependencies = [
        babel
        cl-cookie
        clack-test
        lack
        rove
      ];
    };

    dissect = lispDerivation {
      lispSystem = "dissect";
      src = inputs.dissect;
      lispDependencies = l.optional (lisp.name == "clisp") cl-ppcre;
    };

    djula = lispDerivation {
      lispSystem = "djula";
      src = inputs.djula;
      lispDependencies = [
        access
        alexandria
        babel
        cl-locale
        cl-ppcre
        cl-slice
        closer-mop
        gettext
        iterate
        local-time
        parser-combinators
        split-sequence
        trivial-backtrace
      ];
      lispCheckDependencies = [ fiveam ];
    };

    dns-client = lispify "dns-client" [ punycode usocket documentation-utils ];

    # Technically these could be two separate derivations, one per system, but it
    # doesn’t seem like people use it that way, and there’s no dependencies
    # anyway, so there’s little benefit. Just treat this as a monolith package.
    docs-builder = lispDerivation {
      lispSystems = [ "docs-builder" "docs-config" ];
      src = inputs.docs-builder;
      lispDependencies = [ log4cl self."40ants-doc" ];
      # Requires a modern version of ASDF
      meta.broken = lisp.name == "ecl";
    };

    documentation-utils = lispDerivation {
      lispSystem = "documentation-utils";
      src = inputs.documentation-utils;
      lispDependencies = [ trivial-indent ];
    };

    drakma = lispDerivation {
      lispSystem = "drakma";
      src = inputs.drakma;
      lispDependencies = [
        chipz
        chunga
        cl-base64
        self."cl+ssl"
        cl-ppcre
        flexi-streams
        puri
        usocket
      ];
      lispCheckDependencies = [ easy-routes fiveam hunchentoot ];
    };

    dynamic-classes = lispDerivation {
      lispSystem = "dynamic-classes";
      src = inputs.dynamic-classes;
      lispDependencies = [ metatilities-base ];
      lispCheckDependencies = [ lift ];
    };

    eager-future2 = lispDerivation {
      lispSystem = "eager-future2";
      lispDependencies = [ bordeaux-threads trivial-garbage ];
      src = inputs.eager-future2;
      # Very specific deadlock: ECL & x86 & Macos, since ECL 21.2.1 -> 23.9.9
      # got merged: https://github.com/NixOS/nixpkgs/pull/276506
      # No idea what’s wrong here, or even who’s wrong: ECL? eager-future2?
      # Update: now also broken on aarch64-darwin, not sure why or since when.
      meta.broken = lisp.name == "ecl" && pkgs.stdenv.isDarwin;
    };

    inherit (lispMultiDerivation {
      src = inputs.easy-routes;
      systems = {
        easy-routes = {
          lispDependencies = [ hunchentoot routes ];
        };
        "easy-routes+errors" = {
          lispDependencies = [ easy-routes hunchentoot-errors ];
        };
        "easy-routes+djula" = {
          lispDependencies = [ easy-routes djula ];
        };
      };
    }) easy-routes
       "easy-routes+djula"
       "easy-routes+errors";

    inherit (lispMultiDerivation {
      src = inputs.eclector;
      systems = {
        eclector = {
          lispDependencies = [ alexandria closer-mop acclimation ];
          lispCheckDependencies = [ alexandria fiveam ];
        };
        eclector-concrete-syntax-tree = {
          lispDependencies = [ eclector concrete-syntax-tree alexandria ];
          lispCheckDependencies = [ fiveam ];
        };
      };
      # This directory is unneeded and it messes up some shebang filtering
      # autodetectiong stuff on linux builds.
      preBuild = "rm -rf tools-for-build";
    }) eclector eclector-concrete-syntax-tree;

    enchant = lispDerivation {
      lispDependencies = [ cffi ];
      lispSystem = "enchant";
      src = inputs.enchant;
    };

    eos = lispify "eos" [ ];

    esrap = lispDerivation {
      lispSystem = "esrap";
      src = inputs.esrap;
      lispDependencies = [ alexandria trivial-with-current-source-form ];
      lispCheckDependencies = [ fiveam ];
    };

    event-emitter = lispDerivation {
      lispSystem = "event-emitter";
      src = inputs.event-emitter;
      lispCheckDependencies = [ prove ];
    };

    f-underscore = lispify "f-underscore" [ ];

    fare-mop = lispify "fare-mop" [
      closer-mop
      fare-utils
    ];

    inherit (lispMultiDerivation {
      src = inputs.fare-quasiquote;
      systems = {
        fare-quasiquote = {
          lispDependencies = [ fare-utils ];
          lispCheckDependencies = [
            fare-quasiquote-extras
            hu_dwim_stefil
            optima
          ];
        };
        fare-quasiquote-extras = {
          lispDependencies = [
            fare-quasiquote-optima
            fare-quasiquote-readtable
          ];
        };
        fare-quasiquote-optima = {
          lispDependencies = [
            self."trivia.quasiquote"
          ];
        };
        fare-quasiquote-readtable = {
          lispDependencies = [ fare-quasiquote named-readtables ];
        };
      };
    }) fare-quasiquote
       fare-quasiquote-extras
       fare-quasiquote-optima
       fare-quasiquote-readtable;

    fare-utils = lispDerivation {
      lispSystem = "fare-utils";
      src = inputs.fare-utils;
      lispCheckDependencies = [ hu_dwim_stefil ];
      # "https://gitlab.common-lisp.net/frideau/fare-utils/-/issues/1".  Getting
      # the version here from the derivation is very ugly and I hate it but is
      # there a better way?
      meta.broken = lisp.name == "sbcl" && (lib.getVersion lisp.deriv) == "2.4.4";
    };

    fast-http = lispDerivation {
      src = inputs.fast-http;
      lispSystem = "fast-http";
      lispDependencies = [
        alexandria
        babel
        cl-utilities
        log4cl
        proc-parse
        smart-buffer
        xsubseq
      ];
      lispCheckDependencies = [
        babel
        cl-syntax-interpol
        prove
        xsubseq
      ];
    };

    fast-io = lispify "fast-io" [
      alexandria
      static-vectors
      trivial-gray-streams
    ];

    fast-websocket = lispDerivation {
      lispSystem = "fast-websocket";
      src = inputs.fast-websocket;
      lispCheckDependencies = [
        prove
        trivial-utf-8
      ];
      lispDependencies = [
        fast-io
        babel
        alexandria
      ];
    };

    # I’m defining this as a multideriv because it exposes lots of derivs. Even
    # though I only use one at the moment, it’s likely to change in the future.
    inherit (lispMultiDerivation {
      src = inputs.femlisp;
      systems = {
        infix = {};
      };
      dontConfigure = true;
      lispAsdPath = systems:
        l.optional (builtins.elem "infix" systems) "external/infix";
    }) infix;

    fiasco = lispify "fiasco" [ alexandria trivial-gray-streams ];

    find-port = lispDerivation {
      lispSystem = "find-port";
      lispCheckDependencies = [ fiveam ];
      lispDependencies = [ usocket ];
      src = inputs.find-port;
    };

    fiveam = lispify "fiveam" [ alexandria asdf-flv trivial-backtrace ];

    float-features = lispDerivation {
      lispSystem = "float-features";
      src = inputs.float-features;
      lispDependencies = [ documentation-utils trivial-features ];
      lispCheckDependencies = [ parachute ];
    };

    flexi-streams = lispify "flexi-streams" [ trivial-gray-streams ];

    form-fiddle = lispDerivation {
      lispSystem = "form-fiddle";
      src = inputs.form-fiddle;
      lispDependencies = [ documentation-utils ];
    };

    fset = lispify "fset" [ misc-extensions mt19937 named-readtables ];

    garbage-pools = lispDerivation {
      lispSystem = "garbage-pools";
      src = inputs.garbage-pools;
      lispCheckDependencies = [ lift ];
    };

    gettext = lispDerivation {
      lispSystem = "gettext";
      src = inputs.gettext;
      lispDependencies = [ split-sequence yacc flexi-streams ];
      lispCheckDependencies = [ stefil ];
      preCheck = ''
        export CL_SOURCE_REGISTRY="$PWD/gettext-tests:$CL_SOURCE_REGISTRY"
      '';
    };

    global-vars = lispify "global-vars" [ ];

    inherit (lispMultiDerivation {
      src = inputs.hamcrest;
      systems = {
        hamcrest = {
          lispCheckDependencies = [ prove rove ];
          lispDependencies = [
            self."40ants-asdf-system"
            alexandria
            iterate
            cl-ppcre
            split-sequence
          ];
        };
        # I’m not 100% on how this system is exported exactly, but it is,
        # somehow. Apparently ASDFv3 automatically recognizes this? Reblocks
        # seems to use it.
        "hamcrest/rove" = {
          lispDependencies = [
            hamcrest
            rove
          ];
        };
      };
    }) hamcrest
       "hamcrest/rove";

    history-tree = lispDerivation {
      lispDependencies = [
        alexandria
        cl-custom-hash-table
        local-time
        nclasses
        trivial-package-local-nicknames
      ];
      src = inputs.history-tree;
      lispCheckDependencies = [ lisp-unit2 ];
      lispSystem = "history-tree";
      # *** - EVAL: undefined function EXT::ADD-PACKAGE-LOCAL-NICKNAME
      meta.broken = lisp.name == "clisp";
    };

    http-body = lispDerivation {
      lispSystem = "http-body";
      src = inputs.http-body;
      lispDependencies = [
        babel
        cl-ppcre
        cl-utilities
        fast-http
        flexi-streams
        jonathan
        quri
        trivial-gray-streams
      ];
      lispCheckDependencies = [
        assoc-utils
        cl-ppcre
        flexi-streams
        prove
        trivial-utf-8
      ];
    };

    html-encode = lispify "html-encode" [ ];

    html-entities = lispDerivation {
      lispSystem = "html-entities";
      src = inputs.html-entities;
      lispDependencies = [ cl-ppcre ];
      lispCheckDependencies = [ fiveam ];
    };

    hu_dwim_asdf = lispify "hu.dwim.asdf" [ ];

    hu_dwim_stefil = lispify "hu.dwim.stefil" [ alexandria hu_dwim_asdf ];

    hunchentoot = lispDerivation {
      lispSystem = "hunchentoot";
      src = inputs.hunchentoot;
      lispDependencies = [
        alexandria
        chunga
        cl-base64
        cl-fad
        cl-ppcre
        flexi-streams
        md5
        rfc2388
        trivial-backtrace
        # TODO: Per-lisp selection (these are not necessary on lispworks)
        self."cl+ssl"
        usocket
        bordeaux-threads
      ];
      lispCheckDependencies = [
        cl-ppcre
        cl-who
        drakma
      ];
    };

    hunchentoot-errors = lispify "hunchentoot-errors" [
      cl-mimeparse
      hunchentoot
      parse-number
      string-case
    ];

    idna = lispify "idna" [ split-sequence ];

    ieee-floats = lispDerivation {
      lispSystem = "ieee-floats";
      src = inputs.ieee-floats;
      lispCheckDependencies = [ fiveam ];
    };

    in-nomine = lispDerivation {
      lispSystem = "in-nomine";
      lispDependencies = [
        alexandria
        trivial-arguments
      ];
      lispCheckDependencies = [
        alexandria
        closer-mop
        fiveam
        introspect-environment
        lisp-namespace
      ];
      src = inputs.in-nomine;
      # Uses :local-nickname in defpackage. Ah, the state of CLISP...
      # https://gitlab.com/gnu-clisp/clisp/-/merge_requests/3
      meta.broken = lisp.name == "clisp";
    };

    inferior-shell = lispDerivation {
      lispSystem = "inferior-shell";
      lispDependencies = [
        alexandria
        fare-utils
        fare-quasiquote-extras
        fare-mop
        trivia
        self."trivia.quasiquote"
      ];
      src = inputs.inferior-shell;
      lispCheckDependencies = [ fiveam ];
    };

    infix-math = lispify "infix-math" [ alexandria serapeum wu-decimal parse-number ];

    introspect-environment = lispDerivation {
      lispSystem = "introspect-environment";
      lispCheckDependencies = [ fiveam ];
      src = inputs.introspect-environment;
    };

    ironclad = lispDerivation {
      lispSystem = "ironclad";
      src = inputs.ironclad;
      lispDependencies = [ bordeaux-threads ];
      lispCheckDependencies = [ rt ];
      env = lib.optionalAttrs (lisp.name == "sbcl") {
        NIX_SBCL_DYNAMIC_SPACE_SIZE = "2gb";
      };
    };

    iterate = lispDerivation {
      lispSystem = "iterate";
      src = inputs.iterate;
      lispCheckDependencies = l.optional ((lisp.pname or "") != "sbcl") rt;
    };

    jonathan = lispDerivation {
      lispSystem = "jonathan";
      src = inputs.jonathan;
      lispDependencies = [
        babel
        cl-annot
        cl-ppcre
        cl-syntax
        cl-syntax-annot
        fast-io
        proc-parse
        trivial-types
      ];
      lispCheckDependencies = [
        prove
        legion
      ];
    };

    jpl-queues = lispDerivation {
      lispSystem = "jpl-queues";
      lispDependencies = [ bordeaux-threads jpl-util ];
      pname = "jpl-queues";
      src = inputs.jpl-queues;
    };

    jpl-util = lispDerivation {
      src = inputs.jpl-util;
      lispSystem = "jpl-util";
    };

    json-streams = lispDerivation {
      src = inputs.json-streams;
      lispSystem = "json-streams";
      lispCheckDependencies = [ cl-quickcheck flexi-streams ];
    };

    jzon = lispDerivation {
      src = inputs.jzon;
      lispSystem = "com.inuoe.jzon";
      lispDependencies = [
        closer-mop
        flexi-streams
        trivial-gray-streams
      ] ++ lib.optionals (lisp.name != "ecl") [
        float-features
      ];
      lispAsdPath = [ "src" "test" ];
      lispCheckDependencies = [ alexandria fiveam ];
    };

    kmrcl = lispDerivation {
      lispSystem = "kmrcl";
      version = "4a27407aad9deb607ffb8847630cde3d041ea25a";
      src = inputs.kmrcl;
      lispCheckDependencies = [ rt ];
      # > The symbol "MAKE-THREAD-LOCK" was not found in package EXT.
      meta.broken = lisp.name == "abcl";
    };

    # I can’t be bothered sorting out this dependency jungle
    lack = lispDerivation {
      src = inputs.lack;
      # Kitchen sink dependencies In an ideal world this would be unnecessary:
      # every individual lack system would be listed explicitly in Nix, with its
      # dependencies. I just can’t be bothered to do that right now.
      lispDependencies = [
        anypool
        circular-streams
        cl-base64
        cl-cookie
        cl-ppcre
        cl-redis
        dbi
        http-body
        local-time
        marshal
        quri
        trivial-mimes
        trivial-rfc-1123
        trivial-utf-8
      ] ++ (if pkgs.hostPlatform.isWindows
            then [ ironclad ]
            else [ cl-isaac ]);
      # Extracted from the main asd file. This will probably grow out of date within 3 days.
      lispSystems = [
        "lack/app/directory"
        "lack-app-directory"
        "lack/app/file"
        "lack-app-file"
        "lack/component"
        "lack-component"
        "lack/middleware/accesslog"
        "lack-middleware-accesslog"
        "lack/middleware/auth/basic"
        "lack-middleware-auth-basic"
        "lack/middleware/backtrace"
        "lack-middleware-backtrace"
        "lack/middleware/csrf"
        "lack-middleware-csrf"
        "lack/middleware/dbpool"
        "lack-middleware-dbpool"
        "lack/middleware/mount"
        "lack-middleware-mount"
        "lack/middleware/session"
        "lack-middleware-session"
        "lack/middleware/static"
        "lack-middleware-static"
        "lack/request"
        "lack-request"
        "lack/response"
        "lack-response"
        "lack/session/store/dbi"
        "lack-session-store-dbi"
        "lack/session/store/redis"
        "lack-session-store-redis"
        "lack/test"
        "lack-test"
        "lack/util/writer/stream"
        "lack-util-writer-stream"
        "lack/util"
        "lack-util"
      ];
    };

    lass = lispDerivation {
      lispSystems = [ "lass" "binary-lass" ];
      lispDependencies = [ trivial-indent trivial-mimes cl-base64 ];
      src = inputs.lass;
      # This is kind of ridiculous, but there’s a file here called asdf.lisp
      # which trips up clisp: ‘(require "asdf")’ loads that file, rather than
      # actual asdf. Who’s at fault here?
      meta.broken = lisp.name == "clisp";
    };

    legion = lispDerivation {
      lispSystem = "legion";
      src = inputs.legion;
      lispDependencies = [
        vom
        # Not listed in the .asd but these are required
        bordeaux-threads
        cl-speedy-queue
      ];
      lispCheckDependencies = [ local-time prove ];
    };

    let-plus = lispDerivation {
      lispSystem = "let-plus";
      lispCheckDependencies = [ lift ];
      lispDependencies = [ alexandria anaphora ];
      src = inputs.let-plus;
    };

    lift = lispDerivation {
      lispSystem = "lift";
      src = inputs.lift;
      # There is a bug in lift which causes some silly pathname, ‘mkdir -p’
      # style problem. Setting the broken flag here is the easiest way to
      # disable all lift tests on clisp for now.  The bug looks like this:
      #
      #  > *** - PROBE-FILE: No file name given:
      #  >       #P"/private/tmp/nix-build-system-metatilities-base.drv-1/source/test-results-2023-10-16-1/
      meta.broken = lisp.name == "clisp";
    };

    lisp-namespace = lispDerivation {
      lispSystem = "lisp-namespace";
      lispDependencies = [ alexandria ];
      lispCheckDependencies = [ fiveam ];
      src = inputs.lisp-namespace;
    };

    lisp-unit = lispify "lisp-unit" [ ];

    lisp-unit2 = lispify "lisp-unit2" [
      alexandria
      cl-interpol
      iterate
      symbol-munger
    ];

    lml2 = lispDerivation {
      lispDependencies = [ kmrcl ];
      lispCheckDependencies = [ rt ];
      lispSystem = "lml2";
      src = inputs.lml2;
    };

    local-time = lispDerivation {
      lispSystem = "local-time";
      src = inputs.local-time;
      lispCheckDependencies = [ hu_dwim_stefil ];
    };

    log4cl = lispDerivation {
      lispSystem = "log4cl";
      src = inputs.log4cl;
      lispDependencies = [ bordeaux-threads ];
      lispCheckDependencies = [ stefil ];
    };

    log4cl-extras = lispDerivation {
      lispSystem = "log4cl-extras";
      lispCheckDependencies = [ hamcrest ];
      lispDependencies = [
        self."40ants-doc"
        self."40ants-asdf-system"
        alexandria
        cl-strings
        dissect
        global-vars
        jonathan
        log4cl
        named-readtables
        pythonic-string-reader
        with-output-to-stream
      ];
      src = inputs.log4cl-extras;
    };

    # Technically this package also contains a benchmark system with different
    # dependencies but I’m not going to bother exposing that to this scope.
    lparallel = (
      let
        # Please don’t use this anywhere else
        bordeaux-threads-v1 = bordeaux-threads.overrideAttrs (_: { src = inputs.bordeaux-threads-v1; });
      in
        lispify "lparallel" [
          alexandria
          # If anyone else in your entire family includes
          # bordeaux-threads-master, you’re dead.
          bordeaux-threads-v1
        ]);

    lquery = lispDerivation {
      lispSystem = "lquery";
      src = inputs.lquery;
      lispCheckDependencies = [ fiveam ];
      lispDependencies = [ array-utils form-fiddle plump clss ];
    };

    lw-compat = lispify "lw-compat" [];

    marshal = lispDerivation {
      lispSystem = "marshal";
      lispCheckDependencies = [ xlunit ];
      src = inputs.marshal;
    };

    md5 = lispify "md5" [ flexi-streams ];

    metabang-bind = lispDerivation {
      lispSystem = "metabang-bind";
      src = inputs.metabang-bind;
      lispCheckDependencies = [ lift ];
    };

    inherit (lispMultiDerivation {
      src = inputs.metacopy;
      systems = {
        metacopy = {
          lispDependencies = [ moptilities ];
          lispCheckDependencies = [ lift ];
        };
        metacopy-with-contextl = {
          lispDependencies = [ moptilities contextl ];
          lispCheckDependencies = [ lift ];
        };
      };
    }) metacopy metacopy-with-contextl;

    inherit (lispMultiDerivation {
      src = inputs.metatilities;
      systems = {
        metatilities = {
          lispDependencies = [
            moptilities
            cl-containers
            metabang-bind
            metatilities-base
          ];
          lispCheckDependencies = [
            lift
          ];
        };
        "metatilities/with-lift" = {
          lispDependencies = [
            metatilities
            asdf-system-connections
            self."cl-containers/with-asdf-system-connections"
            lift
          ];
        };
      };
    }) metatilities
       "metatilities/with-lift";

    metatilities-base = lispDerivation {
      lispSystem = "metatilities-base";
      src = inputs.metatilities-base;
      lispCheckDependencies = [ lift ];
    };

    inherit (
      let
        lispCheckDependencies = [ self."mgl-pax/full" dref try ];
      in
        lispMultiDerivation {
          src = inputs.mgl-pax;
          systems = {
            dref = {
              lispDependencies = [
                mgl-pax-bootstrap
                named-readtables
                pythonic-string-reader
              ];
              lispCheckDependencies = lispCheckDependencies ++ [
                alexandria
                swank
              ];
            };
            mgl-pax = {
              lispDependencies = [
                dref
                named-readtables
                pythonic-string-reader
                mgl-pax-bootstrap
              ];
              inherit lispCheckDependencies;
            };
            "mgl-pax/full" = {
              # I don’t use the individual packages so I’ve just lumped them all
              # together.
              lispDependencies = [
                mgl-pax
                # mgl-pax/document
                self."3bmd"
                self."3bmd-ext-code-blocks"
                colorize
                md5
                trivial-utf-8
                # mgl-pax/navigate
                swank
                # mgl-pax/transcribe
                alexandria
              ];
              inherit lispCheckDependencies;
            };
            mgl-pax-bootstrap = {
            };
          };
          lispAsdPath = systems:
            l.optionals (builtins.elem "dref" systems) [ "dref" ];
        }) dref
           mgl-pax
           "mgl-pax/full"
           mgl-pax-bootstrap;

    misc-extensions = lispify "misc-extensions" [ ];

    moptilities = lispDerivation {
      lispSystem = "moptilities";
      lispDependencies = [ closer-mop ];
      lispCheckDependencies = [ lift ];
      src = inputs.moptilities;
    };

    mt19937 = lispify "mt19937" [ ];

    named-readtables = lispDerivation {
      lispSystem = "named-readtables";
      src = inputs.named-readtables;
      lispDependencies = [ mgl-pax-bootstrap ];
      lispCheckDependencies = [ try ];
    };

    nclasses = lispDerivation {
      lispDependencies = [ moptilities ];
      src = inputs.nclasses;
      lispCheckDependencies = [ lisp-unit2 ];
      lispSystem = "nclasses";
      # Requires a new version of ASDF that I’m not sure how to load before
      # building the code. See
      # "https://gitlab.common-lisp.net/asdf/asdf/-/issues/145".
      meta.broken = lisp.name == "ecl";
    };

    nfiles = lispDerivation {
      lispSystem = "nfiles";
      src =  inputs.nfiles;
      lispDependencies = [
        alexandria
        nclasses
        quri
        serapeum
        trivial-garbage
        trivial-package-local-nicknames
        trivial-types
      ];
      lispCheckDependencies = [
        lisp-unit2
      ];
    };

    nst = lispDerivation {
      lispSystem = "nst";
      src = inputs.nst;
      lispDependencies = [
        org-sampler
      ] ++ lib.optionals (builtins.elem lisp.name [ "sbcl" "clisp" ]) [
        closer-mop
      ];
      preCheck = ''
        export CL_SOURCE_REGISTRY="$PWD/test//:$CL_SOURCE_REGISTRY"
      '';
    };

    inherit (lispMultiDerivation {
      src = inputs.optima;
      systems = {
        optima = {
          lispCheckDependencies = [ eos optima-ppcre ];
          lispDependencies = [ alexandria closer-mop ];
        };
        optima-ppcre = {
          lispSystem = "optima.ppcre";
          lispDependencies = [ optima alexandria cl-ppcre ];
        };
      };
    }) optima optima-ppcre;

    org-sampler = lispify "org-sampler" [ iterate ];

    osicat = lispDerivation {
      lispSystem = "osicat";
      src = inputs.osicat;
      # I am ashamed to say I /still/ don’t know how dynamic linking really works
      # in Nix. My God it’s not a learning curve it’s a fractal.
      postInstall = ''
        mkdir -p $out/lib
        ( cd $out/lib ; for f in ../posix/libosicat* ; do ln -s $f ./ ; done )
      '';
      lispDependencies = [ alexandria cffi trivial-features cffi-grovel ];
      lispCheckDependencies = [ rt ];
    };

    parachute = lispify "parachute" [ documentation-utils form-fiddle trivial-custom-debugger ];

    parenscript = lispDerivation {
      lispSystem = "parenscript";
      version = "2.7.1";
      src = inputs.parenscript;
      lispDependencies = [ anaphora cl-ppcre named-readtables ];
      lispCheckDependencies = [ fiveam cl-js ];
    };

    parse-declarations = lispDerivation {
      lispSystem = "parse-declarations-1.0";
      src = inputs.parse-declarations;
    };

    parse-js = lispify "parse-js" [ ];

    parse-number = lispify "parse-number" [ ];

    inherit (lispMultiDerivation {
      src = inputs.parser-combinators;
      systems = {
        parser-combinators = {
          lispDependencies = [ iterate alexandria ];
          lispCheckDependencies = [ stefil infix ];
        };
        parser-combinators-cl-ppcre = {
          lispDependencies = [ parser-combinators cl-ppcre ];
        };
      };
    }) parser-combinators parser-combinators-cl-ppcre;

    path-parse = lispDerivation {
      lispSystem = "path-parse";
      lispCheckDependencies = [ fiveam ];
      lispDependencies = [ split-sequence ];
      src = inputs.path-parse;
    };

    plump = lispify "plump" [ array-utils documentation-utils ];

    proc-parse = lispDerivation {
      lispSystem = "proc-parse";
      lispDependencies = [ alexandria babel ];
      lispCheckDependencies = [ prove ];
      src = inputs.proc-parse;
    };

    prove = lispDerivation {
      # Old name for this project
      lispSystems = [ "prove" "cl-test-more" ];
      src = inputs.prove;
      lispDependencies = [
        alexandria
        cl-ansi-text
        cl-colors
        cl-ppcre
      ];
      lispCheckDependencies = [ alexandria split-sequence ];
    };

    ptester = lispDerivation rec {
      lispSystem = "ptester";
      src = inputs.ptester;
    };

    punycode = lispDerivation {
      lispSystem = "punycode";
      src = inputs.punycode;
      lispCheckDependencies = [ parachute ];
    };

    puri = lispDerivation {
      lispSystem = "puri";
      src = inputs.puri;
      lispCheckDependencies = [ ptester ];
    };

    pythonic-string-reader = lispify "pythonic-string-reader" [ named-readtables ];

    quickhull = lispify "quickhull" [ self."3d-math" documentation-utils ];

    quri = lispDerivation {
      lispSystem = "quri";
      lispDependencies = [ alexandria babel cl-utilities split-sequence ];
      lispCheckDependencies = [ prove ];
      src = inputs.quri;
      # On ABCL this hard-codes a build path which isn’t available once it’s
      # moved to the store.  The dependent pacage will throw:
      #
      # The file #P"/private/tmp/nix-build-system-quri.drv-0/source/data/effective_tld_names.dat" does not exist.
      meta.broken = lisp.name == "abcl";
    };

    reblocks = lispDerivation {
      lispSystem = "reblocks";
      src = inputs.reblocks;
      lispCheckDependencies = [
        cl-mock
        self."hamcrest/rove"
        rove
      ];
      lispDependencies = [
        self."40ants-doc"
        circular-streams
        cl-cookie
        cl-fad
        clack
        clack-handler-hunchentoot
        dexador
        f-underscore
        find-port
        http-body
        lack
        log4cl
        log4cl-extras
        metacopy
        metatilities
        parenscript
        routes
        salza2
        serapeum
        self."spinneret/cl-markdown"
        trivial-open-browser
        trivial-timeout
        uuid
        yason
      ];
    };

    reblocks-parenscript = lispDerivation {
      lispSystem = "reblocks-parenscript";
      lispDependencies = [
        alexandria
        bordeaux-threads
        parenscript
        reblocks
      ];
      lispCheckDependencies = [
        rove
      ];
      src = inputs.reblocks-parenscript;
    };

    reblocks-ui = lispDerivation {
      lispSystem = "reblocks-ui";
      src = inputs.reblocks-ui;
      lispDependencies = [
        self."40ants-doc"
        log4cl
        reblocks
        reblocks-parenscript
      ];
    };

    reblocks-websocket = lispDerivation {
      lispSystem = "reblocks-websocket";
      src = inputs.reblocks-websocket;
      lispDependencies = [
        alexandria
        bordeaux-threads
        jonathan
        log4cl-extras
        reblocks
        reblocks-parenscript
        serapeum
        websocket-driver
      ];
      lispCheckDependencies = [ rove ];
    };

    rfc2388 = lispify "rfc2388" [ ];

    routes = lispDerivation {
      lispSystem = "routes";
      src = inputs.routes;
      lispDependencies = [ puri iterate split-sequence ];
      lispCheckDependencies = [ lift ];
    };

    # For some reason none of these dependencies are specified in the .asd
    rove = lispify "rove" [
      bordeaux-threads
      cl-ppcre
      dissect
      trivial-gray-streams
    ];

    rt = lispDerivation rec {
      lispSystem = "rt";
      src = inputs.rt;
    };

    # rutils and rutilsx have the same dependencies etc, it’s not worth the hassle
    # creating separate derivations for them.
    rutils = lispDerivation {
      lispSystems = [ "rutils" "rutilsx" ];
      src = inputs.rutils;
      lispDependencies = [ named-readtables closer-mop ];
      lispCheckDependencies = [ should-test ];
    };

    s-sysdeps = lispify "s-sysdeps" [ usocket usocket-server bordeaux-threads ];

    s-xml = lispify "s-xml" [ ];

    salza2 = lispDerivation {
      lispSystem = "salza2";
      src = inputs.salza2;
      lispDependencies = [ trivial-gray-streams ];
      lispCheckDependencies = [
        chipz
        flexi-streams
        parachute
      ];
    };

    serapeum = lispDerivation {
      src = inputs.serapeum;
      lispSystem = "serapeum";
      lispDependencies = [
        alexandria
        bordeaux-threads
        global-vars
        introspect-environment
        parse-declarations
        parse-number
        split-sequence
        string-case
        trivia
        trivial-cltl2
        trivial-file-size
        trivial-garbage
        trivial-macroexpand-all
      ];
      lispCheckDependencies = [
        fiveam
        local-time
        trivial-macroexpand-all
        atomics
      ];
      # Something rather benign seems going on with packages depending on
      # Serapeum in ABCL:
      #
      # ; Caught DEPENDENCY-NOT-DONE:
      # ;   Computing just-done stamp  for action (ASDF/LISP-ACTION:PREPARE-OP "serapeum"), but dependency (ASDF/LISP-ACTION:LOAD-OP "extensible-sequences") wasn't done yet!


      # ; Compilation unit finished
      # ;   Caught 1 WARNING condition

      # Unable to open #P"/nix/store/dg1am35c5dlfa1n7493kjhks86ibh3cz-system-serapeum/package-tmpCEA7HV6J.abcl".
      #
      # Looking at the serapeum source it seems to be because ABCL provides a
      # native "extensible-sequences" feature, which serapeum includes somehow,
      # but downstream ASDF gets confused about whether or not this was loaded
      # and tries to rebuild serapeum because of it.  I don’t have the
      # inclination to fix it 🤷
      meta.broken = lisp.name == "abcl";
    };

    sha1 = lispify "sha1" [];

    should-test = lispDerivation {
      lispSystem = "should-test";
      lispDependencies = [ rutils local-time osicat cl-ppcre];
      # TODO: This should be propagated from osicat somehow, not in every client
      # using osicat.
      preBuild = ''
        export LD_LIBRARY_PATH=''${LD_LIBRARY_PATH+$LD_LIBRARY_PATH:}${osicat}/lib
      '';
      buildInputs = [ osicat ];
      src = inputs.should-test;
    };

    simple-date-time = lispify "simple-date-time" [ cl-ppcre ];

    slynk = lispDerivation {
      lispSystem = "slynk";
      src = inputs.sly;
      lispAsdPath = [ "slynk" ];
    };

    smart-buffer = lispDerivation {
      lispSystem = "smart-buffer";
      src = inputs.smart-buffer;
      lispCheckDependencies = [ babel prove ];
      lispDependencies = [ flexi-streams xsubseq ];
    };

    inherit (lispMultiDerivation {
      src = inputs.spinneret;
      lispCheckDependencies = [ fiveam parenscript ];

      systems = {
        spinneret = {
          lispDependencies = [
            alexandria
            cl-ppcre
            global-vars
            in-nomine
            parenscript
            serapeum
            trivia
            trivial-gray-streams
          ];
        };
        "spinneret/cl-markdown" = {
          lispSystem = "spinneret/cl-markdown";
          lispDependencies = [ spinneret cl-markdown ];
        };
      };
    }) spinneret "spinneret/cl-markdown";

    split-sequence = lispDerivation {
      lispSystem = "split-sequence";
      lispCheckDependencies = [ fiveam ];
      src = inputs.split-sequence;
    };

    # N.B.: Soon won’t depend on cffi-grovel
    static-vectors = lispDerivation {
      lispSystem = "static-vectors";
      src = inputs.static-vectors;
      lispDependencies = [ alexandria cffi cffi-grovel ];
      lispCheckDependencies = [ fiveam ];
      meta.broken = lisp.name == "clisp";
    };

    stefil = lispify "stefil" [
      alexandria
      iterate
      metabang-bind
      swank
    ];

    stem = lispify "stem" [];

    str = lispDerivation {
      lispSystem = "str";
      src = inputs.str;
      lispDependencies = [
        cl-change-case
        cl-ppcre
        cl-ppcre-unicode
      ];
      lispCheckDependencies = [ prove ];
    };

    string-case = lispify "string-case" [ ];

    swank = lispDerivation {
      lispSystem = "swank";
      # The Swank Lisp system is bundled with SLIME
      src = inputs.slime;
      patches = ./patches/slime-fix-swank-loader-fasl-cache-pwd.diff;
    };

    symbol-munger = lispDerivation {
      src = inputs.symbol-munger;
      lispSystem = "symbol-munger";
      lispDependencies = [ alexandria iterate ];
      lispCheckDependencies = [ lisp-unit2 ];
    };

    tmpdir = lispify "tmpdir" [ cl-fad ];

    inherit (lispMultiDerivation {
      src = inputs.trivia;

      systems = {
        trivia = {
          lispDependencies = [
            alexandria
            iterate
            self."trivia.trivial"
            type-i
          ];
          lispCheckDependencies = [
            fiveam
            optima
            self."trivia.cffi"
            self."trivia.fset"
            self."trivia.ppcre"
            self."trivia.quasiquote"
          ];
        };

        "trivia.cffi" = {
          lispDependencies = [
            cffi
            self."trivia.trivial"
          ];
        };

        "trivia.fset" = {
          lispDependencies = [
            fset
            self."trivia.trivial"
          ];
        };

        "trivia.ppcre" = {
          lispDependencies = [
            cl-ppcre
            self."trivia.trivial"
          ];
        };

        "trivia.quasiquote" = {
          lispDependencies = [
            fare-quasiquote-readtable
            trivia
          ];
        };

        "trivia.trivial" = {
          lispDependencies = [
            alexandria
            closer-mop
            lisp-namespace
            trivial-cltl2
          ];
        };
      };
    }) trivia
       "trivia.cffi"
       "trivia.fset"
       "trivia.ppcre"
       "trivia.quasiquote"
       "trivia.trivial";

    trivial-arguments = lispify "trivial-arguments" [ ];

    trivial-backtrace = lispify "trivial-backtrace" [ lift ];

    trivial-benchmark = lispify "trivial-benchmark" [ documentation-utils ];

    trivial-cltl2 = lispDerivation {
      lispSystem = "trivial-cltl2";
      src = inputs.trivial-cltl2;
    };

    trivial-custom-debugger = lispDerivation {
      src = inputs.trivial-custom-debugger;
      lispSystem = "trivial-custom-debugger";
      lispCheckDependencies = [ parachute ];
    };

    trivial-extract = lispDerivation {
      src = inputs.trivial-extract;
      lispSystem = "trivial-extract";
      lispDependencies = [
        archive
        self.zip
        deflate
        which
        cl-fad
        alexandria
      ];
      lispCheckDependencies = [
        fiveam
      ];
    };

    trivial-features = lispDerivation {
      src = inputs.trivial-features;
      lispSystem = "trivial-features";
      lispCheckDependencies = [ rt cffi cffi-grovel alexandria ];
    };

    trivial-file-size = lispDerivation {
      src = inputs.trivial-file-size;
      lispCheckDependencies = [ fiveam ];
      lispSystem = "trivial-file-size";
    };

    trivial-garbage = lispDerivation {
      src = inputs.trivial-garbage;
      lispSystem = "trivial-garbage";
      lispCheckDependencies = [ rt ];
    };

    trivial-gray-streams = lispify "trivial-gray-streams" [ ];

    trivial-indent = lispify "trivial-indent" [ ];

    trivial-macroexpand-all = lispify "trivial-macroexpand-all" [ ];

    trivial-mimes = lispify "trivial-mimes" [ ];

    trivial-open-browser = lispify "trivial-open-browser" [ ];

    trivial-package-local-nicknames = lispify "trivial-package-local-nicknames" [ ];

    trivial-rfc-1123 = lispify "trivial-rfc-1123" [ cl-ppcre ];

    trivial-shell = lispDerivation {
      lispSystem = "trivial-shell";
      src = inputs.trivial-shell;
      lispCheckDependencies = [ lift ];
    };

    trivial-sockets = lispDerivation {
      lispSystem = "trivial-sockets";
      src = inputs.trivial-sockets;
      # Supported lisps: sbcl cmu clisp acl openmcl lispworks abcl mcl
      meta.broken = lisp.name == "ecl";
    };

    trivial-timeout = lispDerivation {
      lispSystem = "trivial-timeout";
      lispCheckDependencies = [ lift ];
      src = inputs.trivial-timeout;
    };

    trivial-types = lispify "trivial-types" [ ];

    trivial-utf-8 = lispify "trivial-utf-8" [ mgl-pax-bootstrap ];

    trivial-with-current-source-form = lispify "trivial-with-current-source-form" [ alexandria ];

    try = lispify "try" [
      alexandria
      cl-ppcre
      closer-mop
      ieee-floats
      mgl-pax
      trivial-gray-streams
    ];

    type-i = lispDerivation {
      lispSystem = "type-i";
      src = inputs.type-i;
      lispDependencies = [
        alexandria
        introspect-environment
        self."trivia.trivial"
        lisp-namespace
      ];
      lispCheckDependencies = [ fiveam ];
    };

    type-templates = lispDerivation {
      lispDependencies = [ alexandria form-fiddle documentation-utils ];
      lispSystem = "type-templates";
      src = inputs.type-templates;
    };

    typo = lispDerivation {
      lispSystem = "typo";
      lispDependencies = [
        alexandria
        closer-mop
        introspect-environment
        trivia
        trivial-arguments
        trivial-garbage
      ];
      src = inputs.typo;
      lispAsdPath = [ "code" ];
      preCheck = ''
        export CL_SOURCE_REGISTRY="$PWD/code/test-suite:$CL_SOURCE_REGISTRY"
      '';
      meta.broken = b.elem lisp.name [ "ecl" "clisp" ];
    };

    unit-test = lispify "unit-test" [ ];

    unix-options = lispify "unix-options" [ ];

    inherit (lispMultiDerivation {
      src = inputs.usocket;
      systems = {
        usocket = {
          lispDependencies = [ split-sequence ];
          lispCheckDependencies = [ bordeaux-threads rt ];
        };
        usocket-server = {
          lispDependencies = [ usocket bordeaux-threads ];
        };
      };
    }) usocket usocket-server;

    uuid = lispify "uuid" [ ironclad trivial-utf-8 ];

    vom = lispify "vom" [ ];

    websocket-driver = lispify "websocket-driver" [
      babel
      bordeaux-threads
      self."cl+ssl"
      cl-base64
      clack-socket
      event-emitter
      fast-http
      fast-io
      fast-websocket
      quri
      sha1
      split-sequence
      usocket
    ];

    which = lispDerivation {
      lispSystem = "which";
      src = inputs.which;
      lispCheckDependencies = [ fiveam ];
      lispDependencies = [ path-parse cl-fad ];
    };

    wild-package-inferred-system = lispDerivation {
      lispCheckDependencies = [ fiveam ];
      lispSystem = "wild-package-inferred-system";
      src = inputs.wild-package-inferred-system;
      # Clisp packages ASDF v3.2, WPI requires ≥3.3, this is the easiest way to
      # remedy that. Of course you can byo-ASDF, at which point you can just
      # .overrideAttrs this flag back to false. Same for ECL.
      meta.broken = b.elem lisp.name ["clisp" "ecl"];
    };

    with-output-to-stream = lispDerivation {
      lispSystem = "with-output-to-stream";
      version = "1.0";
      src = inputs.with-output-to-stream;
    };

    wu-decimal = lispify "wu-decimal" [];

    xml-emitter = lispDerivation {
      src = inputs.xml-emitter;
      lispSystem = "xml-emitter";
      lispDependencies = [ cl-utilities ];
      lispCheckDependencies = [ self."1am" ];
    };

    xlunit = lispDerivation rec {
      lispSystem = "xlunit";
      version = "3805d34b1d8dc77f7e0ee527a2490194292dd0fc";
      src = inputs.xlunit;
    };

    xsubseq = lispDerivation {
      src = inputs.xsubseq;
      lispSystem = "xsubseq";
      lispCheckDependencies = [ prove ];
    };

    # QL calls this "cl-yacc", but the system name is "yacc", so I’m sticking to
    # "yacc". Regardless of the repo name--that’s not authoritative. The system
    # name is.
    yacc = lispDerivation {
      lispSystem = "yacc";
      src = inputs.yacc;
    };

    yason = lispify "yason" [ alexandria trivial-gray-streams ];

    zip = lispify "zip" [ trivial-gray-streams babel cl-fad salza2 ];

    zpng = lispify "zpng" [ salza2 ];
  }));
}
