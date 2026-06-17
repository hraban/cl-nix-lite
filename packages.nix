{
  inputs,
  gcc,
  lib,
  libffi,
  libuv,
  lisp,
  mpfr,
  pkg-config,
  stdenv,
  xcbuild,
}:

let
  packages =
    self: prev:
    with self;
    let
      lispify =
        name: lispDependencies:
        lispDerivation {
          inherit lispDependencies;
          lispSystem = name; # convention
          src = inputs.${name};
        };
    in
    {
      "1am" = lispify "1am" [ ];

      inherit
        (lispMultiDerivation {
          src = inputs."3bmd";
          systems = {
            "3bmd" = {
              lispSystem = "3bmd";
              lispDependencies = [
                alexandria
                esrap
                split-sequence
              ];
              lispCheckDependencies = [
                self."3bmd-ext-code-blocks"
                fiasco
              ];
            };
            "3bmd-ext-code-blocks" = {
              lispSystem = "3bmd-ext-code-blocks";
              lispDependencies = [
                self."3bmd"
                alexandria
                colorize
                split-sequence
              ];
            };
            "3bmd-ext-tables" = {
              lispSystem = "3bmd-ext-tables";
              lispDependencies = [ self."3bmd" ];
            };
          };
        })
        "3bmd"
        "3bmd-ext-code-blocks"
        "3bmd-ext-tables"
        ;

      "3d-math" = lispDerivation {
        lispDependencies = [
          documentation-utils
          type-templates
        ];
        lispCheckDependencies = [ parachute ];
        src = inputs."3d-math";
        # For ABCL, if that would fix it: _JAVA_OPTIONS="-Xmx4g";
        env = lib.optionalAttrs (lisp.name == "sbcl") { NIX_SBCL_DYNAMIC_SPACE_SIZE = "4gb"; };
        lispSystem = "3d-math";
        # Compiling this on CLISP hangs forever.
        # On ECL:
        # * The declaration (DECLARE (FTYPE (FUNCTION ((OR IVEC4 DVEC4 VEC4 IVEC3 DVEC3 VEC3 IVEC2 DVEC2 VEC2)) (VALUES (OR I32 F64 F32) &OPTIONAL)) VX)) was found in a bad place.
        meta.broken = builtins.elem lisp.name [
          "clisp"
          "ecl"
          "abcl"
        ];
      };

      "3d-vectors" = lispDerivation {
        lispDependencies = [ documentation-utils ];
        lispCheckDependencies = [ parachute ];
        src = inputs."3d-vectors";
        lispSystem = "3d-vectors";
      };

      inherit
        (lispMultiDerivation {
          src = inputs."40ants-doc";
          systems = {
            "40ants-doc" = {
              lispSystem = "40ants-doc";
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
              lispSystem = "40ants-doc-full";
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
        })
        "40ants-doc"
        "40ants-doc-full"
        ;

      "40ants-asdf-system" = lispDerivation {
        lispSystem = "40ants-asdf-system";
        src = inputs."40ants-asdf-system";
        # Depends on a modern ASDF. SBCL’s built-in ASDF crashes this. Explicitly
        # listing self. here to avoid grabbing nixpkgs.asdf.
        lispDependencies = [ asdf ];
        lispCheckDependencies = [ rove ];
      };

      access = lispDerivation {
        lispSystem = "access";
        src = inputs.access;
        lispDependencies = [
          alexandria
          closer-mop
          iterate
          cl-ppcre
        ];
        lispCheckDependencies = [ lisp-unit2 ];
      };

      acclimation = lispify "acclimation" [ ];

      alexandria = lispDerivation {
        lispSystem = "alexandria";
        src = inputs.alexandria;
        # Contrary to what its .asd file suggests, Alexandria now requires rt even
        # on SBCL. This is recent (introduced after v1.4).
        lispCheckDependencies = [ rt ];
      };

      alien-ring = lispify "alien-ring" [
        cffi
        trivial-gray-streams
      ];

      anaphora = lispDerivation {
        lispSystem = "anaphora";
        lispCheckDependencies = [ rt ];
        src = inputs.anaphora;
      };

      anypool = lispDerivation {
        src = inputs.anypool;
        lispSystem = "anypool";
        lispDependencies = [
          bordeaux-threads
          cl-speedy-queue
        ];
        lispCheckDependencies = [ rove ];
      };

      archive = lispify "archive" [
        cl-fad
        trivial-gray-streams
      ];

      inherit
        (lispMultiDerivation {
          src = inputs.arnesi;
          systems = {
            arnesi = {
              lispDependencies = [ collectors ];
              lispCheckDependencies = [ fiveam ];
            };
            arnesi-cl-ppcre-extras = {
              lispSystem = "arnesi/cl-ppcre-extras";
              lispDependencies = [
                arnesi
                cl-ppcre
              ];
            };
            arnesi-slime-extras = {
              lispSystem = "arnesi/slime-extras";
              lispDependencies = [
                arnesi
                swank
              ];
            };
          };
          # #<PACKAGE CHARSET> has no external symbol with name "UTF-16"
          meta.broken = lisp.name == "clisp";
        })
        arnesi
        arnesi-cl-ppcre-extras
        arnesi-slime-extras
        ;

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
        # Sometimes a dependent project will try and build asdf/defsystem. I’m
        # not exactly clear on when this happens but it’s fixed by just always
        # precompiling it here.
        lispSystems = [
          "asdf"
          "asdf/defsystem"
        ];
        src = inputs.asdf;
        # Not exactly sure why, but clasp doesn’t seem happy rebuilding asdf
        # from source?
        meta.broken = lisp.name == "clasp";
      };

      asdf-flv = lispDerivation {
        lispSystem = "net.didierverna.asdf-flv";
        src = inputs.asdf-flv;
      };

      asdf-system-connections = lispify "asdf-system-connections" [ ];

      assoc-utils = lispDerivation {
        lispSystem = "assoc-utils";
        src = inputs.assoc-utils;
        lispCheckDependencies = [ rove ];
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
        meta.broken = builtins.elem lisp.name [
          "abcl"
          "clisp"
        ];
      };

      inherit
        (lispMultiDerivation {
          src = inputs.babel;

          systems = {
            babel = {
              lispDependencies = [
                alexandria
                trivial-features
              ];
              lispCheckDependencies = [ hu_dwim_stefil ];
            };
            babel-streams = {
              lispDependencies = [
                alexandria
                babel
                trivial-gray-streams
              ];
              lispCheckDependencies = [ hu_dwim_stefil ];
            };
          };
        })
        babel
        babel-streams
        ;

      blackbird = lispDerivation {
        lispSystem = "blackbird";
        src = inputs.blackbird;
        lispDependencies = [ vom ];
        lispCheckDependencies = [
          cl-async
          fiveam
        ];
      };

      bordeaux-threads = lispDerivation {
        lispDependencies = [
          alexandria
          global-vars
          trivial-features
          trivial-garbage
        ];
        lispCheckDependencies = [ fiveam ];
        buildInputs = [ libuv ];
        lispSystem = "bordeaux-threads";
        src = inputs.bordeaux-threads;
        meta.broken = lisp.name == "clisp" || (lisp.name == "sbcl" && !lisp.deriv.threadSupport);
      };

      inherit
        (lispMultiDerivation rec {
          src = inputs.cffi;
          patches = ./patches/clffi-libffi-no-darwin-carevout.patch;
          systems = {
            cffi = {
              lispDependencies = [
                alexandria
                babel
                trivial-features
              ];
              lispCheckDependencies = [
                cffi-grovel
                bordeaux-threads
                rt
              ];
              # I don’t know if cffi-libffi is external but it doesn’t seem to be
              # so just leave it for now.
            };
            cffi-grovel = {
              # cffi-grovel depends on cffi-toolchain. Just specifying it as an
              # exported system works because cffi-toolchain is specified in this
              # same source derivation.
              lispSystems = [
                "cffi-grovel"
                "cffi-toolchain"
              ];
              lispDependencies = [
                alexandria
                cffi
                trivial-features
              ];
              lispCheckDependencies = [
                bordeaux-threads
                rt
              ];
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
          nativeBuildInputs = [
            pkg-config
            gcc
          ];
          propagatedBuildInputs = lib.optionals stdenv.isDarwin [
            # On Darwin, osicat needed access to the libtool package. I have a
            # feeling that’s because of CFFI, and CFFI should provide it, but
            # honestly I don’t know if this is the right place. Maybe I should just
            # make osicat define this as a nativeBuildInput?
            xcbuild
          ];
          buildInputs = systems: lib.optionals (builtins.elem "cffi" systems) [ libffi ];
          # This is broken on Darwin because libcffi rewrites the import path in a
          # way that’s incompatible with pkgconfig. It should be "if darwin AND (not
          # pkg-config)".

          setupHooks =
            systems:
            lib.optionals (builtins.elem "cffi" systems) [
              (
                if
                  stdenv.hostPlatform.isDarwin
                # LD_.. only works with CFFI on Mac, but not with
                # sb-alien:load-shared-object. DYLD_.. works with both.
                then
                  builtins.toFile "cffi-setup-hook-darwin.sh" (
                    builtins.replaceStrings [ "LD_LIBRARY_PATH" ] [ "DYLD_LIBRARY_PATH" ] (
                      builtins.readFile ./cffi-setup-hook.sh
                    )
                  )
                else
                  ./cffi-setup-hook.sh
              )
            ];
          meta =
            systems:
            lib.optionalAttrs (builtins.elem "cffi" systems) {
              # CFFI requires CLISP compiled with dynamic FFI support, which only
              # enabled on Linux. And it’s supposed to work with ABCL but I don’t know
              # how, so I’m marking this broken for now.
              broken = !(lisp.name == "clisp" -> stdenv.isLinux) || lisp.name == "abcl";
            };
        })
        cffi
        cffi-grovel
        ;

      calispel = lispDerivation {
        lispSystem = "calispel";
        src = inputs.calispel;
        lispDependencies = [
          jpl-queues
          bordeaux-threads
        ];
        lispCheckDependencies = [ eager-future2 ];
      };

      chipz = lispify "chipz" [ ];

      chunga = lispify "chunga" [ trivial-gray-streams ];

      inherit
        (lispMultiDerivation {
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
              lispDependencies = [
                coalton
                json-streams
              ];
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
          propagatedBuildInputs =
            systems:
            lib.optionals (builtins.elem "coalton" systems) [
              # Actual dependencies
              mpfr
              libuv
              # For the dynamic loading setup hook, even though we don’t even use
              # CFFI. Needs better UX.
              cffi
            ];
          preBuild =
            let
              testDirectories = [
                "$PWD/examples/coalton-json"
                "$PWD/examples/quil-coalton"
                "$PWD/examples/small-coalton-programs"
                "$PWD/examples/thih"
              ];
              testPaths = b.concatStringsSep ":" testDirectories;
            in
            ''
              export CL_SOURCE_REGISTRY="${testPaths}:$CL_SOURCE_REGISTRY"
            '';
          meta = {
            # Broken since the last update and I can’t exactly figure out why.
            broken = true;
          };
        })
        coalton
        coalton-benchmarks
        coalton-doc
        coalton-examples
        ;

      cl-difflib = callPackage (
        { lispDerivation }:
        lispDerivation {
          lispSystem = "cl-difflib";
          src = inputs.cl-difflib;
        }
      ) { };
    };
in
packages
