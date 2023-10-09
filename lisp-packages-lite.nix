# Copyright © 2022, 2023  Hraban Luyat
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
  lispPackagesLiteFor = lisp: lib.recurseIntoAttrs (lib.makeScope pkgs.newScope (self:
    with self;
    with callPackage ./utils.nix {};
    with callPackage ./lisp-derivation.nix { inherit lisp; };

    let
      lispify = name: lispDependencies:
        lispDerivation {
          inherit lispDependencies;
          lispSystem = name; # convention
          src = inputs.${name};
        };
    in {
    inherit lispDerivation lispMultiDerivation lispWithSystems;

    "1am" = callPackage ({}: lispify "1am" []) {};

    inherit (callPackage ({}: lispMultiDerivation {
      src = inputs."3bmd";
      systems = {
        "3bmd" = {
          lispDependencies = [ alexandria esrap split-sequence ];
          lispCheckDependencies = [ self."3bmd-ext-code-blocks" fiasco ];
        };
        "3bmd-ext-code-blocks" = {
          lispDependencies = [ self."3bmd" alexandria colorize split-sequence ];
        };
      };
    }) {}) "3bmd" "3bmd-ext-code-blocks";

    "3d-math" = callPackage ({}: lispDerivation {
      lispDependencies = [ documentation-utils type-templates ];
      lispCheckDependencies = [ parachute ];
      src = inputs."3d-math";
      lispSystem = "3d-math";
    }) {};

    "3d-vectors" = callPackage ({}: lispDerivation {
      lispDependencies = [ documentation-utils ];
      lispCheckDependencies = [ parachute ];
      src = inputs."3d-vectors";
      lispSystem = "3d-vectors";
    }) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) "40ants-doc" "40ants-doc-full";

    "40ants-asdf-system" = callPackage ({}: lispDerivation {
      lispSystem = "40ants-asdf-system";
      src = inputs."40ants-asdf-system";
      # Depends on a modern ASDF. SBCL’s built-in ASDF crashes this. Explicitly
      # listing self. here to avoid grabbing nixpkgs.asdf.
      lispDependencies = [ self.asdf ];
      lispCheckDependencies = [ rove ];
    }) {};

    access = callPackage ({}: lispDerivation {
      lispSystem = "access";
      src = inputs.access;
      lispDependencies = [ alexandria closer-mop iterate cl-ppcre ];
      lispCheckDependencies = [ lisp-unit2 ];
    }) {};

    acclimation = callPackage ({}: lispify "acclimation" []) {};

    alexandria = callPackage ({}: lispDerivation {
      lispSystem = "alexandria";
      src = inputs.alexandria;
      # See https://gitlab.common-lisp.net/alexandria/alexandria/-/issues/38
      patches = ./patches/alexandria-tests.patch;
      # Contrary to what its .asd file suggests, Alexandria now requires rt even
      # on SBCL. This is recent (introduced after v1.4).
      lispCheckDependencies = [ rt ];
    }) {};

    alien-ring = callPackage ({}: lispify "alien-ring" [ cffi trivial-gray-streams ]) {};

    anaphora = callPackage ({}: lispDerivation {
      lispSystem = "anaphora";
      lispCheckDependencies = [ rt ];
      src = inputs.anaphora;
    }) {};

    archive = callPackage ({}: lispify "archive" [ trivial-gray-streams cl-fad ]) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) arnesi arnesi-cl-ppcre-extras arnesi-slime-extras;

    array-utils = callPackage ({}: lispDerivation {
      lispSystem = "array-utils";
      lispCheckDependencies = [ parachute ];
      src = inputs.array-utils;
    }) {};

    arrow-macros = callPackage ({}: lispDerivation {
      lispSystem = "arrow-macros";

      src = inputs.arrow-macros;

      lispDependencies = [ alexandria ];
      lispCheckDependencies = [ fiveam ];
    }) {};

    asdf = callPackage ({}: lispify "asdf" [ ]) {};

    asdf-flv = callPackage ({}: lispDerivation {
      lispSystem = "net.didierverna.asdf-flv";
      src = inputs.asdf-flv;
    }) {};

    asdf-system-connections = callPackage ({}: lispify "asdf-system-connections" []) {};

    assoc-utils = callPackage ({}: lispDerivation {
      lispSystem = "assoc-utils";
      src = inputs.assoc-utils;
      lispCheckDependencies = [ prove ];
    }) {};

    atomics = callPackage ({}: lispDerivation {
      lispSystem = "atomics";
      src = inputs.atomics;
      lispDependencies = [ documentation-utils ];
      lispCheckDependencies = [ parachute ];
    }) {};

    inherit (callPackage ({}:
      lispMultiDerivation {
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
      }) {}) babel babel-streams;

    blackbird = callPackage ({}: lispDerivation {
      lispSystem = "blackbird";
      src = inputs.blackbird;
      lispDependencies = [ vom ];
      lispCheckDependencies = [ cl-async fiveam ];
    }) {};

    bordeaux-threads = callPackage ({}: lispDerivation rec {
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
    }) {};

    inherit (callPackage ({}:
      lispMultiDerivation rec {
        name = "cffi";
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
        nativeBuildInputs = [ pkgs.pkg-config pkgs.gcc ];
        buildInputs = systems: l.optionals (b.elem "cffi" systems) [ pkgs.libffi ];
        # This is broken on Darwin because libcffi rewrites the import path in a
        # way that’s incompatible with pkgconfig. It should be "if darwin AND (not
        # pkg-config)".

        setupHooks = systems: l.optionals (b.elem "cffi" systems) [(
          if pkgs.hostPlatform.isDarwin
          # LD_.. only works with CFFI on Mac, but not with
          # sb-alien:load-shared-object. DYLD_.. works with both.
          then pkgs.writeText "cffi-setup-hook-darwin.sh" (builtins.replaceStrings
            [ "LD_LIBRARY_PATH" ]
            [ "DYLD_LIBRARY_PATH" ]
            (builtins.readFile ./cffi-setup-hook.sh ))
          else ./cffi-setup-hook.sh
        )];
      }
    ) {}) cffi cffi-grovel;

    calispel = callPackage ({}: lispDerivation {
      lispSystem = "calispel";
      src = inputs.calispel;
      lispDependencies = [ jpl-queues bordeaux-threads ];
      lispCheckDependencies = [ eager-future2 ];
    }) {};

    chipz = callPackage ({}: lispify "chipz" [ ]) {};

    chunga = callPackage ({}: lispify "chunga" [ trivial-gray-streams ]) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) coalton coalton-benchmarks coalton-doc coalton-examples;

    circular-streams = callPackage ({}: lispDerivation {
      lispSystem = "circular-streams";
      src = inputs.circular-streams;
      lispDependencies = [ fast-io trivial-gray-streams ];
      lispCheckDependencies = [ cl-test-more flexi-streams ];
    }) {};

    cl-annot = callPackage ({}: lispDerivation {
      lispSystem = "cl-annot";
      src = inputs.cl-annot;
      lispDependencies = [ alexandria ];
      lispCheckDependencies = [ cl-test-more ];
    }) {};

    cl-ansi-text = callPackage ({}: lispDerivation {
      lispSystem = "cl-ansi-text";
      src = inputs.cl-ansi-text;
      lispDependencies = [ alexandria cl-colors2 ];
      lispCheckDependencies = [ fiveam ];
    }) {};

    inherit (callPackage ({}: lispMultiDerivation rec {
      name = "cl-async";

      src = inputs.cl-async;

      systems = {
        cl-async = {
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
    }) {}) cl-async cl-async-repl cl-async-ssl;

    cl-base64 = callPackage ({}: lispDerivation rec {
      lispSystem = "cl-base64";
      version = "577683b18fd880b82274d99fc96a18a710e3987a";
      src = inputs.cl-base64;
      lispCheckDependencies = [ ptester kmrcl ];
    }) {};

    cl-change-case = callPackage ({}: lispDerivation {
      lispSystem = "cl-change-case";
      src = inputs.cl-change-case;
      lispDependencies = [
        cl-ppcre
        cl-ppcre-unicode
      ];
      lispCheckDependencies = [ fiveam ];
    }) {};

    cl-colors = callPackage ({}: lispDerivation {
      lispSystem = "cl-colors";
      lispCheckDependencies = [ lift ];
      lispDependencies = [ alexandria let-plus ];
      src = inputs.cl-colors;
    }) {};

    cl-colors2 = callPackage ({}: lispDerivation {
      lispSystem = "cl-colors2";
      src = inputs.cl-colors2;
      lispDependencies = [ alexandria cl-ppcre ];
      lispCheckDependencies = [ clunit2 ];
    }) {};

    inherit (callPackage ({}: lispMultiDerivation {
      src = inputs.cl-containers;
      systems = {
        cl-containers = {
          lispDependencies = [ metatilities-base ];
          lispCheckDependencies = [ lift ];
        };
        # This is an infections dependency which, if available on the search
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
    }) {}) cl-containers "cl-containers/with-asdf-system-connections";

    cl-cookie = callPackage ({}: lispDerivation {
      lispSystem = "cl-cookie";
      src = inputs.cl-cookie;
      lispDependencies = [ alexandria cl-ppcre proc-parse local-time quri ];
      lispCheckDependencies = [ prove ];
    }) {};

    cl-coveralls = callPackage ({}: lispDerivation {
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
    }) {};

    cl-custom-hash-table = callPackage ({}: lispDerivation {
      src = inputs.cl-custom-hash-table;
      lispSystem = "cl-custom-hash-table";
      lispCheckDependencies = [ hu_dwim_stefil ];
    }) {};

    cl-difflib = callPackage ({}: lispify "cl-difflib" [ ]) {};

    cl-dot = callPackage ({}: lispify "cl-dot" []) {};

    cl-fad = callPackage ({}: lispDerivation {
      lispSystem = "cl-fad";
      src = inputs.cl-fad;
      lispDependencies = [ alexandria bordeaux-threads ];
      lispCheckDependencies = [ cl-ppcre unit-test ];
    }) {};

    cl-gopher = callPackage ({}: lispify "cl-gopher" [
      usocket
      flexi-streams
      drakma
      bordeaux-threads
      quri
    ]) {};

    cl-html-diff = callPackage ({}: lispify "cl-html-diff" [ cl-difflib ]) {};

    cl-interpol = callPackage ({}: lispDerivation {
      lispSystem = "cl-interpol";
      src = inputs.cl-interpol;
      lispDependencies = [ cl-unicode named-readtables ];
      lispCheckDependencies = [ flexi-streams ];
    }) {};

    cl-isaac = callPackage ({}: lispDerivation {
      lispSystem = "cl-isaac";
      src = inputs.cl-isaac;
      lispCheckDependencies = [ parachute trivial-features ];
    }) {};

    cl-js = callPackage ({}: lispDerivation {
      lispSystem = "cl-js";
      src = inputs.js;
      lispDependencies = [ parse-js cl-ppcre ];
    }) {};

    cl-json = callPackage ({}: lispDerivation {
      lispSystem = "cl-json";
      lispCheckDependencies = [ fiveam ];
      src = inputs.cl-json;
    }) {};

    cl-libuv = callPackage ({}: lispDerivation rec {
      lispDependencies = [ alexandria cffi cffi-grovel ];
      propagatedBuildInputs = [ pkgs.libuv ];
      lispSystem = "cl-libuv";
      src = inputs.cl-libuv;
    }) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
            libname =
              # There has to be a better way. How do you make CC automatically
              # decide on the "correct" extension?
              if pkgs.hostPlatform.isDarwin then "cllibxml2.dylib"
              else "cllibxml2.so"; # I’m not even going to try windows
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
    }) {}) cl-libxml2 cl-libxslt;

    cl-locale = callPackage ({}: lispDerivation {
      src = inputs.cl-locale;
      lispDependencies = [ anaphora arnesi cl-annot cl-syntax cl-syntax-annot ];
      lispCheckDependencies = [ flexi-streams prove ];
      lispSystem = "cl-locale";
    }) {};

    cl-markdown = callPackage ({}: lispDerivation {
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
    }) {};

    cl-mimeparse = callPackage ({}: lispDerivation {
      lispDependencies = [ cl-ppcre parse-number ];
      lispCheckDependencies = [ rt ];
      src = inputs.cl-mimeparse;
      lispSystem = "cl-mimeparse";
    }) {};

    "cl+ssl" = callPackage ({}: lispDerivation {
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
    }) {};

    inherit (callPackage ({}: lispMultiDerivation rec {
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
    }) {}) cl-ppcre cl-ppcre-unicode;

    cl-prevalence = callPackage ({}: lispDerivation {
      lispSystem = "cl-prevalence";
      src = inputs.cl-prevalence;
      lispDependencies = [
        moptilities
        s-xml
        s-sysdeps
      ];
      lispCheckDependencies = [ fiveam find-port ];
    }) {};

    cl-qrencode = callPackage ({}: lispDerivation {
      lispSystem = "cl-qrencode";
      src = inputs.cl-qrencode;
      lispDependencies = [ zpng ];
      lispCheckDependencies = [ lisp-unit ];
    }) {};

    cl-quickcheck = callPackage ({}: lispify "cl-quickcheck" [ ]) {};

    cl-redis = callPackage ({}: lispDerivation {
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
    }) {};

    cl-slice = callPackage ({}: lispDerivation {
      lispSystem = "cl-slice";
      src = inputs.cl-slice;
      lispDependencies = [ alexandria anaphora let-plus ];
      lispCheckDependencies = [ clunit ];
    }) {};

    cl-speedy-queue = callPackage ({}: lispify "cl-speedy-queue" [ ]) {};

    cl-strings = callPackage ({}: lispDerivation {
      lispSystem = "cl-strings";
      src = inputs.cl-strings;
      lispCheckDependencies = [ prove ];
    }) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) cl-syntax cl-syntax-annot cl-syntax-interpol;

    cl-test-more = prove;

    cl-tld = callPackage ({}: lispify "cl-tld" [ ]) {};

    cl-tls = callPackage ({}: lispify "cl-tls" [ ironclad alexandria fast-io cl-base64 ]) {};

    cl-unicode = callPackage ({}: lispDerivation {
      lispSystem = "cl-unicode";
      src = inputs.cl-unicode;
      lispDependencies = [ cl-ppcre flexi-streams ];
    }) {};

    # The official location for this source is
    # "https://www.common-lisp.net/project/cl-utilities/cl-utilities-latest.tar.gz"
    # but I’m not a huge fan of including a "latest.tar.gz" in a Nix
    # derivation. That being said: it hasn’t been changed since 2006, so maybe
    # that is a better resource.
    cl-utilities = callPackage ({}: lispDerivation {
      lispSystem = "cl-utilities";
      src = inputs.cl-utilities;
    }) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) cl-variates
           "cl-variates/with-metacopy";

    cl-who = callPackage ({}: lispDerivation {
      lispSystem = "cl-who";
      src = inputs.cl-who;
      lispCheckDependencies = [ flexi-streams ];
    }) {};

    inherit (callPackage ({}:
      lispMultiDerivation {
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
              lack-middleware-backtrace
              lack-util
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
      }) {}) clack clack-handler-hunchentoot clack-socket clack-test;

    closer-mop = callPackage ({}: lispify "closer-mop" [ ]) {};

    clss = callPackage ({}: lispify "clss" [ array-utils plump ]) {};

    clunit = callPackage ({}: lispify "clunit" [ ]) {};

    clunit2 = callPackage ({}: lispify "clunit2" [ ]) {};

    collectors = callPackage ({}: lispDerivation {
      lispSystem = "collectors";
      lispDependencies = [ alexandria closer-mop symbol-munger ];
      lispCheckDependencies = [ lisp-unit2 ];
      src = inputs.collectors;
    }) {};

    colorize = callPackage ({}: lispify "colorize" [ alexandria html-encode split-sequence ]) {};

    common-doc = callPackage ({}: lispDerivation {
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
    }) {};

    common-html = callPackage ({}: lispDerivation {
      src = inputs.common-html;
      lispSystems = ["common-html"];
      lispDependencies = [ common-doc plump anaphora alexandria ];
      lispCheckDependencies = [ fiveam ];
    }) {};

    commondoc-markdown = callPackage ({}: lispDerivation {
      lispSystem = "commondoc-markdown";
      src = inputs.commondoc-markdown;
      lispDependencies = [
        self."3bmd"
        self."3bmd-ext-code-blocks"
        common-doc
        common-html
        str
        ironclad
        f-underscore
      ];
      lispCheckDependencies = [ hamcrest rove ];
    }) {};

    concrete-syntax-tree = callPackage ({}: lispDerivation {
      lispDependencies = [ acclimation ];
      src = inputs.concrete-syntax-tree;
      lispSystem = "concrete-syntax-tree";
      lispAsdPath = [ "Lambda-list" ];
      preBuild = ''
        echo '(:source-registry-cache ' > .cl-source-registry.cache
        find . -name '*.asd' -exec printf '"%s" ' {} \; >> .cl-source-registry.cache
        echo ')' >> .cl-source-registry.cache
      '';
    }) {};

    contextl = callPackage ({}: lispDerivation {
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
    }) {};

    data-lens = callPackage ({}: lispDerivation {
      lispDependencies = [ cl-ppcre alexandria serapeum ];
      lispSystems = [ "data-lens" "data-lens/beta/transducers" ];
      lispCheckDependencies = [ fiveam string-case ];
      src = inputs.data-lens;
    }) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) dbi;

    deflate = callPackage ({}: lispify "deflate" []) {};

    dexador = callPackage ({}: lispDerivation {
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
      ] ++ lib.optional pkgs.hostPlatform.isWindows flexi-streams;
      lispCheckDependencies = [
        babel
        cl-cookie
        clack-test
        lack-request
        rove
      ];
    }) {};

    dissect = callPackage ({}: lispDerivation {
      lispSystem = "dissect";
      src = inputs.dissect;
      lispDependencies = l.optional ((lisp.pname or "") == "clisp") cl-ppcre;
    }) {};

    djula = callPackage ({}: lispDerivation {
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
    }) {};

    dns-client = callPackage ({}: lispify "dns-client" [ punycode usocket documentation-utils ]) {};

    # Technically these could be two separate derivations, one per system, but it
    # doesn’t seem like people use it that way, and there’s no dependencies
    # anyway, so there’s little benefit. Just treat this as a monolith package.
    docs-builder = callPackage ({}: lispDerivation {
      lispSystems = [ "docs-builder" "docs-config" ];
      src = inputs.docs-builder;
      lispDependencies = [ log4cl self."40ants-doc" ];
    }) {};

    documentation-utils = callPackage ({}: lispDerivation {
      lispSystem = "documentation-utils";
      src = inputs.documentation-utils;
      lispDependencies = [ trivial-indent ];
    }) {};

    drakma = callPackage ({}: lispDerivation {
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
    }) {};

    dynamic-classes = callPackage ({}: lispDerivation {
      lispSystem = "dynamic-classes";
      src = inputs.dynamic-classes;
      lispDependencies = [ metatilities-base ];
      lispCheckDependencies = [ lift ];
    }) {};

    eager-future2 = callPackage ({}: lispify "eager-future2" [ bordeaux-threads trivial-garbage ]) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) easy-routes
           "easy-routes+djula"
           "easy-routes+errors";

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) eclector eclector-concrete-syntax-tree;

    enchant = callPackage ({}: lispDerivation {
      lispDependencies = [ cffi ];
      lispSystem = "enchant";
      src = inputs.enchant;
    }) {};

    eos = callPackage ({}: lispify "eos" [ ]) {};

    esrap = callPackage ({}: lispDerivation {
      lispSystem = "esrap";
      src = inputs.esrap;
      lispDependencies = [ alexandria trivial-with-current-source-form ];
      lispCheckDependencies = [ fiveam ];
    }) {};

    f-underscore = callPackage ({}: lispify "f-underscore" [ ]) {};

    fast-http = callPackage ({}: lispDerivation {
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
    }) {};

    fast-io = callPackage ({}: lispify "fast-io" [
      alexandria
      static-vectors
      trivial-gray-streams
    ]) {};

    fare-mop = callPackage ({}: lispify "fare-mop" [
      closer-mop
      fare-utils
    ]) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
            trivia-quasiquote
          ];
        };
        fare-quasiquote-readtable = {
          lispDependencies = [ fare-quasiquote named-readtables ];
        };
      };
    }) {}) fare-quasiquote
           fare-quasiquote-extras
           fare-quasiquote-optima
           fare-quasiquote-readtable;

    fare-utils = callPackage ({}: lispDerivation {
      lispSystem = "fare-utils";
      src = inputs.fare-utils;
      lispCheckDependencies = [ hu_dwim_stefil ];
    }) {};

    # I’m defining this as a multideriv because it exposes lots of derivs. Even
    # though I only use one at the moment, it’s likely to change in the future.
    inherit (callPackage ({}: lispMultiDerivation {
      src = inputs.femlisp;
      systems = {
        infix = {};
      };
      dontConfigure = true;
      lispAsdPath = systems:
        l.optional (builtins.elem "infix" systems) "external/infix";
    }) {}) infix;

    fiasco = callPackage ({}: lispify "fiasco" [ alexandria trivial-gray-streams ]) {};

    find-port = callPackage ({}: lispDerivation {
      lispSystem = "find-port";
      lispCheckDependencies = [ fiveam ];
      lispDependencies = [ usocket ];
      src = inputs.find-port;
    }) {};

    fiveam = callPackage ({}: lispify "fiveam" [ alexandria asdf-flv trivial-backtrace ]) {};

    float-features = callPackage ({}: lispDerivation {
      lispSystem = "float-features";
      src = inputs.float-features;
      lispDependencies = [ documentation-utils ];
      lispCheckDependencies = [ parachute ];
    }) {};

    flexi-streams = callPackage ({}: lispify "flexi-streams" [ trivial-gray-streams ]) {};

    form-fiddle = callPackage ({}: lispDerivation {
      lispSystem = "form-fiddle";
      src = inputs.form-fiddle;
      lispDependencies = [ documentation-utils ];
    }) {};

    fset = callPackage ({}: lispify "fset" [ misc-extensions mt19937 named-readtables ]) {};

    garbage-pools = lispDerivation {
      lispSystem = "garbage-pools";
      src = inputs.garbage-pools;
      lispCheckDependencies = [ lift ];
    };

    gettext = callPackage ({}: lispDerivation {
      lispSystem = "gettext";
      src = inputs.gettext;
      lispDependencies = [ split-sequence yacc flexi-streams ];
      lispCheckDependencies = [ stefil ];
      preCheck = ''
        export CL_SOURCE_REGISTRY="$PWD/gettext-tests:$CL_SOURCE_REGISTRY"
      '';
    }) {};

    global-vars = callPackage ({}: lispify "global-vars" [ ]) {};

    hamcrest = callPackage ({}: lispDerivation {
      lispSystem = "hamcrest";
      lispCheckDependencies = [ prove rove ];
      lispDependencies = [
        self."40ants-asdf-system"
        alexandria
        iterate
        cl-ppcre
        split-sequence
      ];
      src = inputs.hamcrest;
    }) {};

    history-tree = callPackage ({}: lispDerivation {
      lispDependencies = [
        alexandria
        cl-custom-hash-table
        local-time
        nasdf
        nclasses
        trivial-package-local-nicknames
      ];
      src = inputs.history-tree;
      lispCheckDependencies = [ lisp-unit2 ];
      lispSystem = "history-tree";
    }) {};

    http-body = callPackage ({}: lispDerivation {
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
    }) {};

    html-encode = callPackage ({}: lispify "html-encode" [ ]) {};

    html-entities = callPackage ({}: lispDerivation {
      lispSystem = "html-entities";
      src = inputs.html-entities;
      lispDependencies = [ cl-ppcre ];
      lispCheckDependencies = [ fiveam ];
    }) {};

    hu_dwim_asdf = callPackage ({}: lispify "hu.dwim.asdf" [ ]) {};

    hu_dwim_stefil = callPackage ({}: lispify "hu.dwim.stefil" [ alexandria hu_dwim_asdf ]) {};

    hunchentoot = callPackage ({}: lispDerivation {
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
    }) {};

    hunchentoot-errors = callPackage ({}: lispify "hunchentoot-errors" [
      cl-mimeparse
      hunchentoot
      parse-number
      string-case
    ]) {};

    idna = callPackage ({}: lispify "idna" [ split-sequence ]) {};

    ieee-floats = callPackage ({}: lispDerivation {
      lispSystem = "ieee-floats";
      src = inputs.ieee-floats;
      lispCheckDependencies = [ fiveam ];
    }) {};

    inferior-shell = callPackage ({}: lispDerivation {
      lispSystem = "inferior-shell";
      lispDependencies = [
        alexandria
        fare-utils
        fare-quasiquote-extras
        fare-mop
        trivia
        trivia-quasiquote
      ];
      lispCheckDependencies = [ hu_dwim_stefil ];
      src = inputs.inferior-shell;
    }) {};

    infix-math = callPackage ({}: lispify "infix-math" [ alexandria serapeum wu-decimal parse-number ]) {};

    introspect-environment = callPackage ({}: lispDerivation {
      lispSystem = "introspect-environment";
      lispCheckDependencies = [ fiveam ];
      src = inputs.introspect-environment;
    }) {};

    ironclad = callPackage ({}: lispDerivation {
      lispSystem = "ironclad";
      src = inputs.ironclad;
      lispDependencies = [ bordeaux-threads ];
      lispCheckDependencies = [ rt ];
    }) {};

    iterate = callPackage ({}: lispDerivation {
      lispSystem = "iterate";
      src = inputs.iterate;
      lispCheckDependencies = l.optional ((lisp.pname or "") != "sbcl") rt;
    }) {};

    jonathan = callPackage ({}: lispDerivation {
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
    }) {};

    jpl-queues = callPackage ({}: lispDerivation rec {
      lispSystem = "jpl-queues";
      lispDependencies = [ bordeaux-threads jpl-util ];
      pname = "jpl-queues";
      version = "0.1";
      src = inputs.jpl-queues;
    }) {};

    jpl-util = callPackage ({}: lispDerivation {
      src = inputs.jpl-util;
      lispSystem = "jpl-util";
    }) {};

    json-streams = callPackage ({}: lispDerivation {
      src = inputs.json-streams;
      lispSystem = "json-streams";
      lispCheckDependencies = [ cl-quickcheck flexi-streams ];
    }) {};

    kmrcl = callPackage ({}: lispDerivation rec {
      lispSystem = "kmrcl";
      version = "4a27407aad9deb607ffb8847630cde3d041ea25a";
      src = inputs.kmrcl;
      lispCheckDependencies = [ rt ];
    }) {};

    inherit (callPackage ({}:
      lispMultiDerivation {
        src = inputs.lack;
        systems = {
          lack = {
            lispDependencies = [ lack-util ];
            lispCheckDependencies = [ clack prove ];
          };

          # meta nix-only derivation for packages that just want all of lack
          lack-full = {
            lispSystems = [
              "lack-app-directory"
              "lack-app-file"
              "lack-component"
              "lack-middleware-accesslog"
              "lack-middleware-auth-basic"
              "lack-middleware-backtrace"
              "lack-middleware-csrf"
              "lack-middleware-mount"
              "lack-middleware-session"
              "lack-middleware-static"
              "lack-request"
              "lack-response"
              "lack-session-store-dbi"
              "lack-session-store-redis"
              "lack-util-writer-stream"
              "lack-util"
              "lack"
            ];
            lispDependencies = [
              lack
              lack-middleware-backtrace
              lack-request
              lack-response
              lack-util
              # Kitchen sink dependencies
              # In an ideal world this would be unnecessary: every individual lack
              # system would be listed explicitly in Nix, with its dependencies. I
              # just can’t be bothered to do that right now.
              cl-base64
              cl-redis
              dbi
              marshal
              trivial-mimes
              trivial-rfc-1123
              trivial-utf-8
            ];
            lispCheckDependencies = [ lack-test ];
          };

          lack-middleware-backtrace = {
            lispCheckDependencies = [ alexandria lack prove ];
          };

          lack-request = {
            lispDependencies = [
              circular-streams
              cl-ppcre
              http-body
              quri
            ];
            lispCheckDependencies = [
              alexandria
              clack-test
              dexador
              flexi-streams
              hunchentoot
              prove
            ];
          };

          lack-response = {
            lispDependencies = [
              local-time
              quri
            ];
          };

          # stand-alone project used as a dependency of help systems
          lack-test = {
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

          lack-util = {
            lispDependencies = [ ironclad ];
            lispCheckDependencies = [ lack-test prove ];
          };
        };
      }) {}) lack
             lack-full
             lack-middleware-backtrace
             lack-request
             lack-response
             lack-test
             lack-util;

    lass = callPackage ({}: lispDerivation {
      lispSystems = [ "lass" "binary-lass" ];
      lispDependencies = [ trivial-indent trivial-mimes cl-base64 ];
      src = inputs.lass;
    }) {};

    legion = callPackage ({}: lispDerivation {
      lispSystem = "legion";
      src = inputs.legion;
      lispDependencies = [
        vom
        # Not listed in the .asd but these are required
        bordeaux-threads
        cl-speedy-queue
      ];
      lispCheckDependencies = [ local-time prove ];
    }) {};

    let-plus = callPackage ({}: lispDerivation {
      lispSystem = "let-plus";
      lispCheckDependencies = [ lift ];
      lispDependencies = [ alexandria anaphora ];
      src = inputs.let-plus;
    }) {};

    lift = callPackage ({}: lispify "lift" [ ]) {};

    lisp-namespace = callPackage ({}: lispDerivation {
      lispSystem = "lisp-namespace";
      lispDependencies = [ alexandria ];
      lispCheckDependencies = [ fiveam ];
      src = inputs.lisp-namespace;
    }) {};

    lisp-unit = callPackage ({}: lispify "lisp-unit" [ ]) {};

    lisp-unit2 = callPackage ({}: lispify "lisp-unit2" [
      alexandria
      cl-interpol
      iterate
      symbol-munger
    ]) {};

    lml2 = callPackage ({}: lispDerivation {
      lispDependencies = [ kmrcl ];
      lispCheckDependencies = [ rt ];
      lispSystem = "lml2";
      src = inputs.lml2;
    }) {};

    local-time = callPackage ({}: lispDerivation {
      lispSystem = "local-time";
      src = inputs.local-time;
      lispCheckDependencies = [ hu_dwim_stefil ];
    }) {};

    log4cl = callPackage ({}: lispDerivation {
      lispSystem = "log4cl";
      src = inputs.log4cl;
      lispDependencies = [ bordeaux-threads ];
      lispCheckDependencies = [ stefil ];
    }) {};

    log4cl-extras = callPackage ({}: lispDerivation {
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
    }) {};

    # Technically this package also contains a benchmark system with different
    # dependencies but I’m not going to bother exposing that to this scope.
    lparallel = (
      let
        # Please don’t use this anywhere else
        bordeaux-threads-v1 = bordeaux-threads.overrideAttrs (_: { src = inputs.bordeaux-threads-v1; });
      in
        callPackage ({}: lispify "lparallel" [
          alexandria
          # If anyone else in your entire family includes
          # bordeaux-threads-master, you’re dead.
          bordeaux-threads-v1
        ]) {});

    lquery = callPackage ({}: lispDerivation {
      lispSystem = "lquery";
      src = inputs.lquery;
      lispCheckDependencies = [ fiveam ];
      lispDependencies = [ array-utils form-fiddle plump clss ];
    }) {};

    lw-compat = callPackage ({}: lispify "lw-compat" []) {};

    marshal = callPackage ({}: lispDerivation {
      lispSystem = "marshal";
      lispCheckDependencies = [ xlunit ];
      src = inputs.marshal;
    }) {};

    md5 = callPackage ({}: lispify "md5" [ flexi-streams ]) {};

    metabang-bind = callPackage ({}: lispDerivation {
      lispSystem = "metabang-bind";
      src = inputs.metabang-bind;
      lispCheckDependencies = [ lift ];
    }) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) metacopy metacopy-with-contextl;

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) metatilities
           "metatilities/with-lift";

    metatilities-base = callPackage ({}: lispDerivation {
      lispSystem = "metatilities-base";
      src = inputs.metatilities-base;
      lispCheckDependencies = [ lift ];
    }) {};

    inherit (callPackage ({}:
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
        }) {}) dref
               mgl-pax
               "mgl-pax/full"
               mgl-pax-bootstrap;

    misc-extensions = callPackage ({}: lispify "misc-extensions" [ ]) {};

    moptilities = callPackage ({}: lispDerivation {
      lispSystem = "moptilities";
      lispDependencies = [ closer-mop ];
      lispCheckDependencies = [ lift ];
      src = inputs.moptilities;
    }) {};

    mt19937 = callPackage ({}: lispify "mt19937" [ ]) {};

    named-readtables = callPackage ({}: lispDerivation {
      lispSystem = "named-readtables";
      src = inputs.named-readtables;
      lispDependencies = [ mgl-pax-bootstrap ];
      lispCheckDependencies = [ try ];
    }) {};

    nclasses = callPackage ({}: lispDerivation {
      lispDependencies = [ moptilities nasdf ];
      src = inputs.nclasses;
      lispCheckDependencies = [ lisp-unit2 ];
      lispSystem = "nclasses";
    }) {};

    inherit (callPackage ({}: lispMultiDerivation {
      src =  inputs.nfiles;
      systems = {
        nfiles = {
          lispDependencies = [
            alexandria
            nasdf
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
        nasdf = {
          lispCheckDependencies = [
            lisp-unit2
          ];
        };
      };
      lispAsdPath = systems:
        l.optional (builtins.elem "nasdf" systems) "nasdf";
    }) {}) nfiles nasdf;

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) optima optima-ppcre;

    osicat = callPackage ({}: lispDerivation {
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
    }) {};

    parachute = callPackage ({}: lispify "parachute" [ documentation-utils form-fiddle trivial-custom-debugger ]) {};

    parenscript = callPackage ({}: lispDerivation {
      lispSystem = "parenscript";
      version = "2.7.1";
      src = inputs.parenscript;
      lispDependencies = [ anaphora cl-ppcre named-readtables ];
      lispCheckDependencies = [ fiveam cl-js ];
    }) {};

    parse-declarations = callPackage ({}: lispDerivation {
      lispSystem = "parse-declarations-1.0";
      src = inputs.parse-declarations;
    }) {};

    parse-js = callPackage ({}: lispify "parse-js" [ ]) {};

    parse-number = callPackage ({}: lispify "parse-number" [ ]) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) parser-combinators parser-combinators-cl-ppcre;

    path-parse = callPackage ({}: lispDerivation {
      lispSystem = "path-parse";
      lispCheckDependencies = [ fiveam ];
      lispDependencies = [ split-sequence ];
      src = inputs.path-parse;
    }) {};

    plump = callPackage ({}: lispify "plump" [ array-utils documentation-utils ]) {};

    proc-parse = callPackage ({}: lispDerivation {
      lispSystem = "proc-parse";
      lispDependencies = [ alexandria babel ];
      lispCheckDependencies = [ prove ];
      src = inputs.proc-parse;
    }) {};

    prove = callPackage ({}: lispDerivation {
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
    }) {};

    ptester = callPackage ({}: lispDerivation rec {
      lispSystem = "ptester";
      src = inputs.ptester;
    }) {};

    punycode = callPackage ({}: lispDerivation {
      lispSystem = "punycode";
      src = inputs.punycode;
      lispCheckDependencies = [ parachute ];
    }) {};

    puri = callPackage ({}: lispDerivation {
      lispSystem = "puri";
      src = inputs.puri;
      lispCheckDependencies = [ ptester ];
    }) {};

    pythonic-string-reader = callPackage ({}: lispify "pythonic-string-reader" [ named-readtables ]) {};

    quickhull = callPackage ({}: lispify "quickhull" [ self."3d-math" documentation-utils ]) {};

    quri = callPackage ({}: lispDerivation {
      lispSystem = "quri";
      lispDependencies = [ alexandria babel cl-utilities split-sequence ];
      lispCheckDependencies = [ prove ];
      src = inputs.quri;
    }) {};

    reblocks  = callPackage ({}: lispDerivation {
      lispSystem = "reblocks";
      src = inputs.reblocks;
      lispCheckDependencies = [ hamcrest ];
      lispDependencies = [
        self."40ants-doc"
        circular-streams
        cl-cookie
        cl-fad
        clack
        dexador
        f-underscore
        find-port
        http-body
        lack-full
        log4cl
        log4cl-extras
        metacopy
        metatilities
        parenscript
        routes
        salza2
        serapeum
        spinneret-cl-markdown
        trivial-open-browser
        trivial-timeout
        uuid
        yason
      ];
    }) {};

    rfc2388 = callPackage ({}: lispify "rfc2388" [ ]) {};

    routes = callPackage ({}: lispDerivation {
      lispSystem = "routes";
      src = inputs.routes;
      lispDependencies = [ puri iterate split-sequence ];
      lispCheckDependencies = [ lift ];
    }) {};

    # For some reason none of these dependencies are specified in the .asd
    rove = callPackage ({}: lispify "rove" [
      bordeaux-threads
      cl-ppcre
      dissect
      trivial-gray-streams
    ]) {};

    rt = callPackage ({}: lispDerivation rec {
      lispSystem = "rt";
      src = inputs.rt;
    }) {};

    # rutils and rutilsx have the same dependencies etc, it’s not worth the hassle
    # creating separate derivations for them.
    rutils = callPackage ({}: lispDerivation {
      lispSystems = [ "rutils" "rutilsx" ];
      src = inputs.rutils;
      lispDependencies = [ named-readtables closer-mop ];
      lispCheckDependencies = [ should-test ];
    }) {};

    s-sysdeps = callPackage ({}: lispify "s-sysdeps" [ usocket usocket-server bordeaux-threads ]) {};

    s-xml = callPackage ({}: lispify "s-xml" [ ]) {};

    salza2 = callPackage ({}: lispDerivation {
      lispSystem = "salza2";
      src = inputs.salza2;
      lispDependencies = [ trivial-gray-streams ];
      lispCheckDependencies = [
        chipz
        flexi-streams
        parachute
      ];
    }) {};

    serapeum = callPackage ({}: lispDerivation {
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
    }) {};

    should-test = callPackage ({}: lispDerivation {
      lispSystem = "should-test";
      lispDependencies = [ rutils local-time osicat cl-ppcre];
      # TODO: This should be propagated from osicat somehow, not in every client
      # using osicat.
      preBuild = ''
        export LD_LIBRARY_PATH=''${LD_LIBRARY_PATH+$LD_LIBRARY_PATH:}${osicat}/lib
      '';
      buildInputs = [ osicat ];
      src = inputs.should-test;
    }) {};

    simple-date-time = callPackage ({}: lispify "simple-date-time" [ cl-ppcre ]) {};

    slynk = callPackage ({}: lispDerivation {
      lispSystem = "slynk";
      src = inputs.sly;
      lispAsdPath = [ "slynk" ];
    }) {};

    smart-buffer = callPackage ({}: lispDerivation {
      lispSystem = "smart-buffer";
      src = inputs.smart-buffer;
      lispCheckDependencies = [ babel prove ];
      lispDependencies = [ flexi-streams xsubseq ];
    }) {};

    inherit (callPackage ({}: lispMultiDerivation {
      src = inputs.spinneret;
      lispCheckDependencies = [ fiveam parenscript ];

      systems = {
        spinneret = {
          lispDependencies = [
            alexandria
            cl-ppcre
            global-vars
            parenscript
            serapeum
            trivia
            trivial-gray-streams
          ];
        };
        spinneret-cl-markdown = {
          lispSystem = "spinneret/cl-markdown";
          lispDependencies = [ spinneret cl-markdown ];
        };
      };
    }) {}) spinneret
           spinneret-cl-markdown;

    split-sequence = callPackage ({}: lispDerivation {
      lispSystem = "split-sequence";
      lispCheckDependencies = [ fiveam ];
      src = inputs.split-sequence;
    }) {};

    # N.B.: Soon won’t depend on cffi-grovel
    static-vectors = callPackage ({}: lispDerivation {
      lispSystem = "static-vectors";
      src = inputs.static-vectors;
      lispDependencies = [ alexandria cffi cffi-grovel ];
      lispCheckDependencies = [ fiveam ];
    }) {};

    stefil = callPackage ({}: lispify "stefil" [
      alexandria
      iterate
      metabang-bind
      swank
    ]) {};

    stem = callPackage ({}: lispify "stem" []) {};

    str = callPackage ({}: lispDerivation {
      lispSystem = "str";
      src = inputs.str;
      lispDependencies = [
        cl-change-case
        cl-ppcre
        cl-ppcre-unicode
      ];
      lispCheckDependencies = [ prove ];
    }) {};

    string-case = callPackage ({}: lispify "string-case" [ ]) {};

    swank = callPackage ({}: lispDerivation {
      lispSystem = "swank";
      # The Swank Lisp system is bundled with SLIME
      src = inputs.slime;
      patches = ./patches/slime-fix-swank-loader-fasl-cache-pwd.diff;
    }) {};

    symbol-munger = callPackage ({}: lispDerivation {
      src = inputs.symbol-munger;
      lispSystem = "symbol-munger";
      lispDependencies = [ alexandria iterate ];
      lispCheckDependencies = [ lisp-unit2 ];
    }) {};

    tmpdir = callPackage ({}: lispify "tmpdir" [ cl-fad ]) {};

    inherit (callPackage ({}: lispMultiDerivation {
      src = inputs.trivia;

      systems = {
        trivia = {
          lispDependencies = [
            alexandria
            iterate
            trivia-trivial
            type-i
          ];
          lispCheckDependencies = [
            fiveam
            optima
            trivia-cffi
            trivia-fset
            trivia-ppcre
            trivia-quasiquote
          ];
        };

        trivia-cffi = {
          lispSystem = "trivia.cffi";
          lispDependencies = [
            cffi
            trivia-trivial
          ];
        };

        trivia-fset = {
          lispSystem = "trivia.fset";
          lispDependencies = [
            fset
            trivia-trivial
          ];
        };

        trivia-ppcre = {
          lispSystem = "trivia.ppcre";
          lispDependencies = [
            cl-ppcre
            trivia-trivial
          ];
        };

        trivia-quasiquote = {
          lispSystem = "trivia.quasiquote";
          lispDependencies = [
            fare-quasiquote-readtable
            trivia
          ];
        };

        trivia-trivial = {
          lispSystem = "trivia.trivial";
          lispDependencies = [
            alexandria
            closer-mop
            lisp-namespace
            trivial-cltl2
          ];
        };
      };
    }) {}) trivia
           trivia-cffi
           trivia-fset
           trivia-ppcre
           trivia-quasiquote
           trivia-trivial;

    trivial-arguments = callPackage ({}: lispify "trivial-arguments" [ ]) {};

    trivial-backtrace = callPackage ({}: lispify "trivial-backtrace" [ lift ]) {};

    trivial-benchmark = callPackage ({}: lispify "trivial-benchmark" [ alexandria ]) {};

    trivial-cltl2 = callPackage ({}: lispDerivation {
      lispSystem = "trivial-cltl2";
      src = inputs.trivial-cltl2;
    }) {};

    trivial-custom-debugger = callPackage ({}: lispDerivation {
      src = inputs.trivial-custom-debugger;
      lispSystem = "trivial-custom-debugger";
      lispCheckDependencies = [ parachute ];
    }) {};

    trivial-extract = callPackage ({}: lispDerivation {
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
    }) {};

    trivial-features = callPackage ({}: lispDerivation {
      src = inputs.trivial-features;
      lispSystem = "trivial-features";
      lispCheckDependencies = [ rt cffi cffi-grovel alexandria ];
    }) {};

    trivial-file-size = callPackage ({}: lispDerivation {
      src = inputs.trivial-file-size;
      lispCheckDependencies = [ fiveam ];
      lispSystem = "trivial-file-size";
    }) {};

    trivial-garbage = callPackage ({}: lispDerivation {
      src = inputs.trivial-garbage;
      lispSystem = "trivial-garbage";
      lispCheckDependencies = [ rt ];
    }) {};

    trivial-gray-streams = callPackage ({}: lispify "trivial-gray-streams" [ ]) {};

    trivial-indent = callPackage ({}: lispify "trivial-indent" [ ]) {};

    trivial-macroexpand-all = callPackage ({}: lispify "trivial-macroexpand-all" [ ]) {};

    trivial-mimes = callPackage ({}: lispify "trivial-mimes" [ ]) {};

    trivial-open-browser = callPackage ({}: lispify "trivial-open-browser" [ ]) {};

    trivial-package-local-nicknames = callPackage ({}: lispify "trivial-package-local-nicknames" [ ]) {};

    trivial-rfc-1123 = callPackage ({}: lispify "trivial-rfc-1123" [ cl-ppcre ]) {};

    trivial-shell = callPackage ({}: lispDerivation {
      lispSystem = "trivial-shell";
      src = inputs.trivial-shell;
      lispCheckDependencies = [ lift ];
    }) {};

    trivial-sockets = callPackage ({}: lispify "trivial-sockets" [ ]) {};

    trivial-timeout = callPackage ({}: lispDerivation {
      lispSystem = "trivial-timeout";
      lispCheckDependencies = [ lift ];
      src = inputs.trivial-timeout;
    }) {};

    trivial-types = callPackage ({}: lispify "trivial-types" [ ]) {};

    trivial-utf-8 = callPackage ({}: lispify "trivial-utf-8" [ mgl-pax-bootstrap ]) {};

    trivial-with-current-source-form = callPackage ({}: lispify "trivial-with-current-source-form" [ alexandria ]) {};

    try = callPackage ({}: lispify "try" [
      alexandria
      cl-ppcre
      closer-mop
      ieee-floats
      mgl-pax
      trivial-gray-streams
    ]) {};

    type-i = callPackage ({}: lispDerivation {
      lispSystem = "type-i";
      src = inputs.type-i;
      lispDependencies = [
        alexandria
        introspect-environment
        trivia-trivial
        lisp-namespace
      ];
      lispCheckDependencies = [ fiveam ];
    }) {};

    type-templates = callPackage ({}: lispDerivation {
      lispDependencies = [ alexandria form-fiddle documentation-utils ];
      lispSystem = "type-templates";
      src = inputs.type-templates;
    }) {};

    typo = callPackage ({}: lispDerivation {
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
    }) {};

    unit-test = callPackage ({}: lispify "unit-test" [ ]) {};

    inherit (callPackage ({}: lispMultiDerivation {
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
    }) {}) usocket usocket-server;

    uuid = callPackage ({}: lispify "uuid" [ ironclad trivial-utf-8 ]) {};

    vom = callPackage ({}: lispify "vom" [ ]) {};

    which = callPackage ({}: lispDerivation {
      lispSystem = "which";
      src = inputs.which;
      lispCheckDependencies = [ fiveam ];
      lispDependencies = [ path-parse cl-fad ];
    }) {};

    wild-package-inferred-system = callPackage ({}: lispDerivation {
      lispCheckDependencies = [ fiveam ];
      lispSystem = "wild-package-inferred-system";
      src = inputs.wild-package-inferred-system;
    }) {};

    with-output-to-stream = callPackage ({}: lispDerivation {
      lispSystem = "with-output-to-stream";
      version = "1.0";
      src = inputs.with-output-to-stream;
    }) {};

    wu-decimal = callPackage ({}: lispify "wu-decimal" []) {};

    xml-emitter = callPackage ({}: lispDerivation {
      src = inputs.xml-emitter;
      lispSystem = "xml-emitter";
      lispDependencies = [ cl-utilities ];
      lispCheckDependencies = [ self."1am" ];
    }) {};

    xlunit = callPackage ({}: lispDerivation rec {
      lispSystem = "xlunit";
      version = "3805d34b1d8dc77f7e0ee527a2490194292dd0fc";
      src = inputs.xlunit;
    }) {};

    xsubseq = callPackage ({}: lispDerivation {
      src = inputs.xsubseq;
      lispSystem = "xsubseq";
      lispCheckDependencies = [ prove ];
    }) {};

    # QL calls this "cl-yacc", but the system name is "yacc", so I’m sticking to
    # "yacc". Regardless of the repo name--that’s not authoritative. The system
    # name is.
    yacc = callPackage ({}: lispDerivation {
      lispSystem = "yacc";
      src = inputs.yacc;
    }) {};

    yason = callPackage ({}: lispify "yason" [ alexandria trivial-gray-streams ]) {};

    zip = callPackage ({}: lispify "zip" [ trivial-gray-streams babel cl-fad salza2 ]) {};

    zpng = callPackage ({}: lispify "zpng" [ salza2 ]) {};
  }));
}
