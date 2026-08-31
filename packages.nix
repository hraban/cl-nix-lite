{ lib, pkgs }:

final: prev:
with final;
let
  hasSystem =
    drv: sys:
    if builtins.isList sys then builtins.any (hasSystem drv) sys else builtins.elem sys drv.lispSystems;
  lispify =
    name: lispDependencies:
    lispDerivation {
      inherit lispDependencies;
      lispSystem = name; # convention
      src = sources.${name};
    };
  sources = final._sources;
in
{
  "1am" = lispDerivation {
    lispSystem = "1am";
    src = sources.x_1am;
  };

  "3bmd" = lispDerivation (self: {
    src = sources.x_3bmd;
    lispSystem = "3bmd";
    lispDependencies = [
      alexandria
      esrap
      split-sequence
    ]
    ++ lib.optionals (hasSystem self "3bmd-ext-code-blocks") [ colorize ]
    ++ lib.optionals (self.doCheck or false) [
      final."3bmd-ext-code-blocks"
      fiasco
    ];
    meta.broken =
      (self.doCheck or false)
      && (
        (final._lisp.name == "abcl")
        || (
          (hasSystem self "3bmd-ext-code-blocks")
          && (final._lisp.name == "clisp")
          && pkgs.stdenv.hostPlatform.isLinux
        )
      );
  });

  "3bmd-ext-code-blocks" = final."3bmd".overrideAttrs (old: {
    lispSystems = [
      "3bmd"
      "3bmd-ext-code-blocks"
    ];
  });

  "3bmd-ext-math" = final."3bmd".overrideAttrs (old: {
    lispSystems = [
      "3bmd"
      "3bmd-ext-math"
    ];
  });

  "3bmd-ext-tables" = final."3bmd".overrideAttrs (old: {
    lispSystems = [
      "3bmd"
      "3bmd-ext-tables"
    ];
  });

  "3d-math" = lispDerivation (self: {
    lispDependencies = [
      documentation-utils
      type-templates
    ]
    ++ lib.optionals (self.doCheck or false) [ parachute ];
    src = sources.x_3d-math;
    # For ABCL, if that would fix it: _JAVA_OPTIONS="-Xmx6g";
    env = lib.optionalAttrs (final._lisp.name == "sbcl") { NIX_SBCL_DYNAMIC_SPACE_SIZE = "6gb"; };
    lispSystem = "3d-math";
    meta.broken = builtins.elem final._lisp.name [
      "abcl"
      # BUG: Unknown packing-type SHORT-FLOAT
      "clasp"
      # Compilation hangs forever.
      "clisp"
      # * The declaration (DECLARE (FTYPE (FUNCTION ((OR IVEC4 DVEC4 VEC4 IVEC3 DVEC3 VEC3 IVEC2 DVEC2 VEC2)) (VALUES (OR I32 F64 F32) &OPTIONAL)) VX)) was found in a bad place.
      "ecl"
    ];
  });

  "3d-vectors" = lispDerivation (self: {
    lispDependencies = [ documentation-utils ] ++ lib.optionals (self.doCheck or false) [ parachute ];
    src = sources.x_3d-vectors;
    lispSystem = "3d-vectors";
  });

  "40ants-doc" = lispDerivation (self: {
    src = sources.x_40ants-doc;
    lispSystems = [ "40ants-doc" ] ++ lib.optionals (self.doCheck or false) [ "40ants-doc-full" ];
    lispDependencies =
      lib.optionals (hasSystem self "40ants-doc") [
        cl-ppcre
        commondoc-markdown
        named-readtables
        pythonic-string-reader
        slynk
        str
        swank
      ]
      ++ lib.optionals (hasSystem self "40ants-doc-full") [
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
      ]
      ++ lib.optionals ((self.doCheck or false) && (hasSystem self "40ants-doc")) [ rove ];
    # this one works in QL so it’s nix specific
    meta.broken = self.doCheck or false;
  });

  "40ants-doc-full" = final."40ants-doc".overrideAttrs {
    lispSystems = [
      "40ants-doc"
      "40ants-doc-full"
    ];
  };

  "40ants-asdf-system" = lispDerivation (self: {
    lispSystem = "40ants-asdf-system";
    src = sources.x_40ants-asdf-system;
    # Depends on a modern ASDF. SBCL’s built-in ASDF crashes this. Explicitly
    # listing final. here to avoid grabbing nixpkgs.asdf.
    lispDependencies = [ asdf ] ++ lib.optionals (self.doCheck or false) [ rove ];
  });

  "40ants-routes" = lispDerivation (self: {
    lispSystem = "40ants-routes";
    src = sources.routes;
    lispDependencies = [
      final."40ants-asdf-system"
      cl-ppcre
      serapeum
      split-sequence
      str
    ]
    ++ lib.optionals (self.doCheck or false) [ rove ];
  });

  access = lispDerivation (self: {
    lispSystem = "access";
    src = sources.access;
    lispDependencies = [
      alexandria
      closer-mop
      iterate
      cl-ppcre
    ]
    ++ lib.optionals (self.doCheck or false) [ lisp-unit2 ];
    # The variable ACCESS-BASIC is unbound.
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  acclimation = lispify "acclimation" [ ];

  alexandria = lispDerivation (self: {
    lispSystem = "alexandria";
    src = sources.alexandria;
    # Contrary to what its .asd file suggests, Alexandria now requires rt even
    # on SBCL. This is recent (introduced after v1.4).
    lispDependencies = lib.optionals (self.doCheck or false) [ rt ];
  });

  alien-ring = lispify "alien-ring" [
    cffi
    trivial-gray-streams
  ];

  anaphora = lispDerivation (self: {
    lispSystem = "anaphora";
    lispDependencies = lib.optionals (self.doCheck or false) [ rt ];
    src = sources.anaphora;
  });

  anypool = lispDerivation (self: {
    src = sources.anypool;
    lispSystem = "anypool";
    lispDependencies = [
      bordeaux-threads
      cl-speedy-queue
    ]
    ++ lib.optionals (self.doCheck or false) [ rove ];
    # Oddly specific failure: "https://github.com/fukamachi/anypool/issues/5".
    meta.broken =
      (self.doCheck or false)
      && (
        !(builtins.elem final._lisp.name [
          "ecl"
          "clisp"
        ])
      )
      && (pkgs.stdenv.hostPlatform.system == "x86_64-darwin");
  });

  archive = lispify "archive" [
    cl-fad
    trivial-gray-streams
  ];

  arnesi = lispDerivation (self: {
    src = sources.arnesi;
    lispSystem = "arnesi";
    lispDependencies =
      lib.optionals (hasSystem self "arnesi") [ collectors ]
      ++ lib.optionals (hasSystem self "arnesi/cl-ppcre-extras") [ cl-ppcre ]
      ++ lib.optionals (hasSystem self "arnesi/slime-extras") [ swank ]
      ++ lib.optionals ((self.doCheck or false) && (hasSystem self "arnesi")) [ fiveam ];
    # #<PACKAGE CHARSET> has no external symbol with name "UTF-16"
    meta.broken = final._lisp.name == "clisp" || (self.doCheck or false);
  });

  arnesi-cl-ppcre-extras = arnesi.overrideAttrs {
    name = "arnesi-cl-ppcre-extras";
    lispSystems = [
      "arnesi"
      "arnesi/cl-ppcre-extras"
    ];
  };

  arnesi-slime-extras = arnesi.overrideAttrs {
    name = "arnesi-slime-extras";
    lispSystems = [
      "arnesi"
      "arnesi/slime-extras"
    ];
  };

  array-utils = lispDerivation (self: {
    lispSystem = "array-utils";
    lispDependencies = lib.optionals (self.doCheck or false) [ parachute ];
    src = sources.array-utils;
  });

  arrow-macros = lispDerivation (self: {
    lispSystem = "arrow-macros";

    src = sources.arrow-macros;

    lispDependencies = [ alexandria ] ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  asdf = lispDerivation {
    # Sometimes a dependent project will try and build asdf/defsystem. I’m
    # not exactly clear on when this happens but it’s fixed by just always
    # precompiling it here.
    lispSystems = [
      "asdf"
      "asdf/defsystem"
    ];
    src = sources.asdf;
    # Not exactly sure why, but clasp doesn’t seem happy rebuilding asdf
    # from source?
    meta.broken = final._lisp.name == "clasp";
  };

  asdf-flv = lispDerivation {
    lispSystem = "net.didierverna.asdf-flv";
    src = sources.asdf-flv;
  };

  asdf-system-connections = lispify "asdf-system-connections" [ ];

  assoc-utils = lispDerivation (self: {
    lispSystem = "assoc-utils";
    src = sources.assoc-utils;
    lispDependencies = lib.optionals (self.doCheck or false) [ rove ];
  });

  atomics = lispDerivation (self: {
    lispSystem = "atomics";
    src = sources.atomics;
    lispDependencies = [ documentation-utils ] ++ lib.optionals (self.doCheck or false) [ parachute ];
    # CLISP is not supported by the Atomics library.
    # The CAS operation is not supported by Armed Bear Common Lisp in Atomics.
    # This is most likely due to lack of support by the implementation.
    # If you think this is in error, and the implementation does expose
    # the necessary operators, please file an issue at
    #   https://github.com/shinmera/atomics/issues
    meta.broken = builtins.elem final._lisp.name [
      "abcl"
      "clisp"
    ];
  });

  autoload = lispDerivation (self: {
    src = sources.autoload;
    lispSystem = "autoload";
    lispDependencies = [
      closer-mop
      mgl-pax-bootstrap
      trivial-indent
    ]
    ++ lib.optionals (self.doCheck or false) [ try ]
    ++ lib.optionals (hasSystem self "autoload-doc") [
      dref
      mgl-pax
      named-readtables
      pythonic-string-reader
    ];
    # Excessively CPU intensive test
    meta.broken = self.doCheck or false;
  });

  autoload-doc = autoload.overrideAttrs {
    lispSystems = [
      "autoload"
      "autoload-doc"
    ];
  };

  babel = lispDerivation (self: {
    src = sources.babel;
    lispSystem = "babel";
    lispDependencies =
      lib.optionals (hasSystem self "babel") [
        alexandria
        trivial-features
      ]
      ++ lib.optionals (hasSystem self "babel-streams") [ trivial-gray-streams ]
      ++ lib.optionals (self.doCheck or false) [ hu_dwim_stefil ];
  });

  babel-streams = babel.overrideAttrs {
    name = "babel-streams";
    lispSystems = [
      "babel"
      "babel-streams"
    ];
  };

  blackbird = lispDerivation (self: {
    lispSystem = "blackbird";
    src = sources.blackbird;
    lispDependencies = [
      vom
    ]
    ++ lib.optionals (self.doCheck or false) [
      cl-async
      fiveam
    ];
  });

  bordeaux-threads = lispDerivation (self: {
    lispDependencies = [
      alexandria
      global-vars
      trivial-features
      trivial-garbage
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
    buildInputs = [ pkgs.libuv ];
    lispSystem = "bordeaux-threads";
    src = sources.bordeaux-threads;
    meta.broken =
      (final._lisp.name == "clisp" || (final._lisp.name == "sbcl" && !final._lisp.deriv.threadSupport))
      || (self.doCheck or false) # There’s a deadlock heisenbug in these tests
    ;
  });

  cffi = lispDerivation (self: {
    name = "cffi";
    src = sources.cffi;
    patches = ./patches/clffi-libffi-no-darwin-carevout.patch;
    lispSystems = [ "cffi" ] ++ lib.optionals (self.doCheck or false) [ "cffi-grovel" ];
    # I don’t know if cffi-libffi is external but it doesn’t seem to be
    # so just leave it for now.
    lispDependencies =
      lib.optionals (hasSystem self "cffi") [
        alexandria
        babel
        trivial-features
      ]
      ++ lib.optionals (self.doCheck or false) [
        bordeaux-threads
        rt
      ];
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
    propagatedBuildInputs = lib.optionals pkgs.stdenv.isDarwin [
      # On Darwin, osicat needed access to the libtool package. I have a
      # feeling that’s because of CFFI, and CFFI should provide it, but
      # honestly I don’t know if this is the right place. Maybe I should just
      # make osicat define this as a nativeBuildInput?
      pkgs.xcbuild
    ];
    buildInputs = lib.optionals (hasSystem self "cffi") [ pkgs.libffi ];
    # This is broken on Darwin because libcffi rewrites the import path in a
    # way that’s incompatible with pkgconfig. It should be "if darwin AND (not
    # pkg-config)".

    setupHooks = lib.optionals (hasSystem self "cffi") [
      (
        if
          pkgs.stdenv.hostPlatform.isDarwin
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
    # CFFI requires CLISP compiled with dynamic FFI support, which only
    # enabled on Linux. And it’s supposed to work with ABCL but I don’t know
    # how, so I’m marking this broken for now.
    meta.broken =
      (self.doCheck or false)
      || (
        (hasSystem self "cffi")
        && (!(final._lisp.name == "clisp" -> pkgs.stdenv.isLinux) || final._lisp.name == "abcl")
      );
  });

  cffi-grovel = cffi.overrideAttrs {
    name = "cffi-grovel";
    # cffi-grovel depends on cffi-toolchain. Just specifying it as an
    # exported system works because cffi-toolchain is specified in this
    # same source derivation.
    lispSystems = [
      "cffi"
      "cffi-grovel"
      "cffi-toolchain"
    ];
  };

  calispel = lispDerivation (self: {
    lispSystem = "calispel";
    src = sources.calispel;
    lispDependencies = [
      jpl-queues
      bordeaux-threads
    ]
    ++ lib.optionals (self.doCheck or false) [ eager-future2 ];
  });

  chipz = lispify "chipz" [ ];

  chunga = lispify "chunga" [ trivial-gray-streams ];

  coalton = lispDerivation (self: {
    lispSystem = "coalton";
    src = sources.coalton;
    lispDependencies =
      lib.optionals (hasSystem self "coalton") [
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
      ]
      ++
        lib.optionals
          (hasSystem self [
            "coalton-json"
            "quil-coalton"
            "small-coalton-programs"
            "thih-coalton"
          ])
          [
            coalton
            json-streams
          ]
      ++ lib.optionals (hasSystem self "coalton/benchmarks") [
        coalton
        trivial-benchmark
        yason
      ]
      ++ lib.optionals (hasSystem self "coalton/doc") [
        coalton
        html-entities
        yason
      ]
      ++ lib.optionals (self.doCheck or false) (
        lib.optionals (hasSystem self "coalton") [
          fiasco
          coalton-examples
        ]
        ++ lib.optionals (hasSystem self [
          "coalton-json"
          "quil-coalton"
          "small-coalton-programs"
          "thih-coalton"
        ]) [ fiasco ]
      );
    # Technically coalton is always a dependency so any derivation will always
    # include coalton so this could just hard-code the list, but I like to be
    # explicit about it for the sake of clarity.
    propagatedBuildInputs = lib.optionals (hasSystem self "coalton") [
      # Actual dependencies
      pkgs.mpfr
      pkgs.libuv
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
    # Broken since the last update and I can’t exactly figure out why.
    meta.broken = true;
  });

  coalton-examples = coalton.overrideAttrs {
    lispSystems = [
      "coalton-json"
      "quil-coalton"
      "small-coalton-programs"
      "thih-coalton"
    ];
  };

  coalton-benchmarks = coalton.overrideAttrs { lispSystems = [ "coalton/benchmarks" ]; };

  coalton-doc = coalton.overrideAttrs { lispSystems = [ "coalton/doc" ]; };

  circular-streams = lispDerivation (self: {
    lispSystem = "circular-streams";
    src = sources.circular-streams;
    lispDependencies = [
      fast-io
      trivial-gray-streams
    ]
    ++ lib.optionals (self.doCheck or false) [
      cl-test-more
      flexi-streams
    ];
  });

  cl-annot = lispDerivation (self: {
    lispSystem = "cl-annot";
    src = sources.cl-annot;
    lispDependencies = [ alexandria ] ++ lib.optionals (self.doCheck or false) [ cl-test-more ];
  });

  cl-ansi-text = lispDerivation (self: {
    lispSystem = "cl-ansi-text";
    src = sources.cl-ansi-text;
    lispDependencies = [
      alexandria
      cl-colors2
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  cl-async = lispDerivation (
    self:
    let
      baseSystems = [
        "cl-async"
        "cl-async-base"
        "cl-async-util"
      ];
    in
    rec {
      name = "cl-async";
      src = sources.cl-async;
      # ECL wants an archive file (.a) for every dependent /system/ (not just
      # source derivation) when it creates a binary for an application. Since
      # cl-async has this cl-async-base system internally, if it doesn’t exist
      # ECL will create a cl-async-base.a file at build time of a dependent
      # system, which obviously leads to a nix store read-only violation. What I
      # hate about this: it’s a violation of the entire cl-nix-lite premise of
      # “you don’t have to declare internal systems, just external ones”, only
      # for the sake of ECL. Am I going to have to do this for every package
      # now? I’m not looking forward to it. On the other hand: who cares? As
      # always, I’ll just fix it here for now and see where this takes me
      # further down the road. - hraban 2023-10
      lispSystems = baseSystems;
      lispDependencies =
        lib.optionals (hasSystem self baseSystems) [
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
        ]
        ++ lib.optionals (hasSystem self "cl-async-repl") [
          bordeaux-threads
          cl-async
        ]
        ++ lib.optionals (hasSystem self "cl-async-ssl") [
          cffi
          cl-async
          vom
        ];

      meta.broken = final._lisp.name == "clasp";
      propagatedBuildInputs = lib.optionals (hasSystem self "cl-async-ssl") [ pkgs.openssl ];
    }
  );

  cl-async-repl = cl-async.overrideAttrs { lispSystems = [ "cl-async-repl" ]; };

  cl-async-ssl = cl-async.overrideAttrs { lispSystems = [ "cl-async-ssl" ]; };

  cl-base64 = lispDerivation (self: {
    lispSystem = "cl-base64";
    version = "577683b18fd880b82274d99fc96a18a710e3987a";
    src = sources.cl-base64;
    lispDependencies = lib.optionals (self.doCheck or false) [
      ptester
      kmrcl
    ];
  });

  cl-change-case = lispDerivation (self: {
    lispSystem = "cl-change-case";
    src = sources.cl-change-case;
    lispDependencies = [
      cl-ppcre
      cl-ppcre-unicode
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  cl-colors = lispDerivation (self: {
    lispSystem = "cl-colors";
    lispDependencies = [
      alexandria
      let-plus
    ]
    ++ lib.optionals (self.doCheck or false) [ lift ];
    src = sources.cl-colors;
  });

  cl-colors2 = lispDerivation (self: {
    lispSystem = "cl-colors2";
    src = sources.cl-colors2;
    lispDependencies = [
      alexandria
      cl-ppcre
      parse-number
    ]
    ++ lib.optionals (self.doCheck or false) [ clunit2 ];
  });

  cl-containers = lispDerivation (
    self:
    let
      extendedSystems = [
        "cl-containers/with-moptilities"
        "cl-containers/with-utilities"
        "cl-containers/with-variates"
      ];
    in
    {
      lispSystem = "cl-containers";
      src = sources.cl-containers;
      lispDependencies =
        lib.optionals (hasSystem self "cl-containers") [ metatilities-base ]
        ++ lib.optionals (hasSystem self extendedSystems) [
          cl-containers
          # This is an infectious dependency which, if available on the search
          # path at all, will cause cl-containers to start compiling some extra
          # of its files. This must of course happen at build time of
          # cl-containers, otherwise it happens in the nix store which will
          # fail. So if if you are a dependent of cl-containers and you, or any
          # of your dependencies, depend on asdf-system-connections, you must
          # include this version of cl-containers lest you get a build error.
          asdf-system-connections
          moptilities
          metatilities-base
          cl-variates
        ]
        ++ lib.optionals ((self.doCheck or false) && (hasSystem self "cl-containers")) [ lift ];
      meta.broken = (self.doCheck or false) && (final._lisp.name == "abcl");
    }
  );

  "cl-containers/with-asdf-system-connections" = cl-containers.overrideAttrs {
    lispSystems = [
      "cl-containers/with-moptilities"
      "cl-containers/with-utilities"
      "cl-containers/with-variates"
    ];
  };

  cl-cookie = lispDerivation (self: {
    lispSystem = "cl-cookie";
    src = sources.cl-cookie;
    lispDependencies = [
      alexandria
      cl-ppcre
      proc-parse
      local-time
      quri
    ]
    ++ lib.optionals (self.doCheck or false) [ rove ];
  });

  cl-coveralls = lispDerivation (self: {
    lispSystem = "cl-coveralls";
    lispDependencies = [
      alexandria
      cl-ppcre
      dexador
      flexi-streams
      ironclad
      jonathan
      lquery
      split-sequence
    ]
    ++ lib.optionals (self.doCheck or false) [ prove ];
    src = sources.cl-coveralls;
  });

  cl-custom-hash-table = lispDerivation (self: {
    src = sources.cl-custom-hash-table;
    lispSystem = "cl-custom-hash-table";
    lispDependencies = lib.optionals (self.doCheck or false) [ hu_dwim_stefil ];
  });

  cl-csv = lispDerivation (self: {
    lispSystem = "cl-csv";
    src = sources.cl-csv;
    lispDependencies =
      lib.optionals (hasSystem self "cl-csv") [
        alexandria
        cl-interpol
        iterate
      ]
      ++ lib.optionals (hasSystem self "cl-csv-data-table") [ data-table ]
      ++ lib.optionals (self.doCheck or false) [ lisp-unit2 ];
    # The variable PARSING-1 is unbound.
    meta.broken = final._lisp.name == "clasp";
  });

  cl-csv-data-table = cl-csv.overrideAttrs {
    name = "cl-csv-data-table";
    lispSystems = [
      "cl-csv"
      "cl-csv-data-table"
    ];
  };

  # There is also a cl-csv-clsql but I don’t feel like adding clsql right now

  cl-difflib = lispify "cl-difflib" [ ];

  cl-dot = lispDerivation {
    lispSystem = "cl-dot";
    src = sources.cl-dot;
    propagatedBuildInputs = [ pkgs.graphviz ];
    # https://github.com/michaelw/cl-dot/issues/42
    meta.broken = final._lisp.name == "clisp";
  };

  cl-fad = lispDerivation (self: {
    lispSystem = "cl-fad";
    src = sources.cl-fad;
    lispDependencies = [
      alexandria
      bordeaux-threads
    ]
    ++ lib.optionals (self.doCheck or false) [
      cl-ppcre
      unit-test
    ];
  });

  cl-gopher = lispify "cl-gopher" [
    usocket
    flexi-streams
    drakma
    bordeaux-threads
    quri
  ];

  cl-html-diff = final.callPackage (
    { cl-difflib, lispDerivation }:
    lispDerivation {
      lispSystem = "cl-html-diff";
      lispDependencies = [ cl-difflib ];
      src = sources.cl-html-diff;
    }
  ) { };

  cl-interpol = lispDerivation (self: {
    lispSystem = "cl-interpol";
    src = sources.cl-interpol;
    lispDependencies = [
      cl-unicode
      named-readtables
    ]
    ++ lib.optionals (self.doCheck or false) [ flexi-streams ];
  });

  cl-isaac = lispDerivation (self: {
    lispSystem = "cl-isaac";
    src = sources.cl-isaac;
    lispDependencies = lib.optionals (self.doCheck or false) [
      parachute
      trivial-features
    ];
  });

  cl-js = lispDerivation {
    lispSystem = "cl-js";
    src = sources.js;
    lispDependencies = [
      parse-js
      cl-ppcre
    ];
  };

  cl-json = lispDerivation (self: {
    lispSystem = "cl-json";
    lispDependencies = lib.optionals (self.doCheck or false) [ fiveam ];
    src = sources.cl-json;
  });

  cl-libuv = lispDerivation rec {
    lispDependencies = [
      alexandria
      cffi
      cffi-grovel
    ];
    propagatedBuildInputs = [ pkgs.libuv ];
    lispSystem = "cl-libuv";
    src = sources.cl-libuv;
  };

  cl-libxml2 = lispDerivation (
    self:
    let
      baseSystems = [
        "cl-libxml2"
        "xfactory"
        "xoverlay"
      ];
    in
    {
      name = "cl-libxml2";
      src = sources.cl-libxml2;
      lispSystems = baseSystems;
      lispDependencies =
        lib.optionals (hasSystem self baseSystems) [
          iterate
          cffi
          puri
          flexi-streams
          alexandria
          garbage-pools
          metabang-bind
        ]
        ++ lib.optionals (hasSystem self "cl-libxslt") [ cl-libxml2 ]
        ++ lib.optionals ((self.doCheck or false) && (hasSystem self (baseSystems ++ [ "cl-libxslt" ]))) [
          lift
        ];
      makeFlags = [ "CC=cc" ];
      buildInputs =
        (lib.optionals (hasSystem self "cl-libxml2") [ pkgs.libxml2 ])
        ++ (lib.optionals (hasSystem self "cl-libxslt") [ pkgs.libxslt ]);
      outputs = [ "out" ] ++ lib.optionals (hasSystem self "cl-libxslt") [ "lib" ];
      # This :force t isn’t necessary, and it breaks tests
      postUnpack = ''
        (cd "$sourceRoot"; sed -i  -e "s/ :force t//" *.asd)
      '';
      meta.broken =
        (self.doCheck or false)
        && (hasSystem self [
          "cl-libxslt" # Broken since nixpkgs 91594d11a2248ebe00f45f6b9be63fe264bb74e1
          "cl-libxml2" # Broken since nixpkgs a5b2fe73740c3b1a1835bb1335d30b88c276924c
        ]);
      preBuild = lib.optionalString (hasSystem self "cl-libxslt") (
        let
          libname = "cllibxml2${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}";
        in
        ''
          LIBNAME=${libname} make -C foreign
          mkdir -p $lib
          cp -r foreign/${libname} $lib/
          # No need to special case this for Darwin (DYLD_..) because
          # we're using cffi which picks up LD_ on both Linux and
          # Darwin.
          addToSearchPath "LD_LIBRARY_PATH" "$lib"
        ''
      );
    }
  );

  # Defined as a separate Nix derivation because it has complicated and fragile
  # build steps, and as far as I can tell QL doesn’t even export this at
  # all. Consider this derivation experimental for now. It’d be nice if it
  # actually worked, of course.
  cl-libxslt = cl-libxml2.overrideAttrs (old: {
    name = "cl-libxslt";
    lispSystems = old.lispSystems ++ [ "cl-libxslt" ];
  });

  cl-locale = lispDerivation (self: {
    src = sources.cl-locale;
    lispDependencies = [
      anaphora
      arnesi
      cl-annot
      cl-syntax
      cl-syntax-annot
    ]
    ++ lib.optionals (self.doCheck or false) [
      flexi-streams
      prove
    ];
    lispSystem = "cl-locale";
  });

  cl-markdown = lispDerivation (self: {
    lispSystem = "cl-markdown";
    src = sources.cl-markdown;
    lispDependencies = [
      asdf-system-connections
      anaphora
      final."cl-containers/with-asdf-system-connections"
      cl-ppcre
      dynamic-classes
      metabang-bind
      metatilities-base
    ]
    ++ lib.optionals (self.doCheck or false) [
      lift
      trivial-shell
    ];
    meta.broken =
      # “There is no class named ABSTRACT-CONTAINER.”
      (final._lisp.name == "abcl")
      ||
        # > The function LIFT::GET-BACKTRACE-AS-STRING is undefined..
        ((self.doCheck or false) && (final._lisp.name == "ecl"));
  });

  cl-mimeparse = lispDerivation (self: {
    lispDependencies = [
      cl-ppcre
      parse-number
    ]
    ++ lib.optionals (self.doCheck or false) [ rt ];
    src = sources.cl-mimeparse;
    lispSystem = "cl-mimeparse";
  });

  cl-mock = lispDerivation (self: {
    src = sources.cl-mock;
    lispSystem = "cl-mock";
    lispDependencies = [
      alexandria
      bordeaux-threads
      closer-mop
      trivia
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  cl-octet-streams = lispDerivation (self: {
    src = sources.cl-octet-streams;
    lispSystem = "cl-octet-streams";
    lispDependencies = [ trivial-gray-streams ] ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  "cl+ssl" = lispDerivation (self: {
    lispSystem = "cl+ssl";
    src = sources.cl-plus-ssl;
    lispDependencies = [
      alexandria
      bordeaux-threads
      cffi
      flexi-streams
      trivial-features
      trivial-garbage
      trivial-gray-streams
      usocket
    ]
    ++ lib.optionals (self.doCheck or false) [
      bordeaux-threads
      cl-coveralls
      fiveam
      trivial-sockets
      usocket
    ];
    propagatedBuildInputs = [ pkgs.openssl ];
  });

  cl-ppcre = lispDerivation (self: {
    lispSystem = "cl-ppcre";
    src = sources.cl-ppcre;
    lispDependencies =
      lib.optionals (hasSystem self "cl-ppcre-unicode") [
        cl-ppcre
        cl-unicode
      ]
      ++ lib.optionals (self.doCheck or false) [ flexi-streams ];
  });

  cl-ppcre-unicode = cl-ppcre.overrideAttrs {
    name = "cl-ppcre-unicode";
    lispSystems = [
      "cl-ppcre"
      "cl-ppcre-unicode"
    ];
  };

  cl-prevalence = lispDerivation (self: {
    lispSystem = "cl-prevalence";
    src = sources.cl-prevalence;
    lispDependencies = [
      moptilities
      s-xml
      s-sysdeps
    ]
    ++ lib.optionals (self.doCheck or false) [
      fiveam
      find-port
    ];
    # Stateful in /tmp/ and crashes when different users run the tests
    meta.broken = self.doCheck or false;
  });

  cl-qrencode = lispDerivation (self: {
    lispSystem = "cl-qrencode";
    src = sources.cl-qrencode;
    lispDependencies = [ zpng ] ++ lib.optionals (self.doCheck or false) [ lisp-unit ];
  });

  cl-quickcheck = lispify "cl-quickcheck" [ ];

  cl-reactive = lispDerivation (self: {
    src = sources.cl-reactive;
    lispSystem = "cl-reactive";
    lispDependencies = [
      bordeaux-threads
      closer-mop
      trivial-garbage
      anaphora
    ]
    ++ lib.optionals (self.doCheck or false) [ nst ];
    meta.broken = builtins.elem final._lisp.name [
      # Attempt to define a subclass of built-in-class FUNCTION.
      "abcl"
      # Class #<BUILT-IN-CLASS FUNCTION> is not a valid superclass for #<FUNCALLABLE-STANDARD-CLASS
      "clasp"
      # Class #<The BUILT-IN-CLASS FUNCTION> is not a valid superclass for #<The CLOS:FUNCALLABLE-STANDARD-CLASS CL-REACTIVE::SIGNAL-FUNCTION>
      "ecl"
    ];
  });

  cl-redis = lispDerivation (self: {
    lispSystem = "cl-redis";
    lispDependencies = [
      babel
      cl-ppcre
      flexi-streams
      rutils
      usocket
    ]
    ++ lib.optionals (self.doCheck or false) [
      bordeaux-threads
      should-test
    ];
    src = sources.cl-redis;
    meta.broken = self.doCheck or false;
  });

  cl-slice = lispDerivation (self: {
    lispSystem = "cl-slice";
    src = sources.cl-slice;
    lispDependencies = [
      alexandria
      anaphora
      let-plus
    ]
    ++ lib.optionals (self.doCheck or false) [ clunit ];
  });

  cl-sqlite = lispDerivation (self: {
    src = sources.cl-sqlite;
    lispDependencies = [
      iterate
      cffi
    ]
    ++ lib.optionals (self.doCheck or false) [
      fiveam
      bordeaux-threads
    ];
    propagatedBuildInputs = [ pkgs.sqlite ];
    lispSystem = "sqlite";
  });

  cl-speedy-queue = lispify "cl-speedy-queue" [ ];

  cl-strings = lispDerivation (self: {
    lispSystem = "cl-strings";
    src = sources.cl-strings;
    lispDependencies = lib.optionals (self.doCheck or false) [ prove ];
  });

  cl-syntax = lispDerivation (self: {
    src = sources.cl-syntax;
    lispSystem = "cl-syntax";
    lispDependencies =
      lib.optionals (hasSystem self "cl-syntax") [
        named-readtables
        trivial-types
      ]
      ++ lib.optionals (hasSystem self "cl-syntax-annot") [ cl-annot ]
      ++ lib.optionals (hasSystem self "cl-syntax-interpol") [ cl-interpol ];
  });

  cl-syntax-annot = cl-syntax.overrideAttrs {
    lispSystems = [
      "cl-syntax"
      "cl-syntax-annot"
    ];
  };

  cl-syntax-interpol = cl-syntax.overrideAttrs {
    lispSystems = [
      "cl-syntax"
      "cl-syntax-interpol"
    ];
  };

  cl-test-more = prove;

  cl-tld = lispify "cl-tld" [ ];

  cl-tls = lispify "cl-tls" [
    ironclad
    alexandria
    fast-io
    cl-base64
  ];

  cl-unicode = lispDerivation {
    lispSystem = "cl-unicode";
    src = sources.cl-unicode;
    lispDependencies = [
      cl-ppcre
      flexi-streams
    ];
  };

  # The official location for this source is
  # "https://www.common-lisp.net/project/cl-utilities/cl-utilities-latest.tar.gz"
  # but I’m not a huge fan of including a "latest.tar.gz" in a Nix
  # derivation. That being said: it hasn’t been changed since 2006, so maybe
  # that is a better resource.
  cl-utilities = lispDerivation {
    lispSystem = "cl-utilities";
    src = sources.cl-utilities;
  };

  cl-variates = lispDerivation (self: {
    lispSystem = "cl-variates";
    src = sources.cl-variates;
    lispDependencies =
      lib.optionals (hasSystem self "cl-variates/with-metacopy") [
        cl-variates
        asdf-system-connections
        metacopy
      ]
      ++ lib.optionals ((self.doCheck or false) && (hasSystem self "cl-variates")) [ lift ];
    meta.broken =
      (hasSystem self "cl-variates/with-metacopy")
      && (builtins.elem final._lisp.name [
        # The function get-structure is not yet implemented for Armed Bear Common Lisp 1.9.2 on AARCH64.
        "abcl"
        # The function get-structure is not yet implemented for clasp cclasp-boehmprecise-2.7.0-cst on x86_64.
        "clasp"
        # *** - The function get-structure is not yet implemented for CLISP 2.49.92
        "clisp"
        # ;;; The function get-structure is not yet implemented for ECL 21.2.1 on arm64.
        "ecl"
      ]);
  });

  "cl-variates/with-metacopy" = cl-variates.overrideAttrs {
    lispSystems = [ "cl-variates/with-metacopy" ];
  };

  cl-who = lispDerivation (self: {
    lispSystem = "cl-who";
    src = sources.cl-who;
    lispDependencies = lib.optionals (self.doCheck or false) [ flexi-streams ];
  });

  clack = lispDerivation (self: {
    src = sources.clack;
    lispSystem = "clack";
    # TODO: This is a complex package with lots of derivations and check
    # dependencies. Fill in as necessary. I’ve only filled in what I need
    # right now.
    lispDependencies =
      lib.optionals (hasSystem self "clack") [
        alexandria
        bordeaux-threads
        lack
        swank
        usocket
      ]
      ++ lib.optionals (hasSystem self "clack-handler-hunchentoot") [
        alexandria
        bordeaux-threads
        flexi-streams
        hunchentoot
        split-sequence
      ]
      ++ lib.optionals (hasSystem self "clack-test") [
        bordeaux-threads
        dexador
        flexi-streams
        http-body
        ironclad
        rove
      ]
      ++ lib.optionals ((self.doCheck or false) && (hasSystem self "clack-handler-hunchentoot")) [
        clack-test
      ];
  });

  clack-handler-hunchentoot = clack.overrideAttrs {
    name = "clack-handler-hunchentoot";
    lispSystems = [
      "clack-handler-hunchentoot"
      "clack-socket"
    ];
  };

  clack-socket = clack.overrideAttrs { lispSystems = [ "clack-socket" ]; };

  clack-test = clack.overrideAttrs {
    name = "clack-test";
    lispSystems = [
      "clack"
      "clack-handler-hunchentoot"
      "clack-test"
    ];
  };

  closer-mop = lispify "closer-mop" [ ];

  clss = lispify "clss" [
    array-utils
    plump
  ];

  clunit = lispify "clunit" [ ];

  clunit2 = lispify "clunit2" [ ];

  collectors = lispDerivation (self: {
    lispSystem = "collectors";
    lispDependencies = [
      alexandria
      closer-mop
      symbol-munger
    ]
    ++ lib.optionals (self.doCheck or false) [ lisp-unit2 ];
    src = sources.collectors;
    # The variable MAKE-REDUCER-TEST is unbound.
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  colorize = lispify "colorize" [
    alexandria
    html-encode
    split-sequence
  ];

  common-doc = lispDerivation (self: {
    src = sources.common-doc;
    name = "common-doc";
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
    ]
    ++ lib.optionals (self.doCheck or false) [
      cl-ppcre
      fiveam
    ];
  });

  common-html = lispDerivation (self: {
    src = sources.common-html;
    lispSystem = "common-html";
    lispDependencies = [
      common-doc
      plump
      anaphora
      alexandria
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  commondoc-markdown = lispDerivation (self: {
    lispSystem = "commondoc-markdown";
    src = sources.commondoc-markdown;
    lispDependencies = [
      final."3bmd"
      final."3bmd-ext-code-blocks"
      final."3bmd-ext-tables"
      common-doc
      common-html
      str
      ironclad
      f-underscore
    ]
    ++ lib.optionals (self.doCheck or false) [
      hamcrest
      rove
    ];
    # I have no idea what’s happening here but I need to move on
    meta.broken = self.doCheck or false;
  });

  computable-reals = lispDerivation {
    lispSystem = "computable-reals";
    src = sources.computable-reals;
  };

  concrete-syntax-tree = lispDerivation (self: {
    lispDependencies = [ acclimation ] ++ lib.optionals (self.doCheck or false) [ fiveam ];
    src = sources.concrete-syntax-tree;
    lispSystem = "concrete-syntax-tree";
    lispAsdPath = [ "Lambda-list" ];
    preBuild = ''
      echo '(:source-registry-cache ' > .cl-source-registry.cache
      find . -name '*.asd' -exec printf '"%s" ' {} \; >> .cl-source-registry.cache
      echo ')' >> .cl-source-registry.cache
    '';
    # These checks take too long on any reasonable machine.
    meta.broken = self.doCheck or false;
  });

  contextl = lispDerivation {
    lispDependencies = [
      closer-mop
      lw-compat
    ];
    src = sources.contextl;
    lispSystems = [
      "contextl"

      # These two packages have clashing symbol exports, they can’t be loaded in
      # the same image. That’s fair, but lispDerivation doesn’t currently
      # support that, so I need to figure out whether I want to support that,
      # or, if not, how to allow packages like this to work around it. I guess
      # using overrides?
      # "dynamic-wind"
    ];
    # The variable =LAYERED-FUNCTION-DEFINER-FOR-ADJOIN-LAYER-USING-CLASS= is unbound.
    meta.broken = final._lisp.name == "clasp";
  };

  data-lens = lispDerivation (self: {
    lispDependencies = [
      cl-ppcre
      alexandria
      serapeum
    ]
    ++ lib.optionals (self.doCheck or false) [
      fiveam
      string-case
    ];
    lispSystems = [
      "data-lens"
      "data-lens/beta/transducers"
    ];
    src = sources.data-lens;
    meta.broken = (self.doCheck or false) && (final._lisp.name == "ecl");
  });

  data-table = lispDerivation (self: {
    # There is also data-table-clsql but I don’t feel like adding clsql right
    # now
    lispSystem = "data-table";
    src = sources.data-table;
    lispDependencies = [
      alexandria
      cl-interpol
      iterate
      symbol-munger
    ]
    ++ lib.optionals (self.doCheck or false) [ lisp-unit2 ];
    meta.broken =
      # * Wrong number of arguments for function COLUMN-TYPEAn error occurred during initialization:
      final._lisp.name == "ecl"
      # The variable DATA-TABLE-TYPES is unbound.
      || ((self.doCheck or false) && final._lisp.name == "clasp");
  });

  dbi = lispDerivation (self: {
    lispSystem = "dbi";
    src = sources.cl-dbi;
    lispDependencies = [
      cl-ppcre
      bordeaux-threads
      split-sequence
      closer-mop
    ]
    ++ lib.optionals (self.doCheck or false) [
      alexandria
      cl-sqlite
      rove
      trivial-types
    ];
    # depends on mysql, which isn’t available in cl-nix-lite
    meta.broken = self.doCheck or false;
  });

  deflate = lispDerivation (self: {
    lispSystem = "deflate";
    src = sources.deflate;
    # The symbol STREAM-ELEMENT-TYPE is bound to an ordinary function and is not a valid name for a generic function
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  dexador = lispDerivation (self: {
    lispSystem = "dexador";
    src = sources.dexador;
    lispDependencies = [
      alexandria
      babel
      bordeaux-threads
      chipz
      chunga
      cl-base64
      cl-cookie
      final."cl+ssl"
      cl-ppcre
      fast-http
      fast-io
      quri
      trivial-garbage
      trivial-gray-streams
      trivial-mimes
      usocket
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isWindows [ flexi-streams ]
    ++ lib.optionals (self.doCheck or false) [
      babel
      cl-cookie
      clack-test
      lack
      rove
    ];
  });

  dissect = lispDerivation {
    lispSystem = "dissect";
    src = sources.dissect;
    lispDependencies = lib.optionals (final._lisp.name == "clisp") [ cl-ppcre ];
  };

  djula = lispDerivation (self: {
    lispSystem = "djula";
    src = sources.djula;
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
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
    # ARGS is not of type LIST.
    meta.broken = final._lisp.name == "clasp";
  });

  dns-client = lispify "dns-client" [
    punycode
    usocket
    documentation-utils
  ];

  # Technically these could be two separate derivations, one per system, but it
  # doesn’t seem like people use it that way, and there’s no dependencies
  # anyway, so there’s little benefit. Just treat this as a monolith package.
  docs-builder = lispDerivation {
    lispSystems = [
      "docs-builder"
      "docs-config"
    ];
    src = sources.docs-builder;
    lispDependencies = [
      log4cl
      final."40ants-doc"
    ];
    # Requires a modern version of ASDF
    meta.broken = final._lisp.name == "ecl";
  };

  documentation-utils = lispDerivation {
    lispSystem = "documentation-utils";
    src = sources.documentation-utils;
    lispDependencies = [ trivial-indent ];
  };

  drakma = lispDerivation (self: {
    lispSystem = "drakma";
    src = sources.drakma;
    lispDependencies = [
      chipz
      chunga
      cl-base64
      final."cl+ssl"
      cl-ppcre
      flexi-streams
      puri
      usocket
    ]
    ++ lib.optionals (self.doCheck or false) [
      easy-routes
      fiveam
      hunchentoot
    ];
    # Running test GET-GOOGLE Condition of type: TRY-AGAIN-ERROR
    #
    # Not sure why this isn’t failing on other lisps... shouldn’t nix sandboxing
    # break this test?
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  dref = lispDerivation (self: {
    src = sources.dref;
    lispSystems = [
      "dref"
    ]
    ++ lib.optionals (self.doCheck or false) [
      "dref/full"
      "dref-test"
    ];
    lispDependencies = [
      autoload
      mgl-pax-bootstrap
      named-readtables
      pythonic-string-reader
    ]
    ++ lib.optionals (hasSystem self "dref/full") (
      [
        alexandria
        closer-mop
        mgl-pax
      ]
      ++ lib.optionals (final._lisp.name != "sbcl") [ swank ]
    )
    ++ lib.optionals (hasSystem self "dref-test") [
      try
      final."mgl-pax/full"
      swank
    ];
    meta.broken = self.doCheck or false;
  });

  "dref/full" = dref.overrideAttrs {
    lispSystems = [
      "dref"
      "dref/full"
    ];
  };

  dref-test = dref.overrideAttrs {
    lispSystems = [
      "dref"
      "dref-test"
    ];
  };

  dynamic-classes = lispDerivation (self: {
    lispSystem = "dynamic-classes";
    src = sources.dynamic-classes;
    lispDependencies = [ metatilities-base ] ++ lib.optionals (self.doCheck or false) [ lift ];
    meta.broken = self.doCheck or false;
  });

  eager-future2 = lispDerivation {
    lispSystem = "eager-future2";
    lispDependencies = [
      bordeaux-threads
      trivial-garbage
    ];
    src = sources.eager-future2;
    # Very specific deadlock: ECL & x86 & Macos, since ECL 21.2.1 -> 23.9.9
    # got merged: https://github.com/NixOS/nixpkgs/pull/276506
    # No idea what’s wrong here, or even who’s wrong: ECL? eager-future2?
    # Update: now also broken on aarch64-darwin, not sure why or since when.
    meta.broken = final._lisp.name == "ecl" && pkgs.stdenv.isDarwin;
  };

  easy-routes = lispDerivation (self: {
    src = sources.easy-routes;
    lispSystem = "easy-routes";
    lispDependencies =
      lib.optionals (hasSystem self "easy-routes") [
        hunchentoot
        routes
      ]
      ++ lib.optionals (hasSystem self "easy-routes+errors") [ hunchentoot-errors ]
      ++ lib.optionals (hasSystem self "easy-routes+djula") [ djula ];
  });

  "easy-routes+errors" = easy-routes.overrideAttrs {
    lispSystems = [
      "easy-routes"
      "easy-routes+errors"
    ];
  };

  "easy-routes+djula" = easy-routes.overrideAttrs {
    lispSystems = [
      "easy-routes"
      "easy-routes+djula"
    ];
  };

  eclector = lispDerivation (self: {
    lispSystem = "eclector";
    src = sources.eclector;
    lispDependencies =
      lib.optionals (hasSystem self "eclector") [
        alexandria
        closer-mop
        acclimation
      ]
      ++ lib.optionals (hasSystem self "eclector-concrete-syntax-tree") [ concrete-syntax-tree ]
      ++ lib.optionals (self.doCheck or false) [
        alexandria
        fiveam
      ];
    # This directory is unneeded and it messes up some shebang filtering
    # autodetectiong stuff on linux builds.
    preBuild = "rm -rf tools-for-build";
  });

  eclector-concrete-syntax-tree = eclector.overrideAttrs {
    lispSystems = [
      "eclector"
      "eclector-concrete-syntax-tree"
    ];
    name = "eclector-concrete-syntax-tree";
  };

  enchant = lispDerivation {
    lispDependencies = [ cffi ];
    lispSystem = "enchant";
    propagatedBuildInputs = [ pkgs.enchant ];
    src = sources.enchant;
  };

  eos = lispify "eos" [ ];

  esrap = lispDerivation (self: {
    lispSystem = "esrap";
    src = sources.esrap;
    lispDependencies = [
      alexandria
      trivial-with-current-source-form
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  event-emitter = lispDerivation (self: {
    lispSystem = "event-emitter";
    src = sources.event-emitter;
    lispDependencies = lib.optionals (self.doCheck or false) [ prove ];
    # This fails on Github Actions, not in my local VM:
    # *** - handle_fault error2 ! address = 0x1fffffd6e640 not in [0x1000000c0000,0x10000058dd90) !
    # SIGSEGV cannot be cured. Fault address = 0x1fffffd6e640.
    meta.broken =
      (self.doCheck or false) && (final._lisp.name == "clisp") && pkgs.stdenv.hostPlatform.isLinux;
  });

  f-underscore = lispify "f-underscore" [ ];

  fare-memoization = lispDerivation (self: {
    lispSystem = "fare-memoization";
    src = sources.fare-memoization;
    lispDependencies = lib.optionals (self.doCheck or false) [ hu_dwim_stefil ];
  });

  fare-mop = lispify "fare-mop" [
    closer-mop
    fare-utils
  ];

  fare-quasiquote = lispDerivation (self: {
    src = sources.fare-quasiquote;
    lispSystem = "fare-quasiquote";
    lispDependencies =
      lib.optionals (hasSystem self "fare-quasiquote") [ fare-utils ]
      ++ lib.optionals (hasSystem self "fare-quasiquote-optima") [ final."trivia.quasiquote" ]
      ++ lib.optionals (hasSystem self "fare-quasiquote-readtable") [ named-readtables ]
      ++ lib.optionals (self.doCheck or false) [
        fare-quasiquote-extras
        hu_dwim_stefil
        optima
      ];
  });

  fare-quasiquote-extras = fare-quasiquote.overrideAttrs {
    name = "fare-quasiquote-extras";
    lispSystems = [
      "fare-quasiquote"
      "fare-quasiquote-optima"
      "fare-quasiquote-readtable"
    ];
  };

  fare-quasiquote-optima = fare-quasiquote.overrideAttrs {
    name = "fare-quasiquote-optima";
    lispSystems = [
      "fare-quasiquote"
      "fare-quasiquote-optima"
    ];
  };

  fare-quasiquote-readtable = fare-quasiquote.overrideAttrs {
    name = "fare-quasiquote-readtable";
    lispSystems = [
      "fare-quasiquote"
      "fare-quasiquote-readtable"
    ];
  };

  fare-utils = lispDerivation (self: {
    lispSystem = "fare-utils";
    src = sources.fare-utils;
    lispDependencies = lib.optionals (self.doCheck or false) [ hu_dwim_stefil ];
    # "https://gitlab.common-lisp.net/frideau/fare-utils/-/issues/1".  Getting
    # the version here from the derivation is very ugly and I hate it but is
    # there a better way?
    meta.broken = final._lisp.name == "sbcl" && (lib.getVersion final._lisp.deriv) == "2.4.4";
  });

  fast-http = lispDerivation (self: {
    src = sources.fast-http;
    lispSystem = "fast-http";
    lispDependencies = [
      alexandria
      babel
      cl-utilities
      log4cl
      proc-parse
      smart-buffer
      xsubseq
    ]
    ++ lib.optionals (self.doCheck or false) [
      babel
      cl-syntax-interpol
      prove
      xsubseq
    ];
    # lisp_instance_class for called on #<UNBOUND>
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  fast-io = lispify "fast-io" [
    alexandria
    static-vectors
    trivial-gray-streams
  ];

  fast-websocket = lispDerivation (self: {
    lispSystem = "fast-websocket";
    src = sources.fast-websocket;
    lispDependencies = [
      fast-io
      babel
      alexandria
    ]
    ++ lib.optionals (self.doCheck or false) [
      prove
      trivial-utf-8
    ];
  });

  infix = lispDerivation (self: {
    src = sources.femlisp;
    lispSystem = "infix";
    dontConfigure = true;
    lispAsdPath = lib.optionals (hasSystem self "infix") [ "external/infix" ];
  });

  fiasco = lispify "fiasco" [
    alexandria
    trivial-gray-streams
  ];

  find-port = lispDerivation (self: {
    lispSystem = "find-port";
    lispDependencies = [ usocket ] ++ lib.optionals (self.doCheck or false) [ fiveam ];
    src = sources.find-port;
    # Works locally but broken on Github Actions I don’t know why:
    #
    # Running test FIND-PORTS XThe following check failed: ((FIND-PORT:FIND-PORT))
    meta.broken =
      (self.doCheck or false) && (final._lisp.name == "abcl") && pkgs.stdenv.hostPlatform.isDarwin;
  });

  fiveam = lispify "fiveam" [
    alexandria
    asdf-flv
    trivial-backtrace
  ];

  float-features = lispDerivation (self: {
    lispSystem = "float-features";
    src = sources.float-features;
    lispDependencies = [
      documentation-utils
      trivial-features
    ]
    ++ lib.optionals (self.doCheck or false) [ parachute ];
    # *** - APPLY: too few arguments given to FIND
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clisp");
  });

  flexi-streams = lispDerivation (self: {
    lispSystem = "flexi-streams";
    src = sources.flexi-streams;
    lispDependencies = [ trivial-gray-streams ];
    # Stateful in /tmp/, conflicts when tests are run by different users
    meta.broken = self.doCheck or false;
  });

  form-fiddle = lispDerivation {
    lispSystem = "form-fiddle";
    src = sources.form-fiddle;
    lispDependencies = [ documentation-utils ];
  };

  fset = lispDerivation (self: {
    lispDependencies = [
      misc-extensions
      mt19937
      named-readtables
    ];
    src = sources.fset;
    lispSystem = "fset";
    meta.broken = builtins.elem final._lisp.name [
      # The value FSET::IDENTITY-ORDERING-MIXIN-NEXT-SERIAL-NUMBER is not of type LIST.
      "abcl"
      # *** - CAR: IDENTITY-ORDERING-MIXIN-NEXT-SERIAL-NUMBER is not a list
      "clisp"
      #   * The macro form (INCREMENT-ATOMIC-SERIES IDENTITY-ORDERING-MIXIN-NEXT-SERIAL-NUMBER) was not expanded successfully.
      # Error detected:
      # In function CAR, the value of the first argument is
      #   IDENTITY-ORDERING-MIXIN-NEXT-SERIAL-NUMBER
      # which is not of the expected type LIST
      "ecl"
    ];
  });

  function-cache = lispDerivation (self: {
    lispSystem = "function-cache";
    src = sources.function-cache;
    lispDependencies = [
      alexandria
      cl-interpol
      iterate
      symbol-munger
      closer-mop
    ]
    ++ lib.optionals (self.doCheck or false) [ lisp-unit2 ];

    meta.broken =
      # Supported lisps: sbcl clozure
      final._lisp.name != "sbcl" && final._lisp.name != "ccl";

  });

  garbage-pools = lispDerivation (self: {
    lispSystem = "garbage-pools";
    src = sources.garbage-pools;
    lispDependencies = lib.optionals (self.doCheck or false) [ lift ];
  });

  gettext = lispDerivation (self: {
    lispSystem = "gettext";
    src = sources.gettext;
    lispDependencies = [
      split-sequence
      yacc
      flexi-streams
    ]
    ++ lib.optionals (self.doCheck or false) [ stefil ];
    preCheck = ''
      export CL_SOURCE_REGISTRY="$PWD/gettext-tests:$CL_SOURCE_REGISTRY"
    '';
  });

  global-vars = lispify "global-vars" [ ];

  hamcrest = lispDerivation (self: {
    src = sources.hamcrest;
    lispSystem = "hamcrest";
    lispDependencies = [
      final."40ants-asdf-system"
      alexandria
      iterate
      cl-ppcre
      split-sequence
    ]
    ++ lib.optionals (hasSystem self "hamcrest/rove") [ rove ]
    ++ lib.optionals (self.doCheck or false) [
      prove
      rove
    ];
  });

  "hamcrest/rove" = hamcrest.overrideAttrs {
    name = "hamcrest/rove";
    lispSystems = [
      "hamcrest"
      # I’m not 100% on how this system is exported exactly, but it is,
      # somehow. Apparently ASDFv3 automatically recognizes this? Reblocks seems
      # to use it.
      "hamcrest/rove"
    ];
  };

  history-tree = lispDerivation (self: {
    lispDependencies = [
      alexandria
      cl-custom-hash-table
      local-time
      nclasses
      trivial-package-local-nicknames
    ]
    ++ lib.optionals (self.doCheck or false) [ lisp-unit2 ];
    src = sources.history-tree;
    lispSystem = "history-tree";
    meta.broken =
      # *** - EVAL: undefined function EXT::ADD-PACKAGE-LOCAL-NICKNAME
      (final._lisp.name == "clisp")
      ||
        # The variable SINGLE-ENTRY is unbound.
        ((self.doCheck or false) && (final._lisp.name == "clasp"));
  });

  http-body = lispDerivation (self: {
    lispSystem = "http-body";
    src = sources.http-body;
    lispDependencies = [
      babel
      cl-ppcre
      cl-utilities
      fast-http
      flexi-streams
      jonathan
      quri
      trivial-gray-streams
    ]
    ++ lib.optionals (self.doCheck or false) [
      assoc-utils
      cl-ppcre
      flexi-streams
      prove
      trivial-utf-8
    ];
    # Condition of type: SIMPLE-PROGRAM-ERROR: lisp_instance_class for called on #<UNBOUND>
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  html-encode = lispify "html-encode" [ ];

  html-entities = lispDerivation (self: {
    lispSystem = "html-entities";
    src = sources.html-entities;
    lispDependencies = [ cl-ppcre ] ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  hu_dwim_asdf = lispDerivation {
    lispSystem = "hu.dwim.asdf";
    src = sources.hu_dwim_asdf;
  };

  hu_dwim_stefil = lispDerivation {
    lispSystem = "hu.dwim.stefil";
    src = sources.hu_dwim_stefil;
    lispDependencies = [
      alexandria
      hu_dwim_asdf
    ];
  };

  hunchentoot = lispDerivation (self: {
    lispSystem = "hunchentoot";
    src = sources.hunchentoot;
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
      final."cl+ssl"
      usocket
      bordeaux-threads
    ]
    ++ lib.optionals (self.doCheck or false) [
      cl-ppcre
      cl-who
      drakma
    ];
    # https://github.com/edicl/hunchentoot/issues/217
    meta.broken = self.doCheck or false;
  });

  hunchentoot-errors = lispify "hunchentoot-errors" [
    cl-mimeparse
    hunchentoot
    parse-number
    string-case
  ];

  idna = lispify "idna" [ split-sequence ];

  ieee-floats = lispDerivation (self: {
    lispSystem = "ieee-floats";
    src = sources.ieee-floats;
    lispDependencies = lib.optionals (self.doCheck or false) [ fiveam ];
    # SYSTEM::LPAR-READER: floating point underflow
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clisp");
  });

  in-nomine = lispDerivation (self: {
    lispSystem = "in-nomine";
    lispDependencies = [
      alexandria
      trivial-arguments
    ]
    ++ lib.optionals (self.doCheck or false) [
      alexandria
      closer-mop
      fiveam
      introspect-environment
      lisp-namespace
    ];
    src = sources.in-nomine;
    # Uses :local-nickname in defpackage. Ah, the state of CLISP...
    # https://gitlab.com/gnu-clisp/clisp/-/merge_requests/3
    meta.broken = final._lisp.name == "clisp";
  });

  inferior-shell = lispDerivation (self: {
    lispSystem = "inferior-shell";
    lispDependencies = [
      alexandria
      fare-utils
      fare-quasiquote-extras
      fare-mop
      trivia
      final."trivia.quasiquote"
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
    src = sources.inferior-shell;
  });

  infix-math = lispify "infix-math" [
    alexandria
    serapeum
    wu-decimal
    parse-number
  ];

  introspect-environment = lispDerivation (self: {
    lispSystem = "introspect-environment";
    lispDependencies = lib.optionals (self.doCheck or false) [ fiveam ];
    src = sources.introspect-environment;
    # The slot CLEAVIR-ENVIRONMENT::%TYPE in the object
    # #<CLEAVIR-ENVIRONMENT:LEXICAL-VARIABLE-INFO @0xffffc851ff99> is unbound.
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  ironclad = lispDerivation (self: {
    lispSystem = "ironclad";
    src = sources.ironclad;
    lispDependencies = [ bordeaux-threads ] ++ lib.optionals (self.doCheck or false) [ rt ];
    env = lib.optionalAttrs (final._lisp.name == "sbcl") { NIX_SBCL_DYNAMIC_SPACE_SIZE = "2gb"; };
    # 50 out of 470 total tests failed
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  iterate = lispDerivation (self: {
    lispSystem = "iterate";
    src = sources.iterate;
    lispDependencies = lib.optionals ((self.doCheck or false) && (final._lisp.name != "sbcl")) [ rt ];
  });

  jonathan = lispDerivation (self: {
    lispSystem = "jonathan";
    src = sources.jonathan;
    lispDependencies = [
      babel
      cl-annot
      cl-ppcre
      cl-syntax
      cl-syntax-annot
      fast-io
      proc-parse
      trivial-types
    ]
    ++ lib.optionals (self.doCheck or false) [
      prove
      legion
    ];
  });

  jpl-queues = lispDerivation {
    lispSystem = "jpl-queues";
    lispDependencies = [
      bordeaux-threads
      jpl-util
    ];
    pname = "jpl-queues";
    src = sources.jpl-queues;
  };

  jpl-util = lispDerivation {
    src = sources.jpl-util;
    lispSystem = "jpl-util";
  };

  json-streams = lispDerivation (self: {
    src = sources.json-streams;
    lispSystem = "json-streams";
    lispDependencies = lib.optionals (self.doCheck or false) [
      cl-quickcheck
      flexi-streams
    ];
  });

  jzon = lispDerivation (self: {
    src = sources.jzon;
    lispSystem = "com.inuoe.jzon";
    lispDependencies = [
      closer-mop
      flexi-streams
      trivial-gray-streams
    ]
    ++ lib.optionals (final._lisp.name != "ecl") [ float-features ]
    ++ lib.optionals (self.doCheck or false) [
      alexandria
      fiveam
    ];
    lispAsdPath = [
      "src"
      "test"
    ];
  });

  kmrcl = lispDerivation (self: {
    lispSystem = "kmrcl";
    version = "4a27407aad9deb607ffb8847630cde3d041ea25a";
    src = sources.kmrcl;
    lispDependencies = lib.optionals (self.doCheck or false) [ rt ];
    meta.broken =
      # > The symbol "MAKE-THREAD-LOCK" was not found in package EXT.
      (final._lisp.name == "abcl")
      ||
        # odd floating point error on clisp
        ((self.doCheck or false) && (final._lisp.name == "clisp"));
  });

  # I can’t be bothered sorting out this dependency jungle
  lack = lispDerivation (self: {
    name = "lack";
    src = sources.lack;
    # Kitchen sink dependencies. In an ideal world this would be unnecessary:
    # every individual lack system would be listed explicitly in Nix, with its
    # dependencies. I just can’t be bothered to do that right now.
    lispDependencies = [
      anypool
      babel
      circular-streams
      cl-base64
      cl-cookie
      cl-ppcre
      cl-redis
      dbi
      http-body
      ironclad
      local-time
      marshal
      quri
      salza2
      trivial-mimes
      trivial-rfc-1123
      trivial-utf-8
      zstd
    ];
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
      "lack-middleware-deflater"
      "lack/middleware/mount"
      "lack-middleware-mount"
      "lack/middleware/session"
      "lack-middleware-session"
      "lack/middleware/static"
      "lack-middleware-static"
      "lack-middleware-when"
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
    # broken test configuration in asdf declarations
    meta.broken = self.doCheck or false;
  });

  lass = lispDerivation {
    lispSystems = [
      "lass"
      "lass-binary"
    ];
    lispDependencies = [
      trivial-indent
      trivial-mimes
      cl-base64
    ];
    src = sources.lass;
    # This is kind of ridiculous, but there’s a file here called asdf.lisp
    # which trips up clisp: ‘(require "asdf")’ loads that file, rather than
    # actual asdf. Who’s at fault here?
    meta.broken = final._lisp.name == "clisp";
  };

  legion = lispDerivation (self: {
    lispSystem = "legion";
    src = sources.legion;
    lispDependencies = [
      vom
      # Not listed in the .asd but these are required
      bordeaux-threads
      cl-speedy-queue
    ]
    ++ lib.optionals (self.doCheck or false) [
      local-time
      prove
    ];
    # hangs forever on ECL
    meta.broken = (self.doCheck or false) && (final._lisp.name == "ecl");
  });

  let-plus = lispDerivation (self: {
    lispSystem = "let-plus";
    lispDependencies = [
      alexandria
      anaphora
    ]
    ++ lib.optionals (self.doCheck or false) [ lift ];
    src = sources.let-plus;
  });

  lift = lispDerivation (self: {
    lispSystem = "lift";
    src = sources.lift;
    meta.broken =
      (builtins.elem final._lisp.name [
        # Symbol named "BTCL" not found in the CORE package.
        "clasp"
        # There is a bug in lift which causes some silly pathname, ‘mkdir
        # -p’ style problem. Setting the broken flag here is the easiest
        # way to disable all lift tests on clisp for now.  The bug looks
        # like this:
        #
        #  > *** - PROBE-FILE: No file name given:
        #  >       #P"/private/tmp/nix-build-system-metatilities-base.drv-1/source/test-results-2023-10-16-1/
        "clisp"
      ])
      || (self.doCheck or false);
  });

  lisp-namespace = lispDerivation (self: {
    lispSystem = "lisp-namespace";
    lispDependencies = [ alexandria ] ++ lib.optionals (self.doCheck or false) [ fiveam ];
    src = sources.lisp-namespace;
  });

  lisp-unit = lispify "lisp-unit" [ ];

  lisp-unit2 = lispDerivation (self: {
    lispSystem = "lisp-unit2";
    src = sources.lisp-unit2;
    lispDependencies = [
      alexandria
      cl-interpol
      iterate
      symbol-munger
    ];
    # The variable COLLECT/DECOLLECT is unbound.
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  lml2 = lispDerivation (self: {
    lispDependencies = [ kmrcl ] ++ lib.optionals (self.doCheck or false) [ rt ];
    lispSystem = "lml2";
    src = sources.lml2;
  });

  local-time = lispDerivation (self: {
    lispSystem = "local-time";
    src = sources.local-time;
    lispDependencies = lib.optionals (self.doCheck or false) [ fiasco ];
    meta.broken =
      (self.doCheck or false)
      && (
        (final._lisp.name == "abcl")
        ||
          # *** - Invalid pathname designator T
          (final._lisp.name == "clisp")
      );
  });

  log4cl = lispDerivation (self: {
    lispSystem = "log4cl";
    src = sources.log4cl;
    lispDependencies = [ bordeaux-threads ] ++ lib.optionals (self.doCheck or false) [ stefil ];
    meta.broken = self.doCheck or false;
  });

  log4cl-extras = lispDerivation (self: {
    lispSystem = "log4cl-extras";
    lispDependencies = [
      final."40ants-doc"
      final."40ants-asdf-system"
      alexandria
      cl-strings
      dissect
      global-vars
      jonathan
      log4cl
      named-readtables
      pythonic-string-reader
      with-output-to-stream
    ]
    ++ lib.optionals (self.doCheck or false) [ hamcrest ];
    src = sources.log4cl-extras;
    meta.broken = self.doCheck or false;
  });

  # Technically this package also contains a benchmark system with different
  # dependencies but I’m not going to bother exposing that to this scope.
  lparallel = (
    let
      # Please don’t use this anywhere else
      bordeaux-threads-v1 = bordeaux-threads.overrideAttrs (_: {
        src = sources.bordeaux-threads-v1;
      });
    in
    lispDerivation (self: {
      lispSystem = "lparallel";
      src = sources.lparallel;
      lispDependencies = [
        alexandria
        # If anyone else in your entire family includes
        # bordeaux-threads-master, you’re dead.
        bordeaux-threads-v1
      ];
      meta.broken =
        (self.doCheck or false)
        && (
          # When calling (COMMON-LISP::FLET CORE::TRANSFORM-KEYWORDS) with the lambda-list (COMMON-LISP::&KEY CORE::REPORT CORE::INTERACTIVE CORE::TEST) the bad keyword argument :HANDLED was passed
          (final._lisp.name == "clasp")
          # ;;; Unknown keyword :HANDLED
          || ((final._lisp.name == "ecl") && pkgs.stdenv.isLinux)
          || pkgs.stdenv.hostPlatform.isDarwin
        );
    })
  );

  lquery = lispDerivation (self: {
    lispSystem = "lquery";
    src = sources.lquery;
    lispDependencies = [
      array-utils
      form-fiddle
      plump
      clss
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  lw-compat = lispify "lw-compat" [ ];

  map-set = lispify "map-set" [ ];

  marshal = lispDerivation (self: {
    lispSystem = "marshal";
    lispDependencies = lib.optionals (self.doCheck or false) [ xlunit ];
    src = sources.marshal;
  });

  md5 = lispify "md5" [ flexi-streams ];

  metabang-bind = lispDerivation (self: {
    lispSystem = "metabang-bind";
    src = sources.metabang-bind;
    lispDependencies = lib.optionals (self.doCheck or false) [ lift ];
  });

  metacopy = lispDerivation (self: {
    lispSystem = "metacopy";
    src = sources.metacopy;
    lispDependencies =
      lib.optionals (hasSystem self "metacopy") [ moptilities ]
      ++ lib.optionals (hasSystem self "metacopy-with-contextl") [ contextl ]
      ++ lib.optionals (self.doCheck or false) [ lift ];
  });

  metacopy-with-contextl = metacopy.overrideAttrs {
    name = "metacopy-with-contextl";
    lispSystems = [
      "metacopy"
      "metacopy-with-contextl"
    ];
  };

  metatilities = lispDerivation (self: {
    src = sources.metatilities;
    lispSystem = "metatilities";
    lispDependencies =
      lib.optionals (hasSystem self "metatilities") [
        moptilities
        cl-containers
        metabang-bind
        metatilities-base
      ]
      ++ lib.optionals (hasSystem self "metatilities/with-lift") [
        asdf-system-connections
        final."cl-containers/with-asdf-system-connections"
        lift
      ]
      ++ lib.optionals (self.doCheck or false) [ lift ];
  });

  "metatilities/with-lift" = metatilities.overrideAttrs {
    name = "metatilities/with-lift";
    lispSystems = [
      "metatilities"
      "metatilities/with-lift"
    ];
  };

  metatilities-base = lispDerivation (self: {
    lispSystem = "metatilities-base";
    src = sources.metatilities-base;
    lispDependencies = lib.optionals (self.doCheck or false) [ lift ];
  });

  mgl-pax-bootstrap = lispDerivation (self: {
    name = "mgl-pax-bootstrap";
    src = sources.mgl-pax;
    lispSystems = [
      "mgl-pax-bootstrap"
    ]
    ++ lib.optionals (self.doCheck or false) [
      "mgl-pax"
      "mgl-pax/full"
    ];
    lispDependencies =
      lib.optionals (hasSystem self "mgl-pax") [
        autoload
        dref
        named-readtables
        pythonic-string-reader
      ]
      ++ lib.optionals (hasSystem self "mgl-pax/full") [
        # I don’t use the individual packages so I’ve just lumped them all
        # together.
        # mgl-pax/document
        final."3bmd"
        final."3bmd-ext-code-blocks"
        final."3bmd-ext-math"
        autoload-doc
        colorize
        final."dref/full"
        hunchentoot
        md5
        trivial-utf-8
        # mgl-pax/navigate
        swank
        # mgl-pax/transcribe
        alexandria
      ]
      ++
        lib.optionals
          (
            (self.doCheck or false)
            && (hasSystem self [
              "mgl-pax"
              "mgl-pax/full"
            ])
          )
          [
            try
            dref-test
          ];
    # This project is too complicated.  If it weren’t used by so many dependents
    # I would remove it.
    meta.broken =
      (self.doCheck or false)
      || ((hasSystem self "mgl-pax/full") && final._lisp.name == "clasp")
      || ((hasSystem self "mgl-pax") && final._lisp.name == "abcl")
      # 0 errors, 2 warnings/nix/store/0i25iw4373868kjqhafvmd6pn1wwzkh3-stdenv-linux/setup: line 1758:    43 Segmentation fault         (core dumped) /nix/store/ya6rksrfiv2kpb9nnnjs8xv5y0bpjn4c-clisp-2.49.95-unstable-2024-12-28/bin/clisp -E UTF-8 -norc /nix/store/qpzsa86nz9q863xwc0xizhyq8xgnz075-asdf-build-mgl-pax-bootstrap.lisp
      || (pkgs.stdenv.hostPlatform.isLinux && (hasSystem self "mgl-pax") && final._lisp.name == "clisp");
  });

  mgl-pax = mgl-pax-bootstrap.overrideAttrs {
    name = "mgl-pax";
    lispSystems = [
      "mgl-pax-bootstrap"
      "mgl-pax"
    ];
  };

  "mgl-pax/full" = mgl-pax-bootstrap.overrideAttrs {
    name = "mgl-pax/full";
    lispSystems = [
      "mgl-pax"
      "mgl-pax-bootstrap"
      "mgl-pax/full"
    ];
  };

  misc-extensions = lispify "misc-extensions" [ ];

  moptilities = lispDerivation (self: {
    lispSystem = "moptilities";
    lispDependencies = [ closer-mop ] ++ lib.optionals (self.doCheck or false) [ lift ];
    src = sources.moptilities;
    meta.broken = self.doCheck or false;
  });

  mt19937 = lispify "mt19937" [ ];

  myway = lispDerivation (self: {
    lispSystem = "myway";
    lispDependencies = [
      cl-ppcre
      quri
      map-set
      alexandria
      cl-utilities
    ]
    ++ lib.optionals (self.doCheck or false) [ prove ];
    src = sources.myway;
  });

  named-readtables = lispDerivation (self: {
    lispSystem = "named-readtables";
    src = sources.named-readtables;
    lispDependencies = [ mgl-pax-bootstrap ] ++ lib.optionals (self.doCheck or false) [ try ];
  });

  nclasses = lispDerivation (self: {
    lispDependencies = [ moptilities ] ++ lib.optionals (self.doCheck or false) [ lisp-unit2 ];
    src = sources.nclasses;
    lispSystem = "nclasses";
    meta.broken =
      # Requires a new version of ASDF that I’m not sure how to load before
      # building the code. See
      # "https://gitlab.common-lisp.net/asdf/asdf/-/issues/145".
      (final._lisp.name == "ecl")
      ||
        # The variable SIMPLE-CLASS is unbound.
        ((self.doCheck or false) && (final._lisp.name == "clasp"));
  });

  nfiles = lispDerivation (self: {
    lispSystem = "nfiles";
    src = sources.nfiles;
    lispDependencies = [
      alexandria
      nclasses
      quri
      serapeum
      trivial-garbage
      trivial-package-local-nicknames
      trivial-types
    ]
    ++ lib.optionals (self.doCheck or false) [ lisp-unit2 ];
  });

  ningle = lispDerivation (self: {
    lispSystem = "ningle";
    src = sources.ningle;
    lispDependencies = [
      myway
      lack
    ]
    ++ lib.optionals (self.doCheck or false) [
      prove
      yason
      babel
    ];
  });

  nst = lispDerivation (self: {
    lispSystem = "nst";
    src = sources.nst;
    lispDependencies = [
      org-sampler
    ]
    ++ lib.optionals (builtins.elem final._lisp.name [
      "sbcl"
      "clisp"
    ]) [ closer-mop ];
    preCheck = ''
      export CL_SOURCE_REGISTRY="$PWD/test//:$CL_SOURCE_REGISTRY"
    '';
    # No such NST group NST-METHODS-META-SOURCES::METHOD-TESTS
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  optima = lispDerivation (self: {
    name = "optima";
    src = sources.optima;
    lispSystems = [ "optima" ] ++ lib.optionals (self.doCheck or false) [ "optima.ppcre" ];
    lispDependencies =
      lib.optionals (hasSystem self "optima") [
        alexandria
        closer-mop
      ]
      ++ lib.optionals (hasSystem self "optima.ppcre") [ cl-ppcre ]
      ++ lib.optionals (self.doCheck or false) [ eos ];
  });

  optima-ppcre = optima.overrideAttrs {
    name = "optima.ppcre";
    lispsystems = [
      "optima"
      "optima.ppcre"
    ];
  };

  org-sampler = lispify "org-sampler" [ iterate ];

  osicat = lispDerivation (self: {
    lispSystem = "osicat";
    src = sources.osicat;
    postCheck = ''
      rm -rf tests
    '';
    # I am ashamed to say I /still/ don’t know how dynamic linking really works
    # in Nix. My God it’s not a learning curve it’s a fractal.
    postInstall = ''
      mkdir -p $out/lib
      ( cd $out/lib ; for f in ../posix/libosicat* ; do ln -s $f ./ ; done )
    '';
    lispDependencies = [
      alexandria
      cffi
      trivial-features
      cffi-grovel
    ]
    ++ lib.optionals (self.doCheck or false) [ rt ];
  });

  parachute = lispify "parachute" [
    documentation-utils
    form-fiddle
    trivial-custom-debugger
  ];

  parenscript = lispDerivation (self: {
    lispSystem = "parenscript";
    version = "2.7.1";
    src = sources.parenscript;
    lispDependencies = [
      anaphora
      cl-ppcre
      named-readtables
    ]
    ++ lib.optionals (self.doCheck or false) [
      fiveam
      cl-js
    ];
  });

  parse-declarations = lispDerivation {
    lispSystem = "parse-declarations-1.0";
    src = sources.parse-declarations;
  };

  parse-js = lispify "parse-js" [ ];

  parse-number = lispify "parse-number" [ ];

  parser-combinators = lispDerivation (self: {
    src = sources.parser-combinators;
    lispSystem = "parser-combinators";
    lispDependencies =
      lib.optionals (hasSystem self "parser-combinators") [
        iterate
        alexandria
      ]
      ++ lib.optionals (hasSystem self "parser-combinators-cl-ppcre") [ cl-ppcre ]
      ++ lib.optionals (self.doCheck or false) [
        stefil
        infix
      ];
  });

  parser-combinators-cl-ppcre = parser-combinators.overrideAttrs {
    name = "parser-combinators-cl-ppcre";
    lispSystem = [
      "parser-combinators"
      "parser-combinators-cl-ppcre"
    ];
  };

  path-parse = lispDerivation (self: {
    lispSystem = "path-parse";
    lispDependencies = [ split-sequence ] ++ lib.optionals (self.doCheck or false) [ fiveam ];
    src = sources.path-parse;
  });

  plump = lispify "plump" [
    array-utils
    documentation-utils
  ];

  proc-parse = lispDerivation (self: {
    lispSystem = "proc-parse";
    lispDependencies = [
      alexandria
      babel
    ]
    ++ lib.optionals (self.doCheck or false) [ prove ];
    src = sources.proc-parse;
  });

  prove = lispDerivation (self: {
    # Old name for this project
    lispSystems = [
      "prove"
      "cl-test-more"
    ];
    src = sources.prove;
    lispDependencies = [
      alexandria
      cl-ansi-text
      cl-colors
      cl-ppcre
    ]
    ++ lib.optionals (self.doCheck or false) [
      alexandria
      split-sequence
    ];
  });

  ptester = lispDerivation rec {
    lispSystem = "ptester";
    src = sources.ptester;
  };

  punycode = lispDerivation (self: {
    lispSystem = "punycode";
    src = sources.punycode;
    lispDependencies = lib.optionals (self.doCheck or false) [ parachute ];
  });

  puri = lispDerivation (self: {
    lispSystem = "puri";
    src = sources.puri;
    lispDependencies = lib.optionals (self.doCheck or false) [ ptester ];
  });

  pythonic-string-reader = lispify "pythonic-string-reader" [ named-readtables ];

  quickhull = lispify "quickhull" [
    final."3d-math"
    documentation-utils
  ];

  quri = lispDerivation (self: {
    lispSystem = "quri";
    lispDependencies = [
      alexandria
      babel
      cl-utilities
      idna
      split-sequence
    ]
    ++ lib.optionals (self.doCheck or false) [ prove ];
    src = sources.quri;
    # On ABCL this hard-codes a build path which isn’t available once it’s
    # moved to the store.  The dependent pacage will throw:
    #
    # The file #P"/private/tmp/nix-build-system-quri.drv-0/source/data/effective_tld_names.dat" does not exist.
    meta.broken = final._lisp.name == "abcl";
  });

  reblocks = lispDerivation (self: {
    lispSystem = "reblocks";
    src = sources.reblocks;
    lispDependencies = [
      final."40ants-doc"
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
      final."spinneret/cl-markdown"
      trivial-open-browser
      trivial-timeout
      uuid
      yason
    ]
    ++ lib.optionals (self.doCheck or false) [
      cl-mock
      final."hamcrest/rove"
      rove
    ];
    # Stateful tests in /tmp which break when run by different users
    meta.broken = self.doCheck or false;
  });

  reblocks-parenscript = lispDerivation (self: {
    lispSystem = "reblocks-parenscript";
    lispDependencies = [
      alexandria
      bordeaux-threads
      parenscript
      reblocks
    ]
    ++ lib.optionals (self.doCheck or false) [ rove ];
    src = sources.reblocks-parenscript;
  });

  reblocks-ui = lispDerivation (self: {
    lispSystem = "reblocks-ui";
    src = sources.reblocks-ui;
    lispDependencies = [
      final."40ants-doc"
      log4cl
      reblocks
      reblocks-parenscript
    ];
    # Build definition refers to non-existant test system as of
    # a9779313def0d362840e0fab990034cd999b6b07
    meta.broken = self.doCheck or false;
  });

  reblocks-websocket = lispDerivation (self: {
    lispSystem = "reblocks-websocket";
    src = sources.reblocks-websocket;
    lispDependencies = [
      alexandria
      bordeaux-threads
      jonathan
      log4cl-extras
      reblocks
      reblocks-parenscript
      serapeum
      websocket-driver
    ]
    ++ lib.optionals (self.doCheck or false) [ rove ];
  });

  rfc2388 = lispify "rfc2388" [ ];

  routes = lispDerivation (self: {
    lispSystem = "routes";
    src = sources.cl-routes;
    lispDependencies = [
      puri
      iterate
      split-sequence
    ]
    ++ lib.optionals (self.doCheck or false) [ lift ];
    meta.broken = self.doCheck or false;
  });

  # For some reason none of these dependencies are specified in the .asd
  rove = lispify "rove" [
    bordeaux-threads
    cl-ppcre
    dissect
    trivial-gray-streams
  ];

  rt = lispDerivation rec {
    lispSystem = "rt";
    src = sources.rt;
  };

  # rutils and rutilsx have the same dependencies etc, it’s not worth the hassle
  # creating separate derivations for them.
  rutils = lispDerivation (self: {
    lispSystems = [
      "rutils"
      "rutilsx"
    ];
    src = sources.rutils;
    lispDependencies = [
      named-readtables
      closer-mop
    ]
    ++ lib.optionals (self.doCheck or false) [ should-test ];
    meta.broken = self.doCheck or false;
  });

  s-sysdeps = lispify "s-sysdeps" [
    usocket
    usocket-server
    bordeaux-threads
  ];

  s-xml = lispify "s-xml" [ ];

  salza2 = lispDerivation (self: {
    lispSystem = "salza2";
    src = sources.salza2;
    lispDependencies = [
      trivial-gray-streams
    ]
    ++ lib.optionals (self.doCheck or false) [
      chipz
      flexi-streams
      parachute
    ];
    meta.broken =
      (self.doCheck or false)
      && (
        (final._lisp.name == "abcl")
        ||
          # The stream #<chipz::decompressing-stream @0x7fffd0c3a7b9> has no suitable method for #:stream-element-type.
          (final._lisp.name == "clasp")
      );
  });

  serapeum = lispDerivation (self: {
    src = sources.serapeum;
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
    ]
    ++ lib.optionals (self.doCheck or false) [
      fiveam
      local-time
      trivial-macroexpand-all
      atomics
    ];
    meta.broken =
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
      (final._lisp.name == "abcl")
      # Condition of type: UNBOUND-SLOT
      # The slot CLEAVIR-ENVIRONMENT::%TYPE in the object
      # #<CLEAVIR-ENVIRONMENT:LEXICAL-VARIABLE-INFO @0xffffc69775d9> is unbound.
      || (final._lisp.name == "clasp")
      # failed AVER:
      #   (AND (EQ (CTRAN-KIND START) INSIDE-BLOCK) (NOT (BLOCK-DELETE-P BLOCK)))
      || ((self.doCheck or false) && (final._lisp.name == "sbcl"));
  });

  sha1 = lispify "sha1" [ ];

  shasht = lispDerivation (self: {
    src = sources.shasht;
    lispSystem = "shasht";
    lispDependencies = [
      trivial-do
      closer-mop
    ]
    ++ lib.optionals (self.doCheck or false) [
      alexandria
      parachute
    ];
  });

  should-test = lispDerivation {
    lispSystem = "should-test";
    lispDependencies = [
      rutils
      local-time
      osicat
      cl-ppcre
    ];
    # TODO: This should be propagated from osicat somehow, not in every client
    # using osicat.
    preBuild = ''
      export LD_LIBRARY_PATH=''${LD_LIBRARY_PATH+$LD_LIBRARY_PATH:}${osicat}/lib
    '';
    buildInputs = [ osicat ];
    src = sources.should-test;
  };

  simple-date-time = lispify "simple-date-time" [ cl-ppcre ];

  slynk = lispDerivation {
    lispSystem = "slynk";
    src = sources.sly;
    lispAsdPath = [ "slynk" ];
  };

  smart-buffer = lispDerivation (self: {
    lispSystem = "smart-buffer";
    src = sources.smart-buffer;
    lispDependencies = [
      flexi-streams
      xsubseq
    ]
    ++ lib.optionals (self.doCheck or false) [
      babel
      prove
    ];
  });

  spinneret = lispDerivation (self: {
    src = sources.spinneret;
    lispSystem = "spinneret";

    lispDependencies = [
      alexandria
      cl-ppcre
      global-vars
      in-nomine
      parenscript
      serapeum
      trivia
      trivial-gray-streams
    ]
    ++ lib.optionals (hasSystem self "spinneret/cl-markdown") [ cl-markdown ]
    ++ lib.optionals (self.doCheck or false) [
      fiveam
      parenscript
    ];
    meta.broken = self.doCheck or false;
  });

  "spinneret/cl-markdown" = spinneret.overrideAttrs {
    name = "spinneret/cl-markdown";
    lispSystems = [
      "spinneret"
      "spinneret/cl-markdown"
    ];
  };

  split-sequence = lispDerivation (self: {
    lispSystem = "split-sequence";
    lispDependencies = lib.optionals (self.doCheck or false) [ fiveam ];
    src = sources.split-sequence;
  });

  # N.B.: Soon won’t depend on cffi-grovel
  static-vectors = lispDerivation (self: {
    lispSystem = "static-vectors";
    src = sources.static-vectors;
    lispDependencies = [
      alexandria
      cffi
      cffi-grovel
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
    meta.broken = final._lisp.name == "clisp";
  });

  stefil = lispify "stefil" [
    alexandria
    iterate
    metabang-bind
    swank
  ];

  stem = lispify "stem" [ ];

  str = lispDerivation (self: {
    lispSystem = "str";
    src = sources.str;
    lispDependencies = [
      cl-change-case
      cl-ppcre
      cl-ppcre-unicode
    ]
    ++ lib.optionals (self.doCheck or false) [ prove ];
    meta.broken = self.doCheck or false;
  });

  string-case = lispify "string-case" [ ];

  swank = lispDerivation {
    lispSystem = "swank";
    # The Swank Lisp system is bundled with SLIME
    src = sources.slime;
    patches = ./patches/slime-fix-swank-loader-fasl-cache-pwd.diff;
  };

  symbol-munger = lispDerivation (self: {
    src = sources.symbol-munger;
    lispSystem = "symbol-munger";
    lispDependencies = [
      alexandria
      iterate
    ]
    ++ lib.optionals (self.doCheck or false) [ lisp-unit2 ];
    # The variable TEST-BASIC is unbound.
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  tmpdir = lispify "tmpdir" [ cl-fad ];

  trivia = lispDerivation (self: {
    src = sources.trivia;
    lispSystems = [
      "trivia.trivial"
      "trivia"
    ];
    lispDependencies =
      lib.optionals (hasSystem self "trivia.trivial") [
        alexandria
        closer-mop
        lisp-namespace
        trivial-cltl2
      ]
      ++ lib.optionals (hasSystem self "trivia") [
        alexandria
        iterate
        type-i
      ]
      ++ lib.optionals (hasSystem self "trivia.cffi") [ cffi ]
      ++ lib.optionals (hasSystem self "trivia.fset") [ fset ]
      ++ lib.optionals (hasSystem self "trivia.ppcre") [ cl-ppcre ]
      ++ lib.optionals (hasSystem self "trivia.quasiquote") [ fare-quasiquote-readtable ]
      ++ lib.optionals ((self.doCheck or false) && (hasSystem self "trivia")) [
        fiveam
        optima
        final."trivia.cffi"
        final."trivia.fset"
        final."trivia.ppcre"
        final."trivia.quasiquote"
      ];
  });

  "trivia.cffi" = trivia.overrideAttrs (old: {
    lispSystems = [
      "trivia.trivial"
      "trivia.cffi"
    ];
  });

  "trivia.fset" = trivia.overrideAttrs (old: {
    lispSystems = [
      "trivia.trivial"
      "trivia.fset"
    ];
  });

  "trivia.ppcre" = trivia.overrideAttrs (old: {
    lispSystems = [
      "trivia.trivial"
      "trivia.ppcre"
    ];
  });

  "trivia.quasiquote" = trivia.overrideAttrs (old: {
    lispSystems = [
      "trivia"
      "trivia.quasiquote"
    ];
  });

  "trivia.trivial" = trivia.overrideAttrs (old: {
    lispSystems = [ "trivia.trivial" ];
  });

  trivial-arguments = lispify "trivial-arguments" [ ];

  trivial-backtrace = lispDerivation (self: {
    lispSystem = "trivial-backtrace";
    lispDependencies = lib.optionals (self.doCheck or false) [ lift ];
    src = sources.trivial-backtrace;
    meta.broken = self.doCheck or false;
  });

  trivial-benchmark = lispify "trivial-benchmark" [ documentation-utils ];

  trivial-cltl2 = lispDerivation {
    lispSystem = "trivial-cltl2";
    src = sources.trivial-cltl2;
  };

  trivial-custom-debugger = lispDerivation (self: {
    src = sources.trivial-custom-debugger;
    lispSystem = "trivial-custom-debugger";
    lispDependencies = lib.optionals (self.doCheck or false) [ parachute ];
    meta.broken =
      (self.doCheck or false)
      && (
        # #<MY-ERROR {354E970D}>
        (final._lisp.name == "abcl")
        ||
          # *** - Condition of type TRIVIAL-CUSTOM-DEBUGGER/TEST::MY-ERROR.
          (final._lisp.name == "clisp")
        ||
          # An error occurred during initialization: #<a TRIVIAL-CUSTOM-DEBUGGER/TEST::MY-ERROR 0x105c49d80>.
          (final._lisp.name == "ecl")
      );
  });

  trivial-extract = lispDerivation (self: {
    src = sources.trivial-extract;
    lispSystem = "trivial-extract";
    lispDependencies = [
      archive
      final.zip
      deflate
      which
      cl-fad
      alexandria
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  trivial-do = lispDerivation {
    src = sources.trivial-do;
    lispSystem = "trivial-do";
  };

  trivial-features = lispDerivation (self: {
    src = sources.trivial-features;
    lispSystem = "trivial-features";
    lispDependencies = lib.optionals (self.doCheck or false) [
      rt
      cffi
      cffi-grovel
      alexandria
    ];
  });

  trivial-file-size = lispDerivation (self: {
    src = sources.trivial-file-size;
    lispDependencies = lib.optionals (self.doCheck or false) [ fiveam ];
    lispSystem = "trivial-file-size";
  });

  trivial-garbage = lispDerivation (self: {
    src = sources.trivial-garbage;
    lispSystem = "trivial-garbage";
    lispDependencies = lib.optionals (self.doCheck or false) [ rt ];
  });

  trivial-gray-streams = lispify "trivial-gray-streams" [ ];

  trivial-indent = lispify "trivial-indent" [ ];

  trivial-macroexpand-all = lispify "trivial-macroexpand-all" [ ];

  trivial-mimes = lispDerivation {
    lispSystem = "trivial-mimes";
    src = sources.trivial-mimes;
    # Broken, see https://codeberg.org/shinmera/trivial-mimes/pulls/20. I don’t
    # know how to fix, nor care to further engage with upstream.  You’ll have to
    # fix and override yourself, or suggest a patch upstream.
    meta.broken = true;
  };

  trivial-open-browser = lispify "trivial-open-browser" [ ];

  trivial-package-local-nicknames = lispDerivation (self: {
    lispSystem = "trivial-package-local-nicknames";
    src = sources.trivial-package-local-nicknames;
    # test hangs indefinitely
    meta.broken = (self.doCheck or false) && (final._lisp.name == "clasp");
  });

  trivial-rfc-1123 = lispify "trivial-rfc-1123" [ cl-ppcre ];

  trivial-shell = lispDerivation (self: {
    lispSystem = "trivial-shell";
    src = sources.trivial-shell;
    lispDependencies = lib.optionals (self.doCheck or false) [ lift ];
  });

  trivial-sockets = lispDerivation {
    lispSystem = "trivial-sockets";
    src = sources.trivial-sockets;
    meta.broken =
      # Error while trying to load definition for system trivial-sockets from pathname /build/source/trivial-sockets.asd: keyword list is not a proper list
      final._lisp.name == "clasp"
      # Supported lisps: sbcl cmu clisp acl openmcl lispworks abcl mcl
      || final._lisp.name == "ecl";
  };

  trivial-timeout = lispDerivation (self: {
    lispSystem = "trivial-timeout";
    lispDependencies = lib.optionals (self.doCheck or false) [ lift ];
    src = sources.trivial-timeout;
    meta.broken = self.doCheck or false;
  });

  trivial-types = lispify "trivial-types" [ ];

  trivial-utf-8 = lispify "trivial-utf-8" [ mgl-pax-bootstrap ];

  trivial-with-current-source-form = lispify "trivial-with-current-source-form" [ ];

  try = lispDerivation (self: {
    lispSystem = "try";
    src = sources.try;
    lispDependencies = [
      alexandria
      cl-ppcre
      closer-mop
      ieee-floats
      mgl-pax
      trivial-gray-streams
    ];
    meta.broken = self.doCheck or false;
  });

  type-i = lispDerivation (self: {
    lispSystem = "type-i";
    src = sources.type-i;
    lispDependencies = [
      alexandria
      introspect-environment
      final."trivia.trivial"
      lisp-namespace
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
    # hangs forever
    meta.broken =
      (self.doCheck or false)
      && (builtins.elem final._lisp.name [
        "clasp"
        "ecl"
      ]);
  });

  type-templates = lispDerivation {
    lispDependencies = [
      alexandria
      form-fiddle
      documentation-utils
    ];
    lispSystem = "type-templates";
    src = sources.type-templates;
  };

  typo = lispDerivation (self: {
    lispSystem = "typo";
    lispDependencies = [
      alexandria
      closer-mop
      introspect-environment
      trivia
      trivial-arguments
      trivial-garbage
    ];
    src = sources.typo;
    lispAsdPath = [ "code" ];
    preCheck = ''
      export CL_SOURCE_REGISTRY="$PWD/code/test-suite:$CL_SOURCE_REGISTRY"
    '';
    meta.broken =
      (builtins.elem final._lisp.name [
        "ecl"
        "clasp"
        "clisp"
      ])
      || (self.doCheck or false);
  });

  unit-test = lispify "unit-test" [ ];

  unix-options = lispify "unix-options" [ ];

  usocket = lispDerivation (self: {
    lispSystem = "usocket";
    src = sources.usocket;
    lispDependencies =
      lib.optionals (hasSystem self "usocket") [
        babel
        split-sequence
      ]
      ++ lib.optionals (hasSystem self "usocket-server") [
        usocket
        bordeaux-threads
      ]
      ++ lib.optionals ((self.doCheck or false) && (hasSystem self "usocket")) [
        bordeaux-threads
        rt
      ];
    # Hangs forever on ABCL
    meta.broken =
      (self.doCheck or false) && (pkgs.stdenv.hostPlatform.isLinux || (final._lisp.name == "abcl"));
  });

  usocket-server = usocket.overrideAttrs { lispSystems = [ "usocket-server" ]; };

  uuid = lispify "uuid" [
    ironclad
    trivial-utf-8
  ];

  vom = lispify "vom" [ ];

  websocket-driver = lispify "websocket-driver" [
    babel
    bordeaux-threads
    final."cl+ssl"
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

  which = lispDerivation (self: {
    lispSystem = "which";
    src = sources.which;
    lispDependencies = [
      path-parse
      cl-fad
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
  });

  wild-package-inferred-system = lispDerivation (self: {
    lispDependencies = lib.optionals (self.doCheck or false) [ fiveam ];
    lispSystem = "wild-package-inferred-system";
    src = sources.wild-package-inferred-system;
    # Clisp packages ASDF v3.2, WPI requires ≥3.3, this is the easiest way to
    # remedy that. Of course you can byo-ASDF, at which point you can just
    # .overrideAttrs this flag back to false. Same for ECL.
    meta.broken = builtins.elem final._lisp.name [
      "clisp"
      "ecl"
    ];
  });

  with-output-to-stream = lispDerivation (self: {
    lispSystem = "with-output-to-stream";
    version = "1.0";
    src = sources.with-output-to-stream;
    meta.broken = self.doCheck or false;
  });

  wu-decimal = lispify "wu-decimal" [ ];

  xml-emitter = lispDerivation (self: {
    src = sources.xml-emitter;
    lispSystem = "xml-emitter";
    lispDependencies = [ cl-utilities ] ++ lib.optionals (self.doCheck or false) [ final."1am" ];
  });

  xlunit = lispDerivation (self: {
    lispSystem = "xlunit";
    version = "3805d34b1d8dc77f7e0ee527a2490194292dd0fc";
    src = sources.xlunit;
    meta.broken = self.doCheck or false;
  });

  xsubseq = lispDerivation (self: {
    src = sources.xsubseq;
    lispSystem = "xsubseq";
    lispDependencies = lib.optionals (self.doCheck or false) [ prove ];
  });

  # QL calls this "cl-yacc", but the system name is "yacc", so I’m sticking to
  # "yacc". Regardless of the repo name--that’s not authoritative. The system
  # name is.
  yacc = lispDerivation {
    lispSystem = "yacc";
    src = sources.yacc;
  };

  yason = lispify "yason" [
    alexandria
    trivial-gray-streams
  ];

  zip = lispify "zip" [
    trivial-gray-streams
    babel
    cl-fad
    salza2
  ];

  zpng = lispify "zpng" [ salza2 ];

  zstd = lispDerivation (self: {
    lispDependencies = [
      cffi
      cl-octet-streams
      trivial-gray-streams
    ]
    ++ lib.optionals (self.doCheck or false) [ fiveam ];
    lispSystem = "zstd";
    propagatedBuildInputs = [ pkgs.zstd ];
    src = sources.cl-zstd;
    meta.broken =
      (self.doCheck or false) && (final._lisp.name == "clisp") && pkgs.stdenv.hostPlatform.isLinux;
  });
}
