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
  pkgs ? import <nixpkgs> {}
  , lisp ? pkgs.sbcl
}:

with {
  inherit (pkgs) lib;
};

lib.recurseIntoAttrs (lib.makeScope pkgs.newScope (self:
with self;

with lib;

with callPackage ./utils.nix {};
with callPackage ./lisp-derivation.nix { inherit lisp; };

# These utility functions really are for this file only
let
  lispify = lispDependencies: src:
    lispDerivation ({
      inherit lispDependencies src;
      # Convention.
      lispSystem = src.lispSystem or trimName (src.pname or src.name);
    } // (
      optionalKeys [ "version" "CL_SOURCE_REGISTRY" ] src
    ) // (
      a.mapAttrs (_: trimName) (optionalKeys [ "name" "pname" ] src)
    ));

  # Get a source from debian package repository.
  fetchDebianPkg = { pname, version, ... }@args:
    let
      a = lib.head (lib.stringToCharacters pname);
      src = pkgs.fetchzip (args // {
        pname = "${pname}-src";
        url = "http://deb.debian.org/debian/pool/main/${a}/${pname}/${pname}_${version}.orig.tar.xz";
      });
    in
      lib.sources.cleanSourceWith {
        filter = path: type:
          let
            relPath = lib.removePrefix (toString src) (toString path);
          in
            relPath != "/debian" || type != "directory";
        inherit src;
      };

  fetchKpePkg = { name, version, sha256 }: pkgs.fetchzip {
    pname = "${name}-src";
    inherit version sha256;
    url = "http://git.kpe.io/?p=${name}.git;a=snapshot;h=${version}";
    # This is necessary because the auto generated filename for a gitweb
    # URL contains invalid characters.
    extension = "tar.gz";
  };
in
{
  inherit lispDerivation lispMultiDerivation lispWithSystems;

  _1am = callPackage (self: with self; lispify [] (pkgs.fetchFromGitHub {
    owner = "lmj";
    repo = "1am";
    name = "1am-src";
    rev = "8b1da94eca4613fd8a20bdf63f0e609e379b0ba5";
    sha256 = "T+y6Bc/i6jF0/Eg6XZOQrHBhlkCkJGHSWTMtGb4lWhc=";
  })) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      name = "3bmd-src";
      owner = "3b";
      repo = "3bmd";
      rev = "20a53fb740eac727ecabd439f2580cf483c98f4d";
      sha256 = "sha256-sooK263J7KwiYxCGrZavLMvf3TYMQErdKUKdCdXSuqw=";
    };
    systems = {
      _3bmd = {
        lispSystem = "3bmd";
        lispDependencies = [ alexandria esrap split-sequence ];
        lispCheckDependencies = [ _3bmd-ext-code-blocks fiasco ];
      };
      _3bmd-ext-code-blocks = {
        lispSystem = "3bmd-ext-code-blocks";
        lispDependencies = [ _3bmd alexandria colorize split-sequence ];
      };
    };
  }) {}) _3bmd _3bmd-ext-code-blocks;

  _3d-vectors = callPackage (self: with self; lispDerivation {
    lispDependencies = [ documentation-utils ];
    lispCheckDependencies = [ parachute ];
    src = pkgs.fetchFromGitHub {
      owner = "Shinmera";
      repo = "3d-vectors";
      name = "3d-vectors-src";
      rev = "03e6a376c43da6ccb9e3949be12edde51c695edb";
      sha256 = "1oeykwz0rabW6CpZKEQ2LP0CPjpzx3gLDzaecCPZOQk=";
    };
    lispSystem = "3d-vectors";
  }) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "40ants";
      repo = "doc";
      name = "doc-src";
      rev = "dbd4e7e5083e4bf06cdcb62c938c30ff66c0f35d";
      sha256 = "jcpP26KJxG6ZIXkpVzVwjiQ/dMT+GgFD2yhA7h3ntEY=";
    };
    systems = {
      _40ants-doc = {
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
          _40ants-doc-full
        ];
      };
      _40ants-doc-full = {
        lispSystem = "40ants-doc-full";
        lispDependencies = [
          _40ants-doc
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
  }) {}) _40ants-doc _40ants-doc-full;

  # Something very odd is happening with the ASDF scope here. I have absolutely
  # no idea why and I’m almost frightened to even find out. If I use the same
  # self: with self; syntax as everywhere else, this captures asdf’s src (!),
  # not the derivation itself. But only asdf, not e.g. alexandria. What’s worse:
  # this fixes it. Wat?????????????????
  _40ants-asdf-system = callPackage ({ asdf, ... }@self: with self; (lispDerivation {
    lispSystem = "40ants-asdf-system";
    src = pkgs.fetchFromGitHub {
      owner = "40ants";
      repo = "40ants-asdf-system";
      name = "40ants-asdf-system-src";
      rev = "d9717a31eced40898b03264484489f19f0b825c2";
      sha256 = "vrolkXLVMmf//qZx1rivCo8F9v1Bz1anw2ezTnp2Jgs=";
    };
    # Depends on a modern ASDF. SBCL’s built-in ASDF crashes this.
    lispDependencies = [ asdf ];
    lispCheckDependencies = [ rove ];
  })) {};

  access = callPackage (self: with self; lispDerivation {
    lispSystem = "access";
    src = pkgs.fetchFromGitHub {
      owner = "AccelerationNet";
      repo = "access";
      name = "access-src";
      rev = "1f3440b03823e01bc6f1384daf18626234f86447";
      sha256 = "8P4dBjxbcMCr6cgwpTS0sCU0E513bxxf5ifWS34n+Ek=";
    };
    lispDependencies = [ alexandria closer-mop iterate cl-ppcre ];
    lispCheckDependencies = [ lisp-unit2 ];
  }) {};

  acclimation = callPackage (self: with self; lispify [] (pkgs.fetchFromGitHub {
    owner = "robert-strandh";
    repo = "Acclimation";
    name = "Acclimation-src";
    rev = "4fc59692f2a12d1038fd3978bb6e66f554672049";
    sha256 = "Cp2bvFvCHzyWoW+pwbRGBqSKbi9Nv0JwWAmSs9VUFgk=";
  })) {};

  alexandria = callPackage (self: with self; lispDerivation {
    lispSystem = "alexandria";
    src = pkgs.fetchFromGitLab {
      name = "alexandria-src";
      domain = "gitlab.common-lisp.net";
      owner = "alexandria";
      repo = "alexandria";
      rev = "v1.4";
      sha256 = "sha256-1Hzxt65dZvgOFIljjjlSGgKYkj+YBLwJCACi5DZsKmQ=";
    };
    lispCheckDependencies = l.optional ((lisp.pname or "") != "sbcl") rt;
  }) {};

  alien-ring = callPackage (self: with self; lispify [ cffi trivial-gray-streams ] (pkgs.fetchFromGitHub {
    owner = "mateuszb";
    name = "alien-ring-src";
    repo = "alien-ring";
    rev = "9bad594df4dc1b700ed319e95c81b38c61120241";
    sha256 = "2t8qcvTIy+SUreAOI9OR1F0F8oOd/ePempApEVgJGVQ=";
  })) {};

  anaphora = callPackage (self: with self; lispDerivation {
    lispSystem = "anaphora";
    lispCheckDependencies = [ rt ];
    src = pkgs.fetchFromGitHub {
      name = "anaphora-src";
      owner = "spwhitton";
      repo = "anaphora";
      rev = "0.9.8";
      sha256 = "sha256-CzApbUmdDmD+BWPcFGJN0rdZu991354EdTDPn8FSRbc=";
    };
  }) {};

  archive = callPackage (self: with self; lispify [ trivial-gray-streams cl-fad ] (pkgs.fetchFromGitHub {
    owner = "sharplispers";
    repo = "archive";
    name = "archive-src";
    rev = "631271c091ed02994bec3980cb288a2cf32c7cdc";
    sha256 = "l2wLh0WuO8/l8U4H1vhtX0MToSb41wlaz6cvX11iel8=";
  })) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "AccelerationNet";
      repo = "arnesi";
      name = "arnesi-src";
      rev = "1e7dc4cb2cad8599113c7492c78f4925e839522e";
      sha256 = "cM045vNFKPdVymsUoF9G1/aVV510EBWRywa/0F4X8kk=";
    };
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

  array-utils = callPackage (self: with self; lispDerivation {
    lispSystem = "array-utils";
    lispCheckDependencies = [ parachute ];
    src = pkgs.fetchFromGitHub {
      name = "array-utils-src";
      owner = "Shinmera";
      repo = "array-utils";
      rev = "40cea8fc895add87d1dba9232da817750222b528";
      sha256 = "sha256-jcVm7dXVj69XrP8Ggl9bZWZ9Ultth/AFUkpANFVr9jQ=";
    };
  }) {};

  arrow-macros = callPackage (self: with self; lispDerivation {
    lispSystem = "arrow-macros";

    src = pkgs.fetchFromGitHub {
      name = "arrow-macros-src";
      owner = "hipeta";
      repo = "arrow-macros";
      rev = "0.2.7";
      sha256 = "sha256-r8zNLtBtk02xgz8oDM49sYs84SZya42GJaoHFnE/QZA=";
    };

    lispDependencies = [ alexandria ];
    lispCheckDependencies = [ fiveam ];
  }) {};

  asdf = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitLab {
    name = "asdf-src";
    domain = "gitlab.common-lisp.net";
    owner = "asdf";
    repo = "asdf";
    rev = "3.3.6";
    sha256 = "sha256-GCmGUMLniPakjyL/D/aEI93Y6bBxjdR+zxXdSgc9NWo=";
  })) {};

  asdf-flv = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "net.didierverna.asdf-flv-src";
    owner = "didierverna";
    repo = "asdf-flv";
    rev = "version-2.1";
    sha256 = "sha256-5IFe7OZgQ9bgaqtTcvoyA5aJPy+KbtuKRA9ygbciCYA=";
  })) {};

  assoc-utils = callPackage (self: with self; lispDerivation {
    lispSystem = "assoc-utils";
    src = pkgs.fetchFromGitHub {
      name = "assoc-utils-src";
      owner = "fukamachi";
      repo = "assoc-utils";
      rev = "483a22ef42995f84fac00d11fb27ace671480153";
      sha256 = "sha256-mncs6+mGNBoZea6jPtgjFxYPbFguUne8MepxTHgsC1c=";
    };
    lispCheckDependencies = [ prove ];
  }) {};

  atomics = callPackage (self: with self; lispDerivation {
    lispSystem = "atomics";
    src = pkgs.fetchFromGitHub {
      owner = "shinmera";
      repo = "atomics";
      name = "atomics-src";
      rev = "9ee0bdebcd2bb9b242671a75460db13fbf45454c";
      sha256 = "H5B2rQvcqUwiLuKuOGc774+IMUsk8G0fbFUpgHGT5VY=";
    };
    lispDependencies = [ documentation-utils ];
    lispCheckDependencies = [ parachute ];
  }) {};

  inherit (callPackage (self: with self;
    lispMultiDerivation {
      src = pkgs.fetchFromGitHub {
        name = "babel-src";
        owner = "cl-babel";
        repo = "babel";
        rev = "627d6a60d0ffc82a3687b39ba8a99128031504d9";
        sha256 = "AA0PJL0A1HsWBM8bkegxduREPH5Vp4rpz9v76dNVzeo=";
      };

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

  blackbird = callPackage (self: with self; lispDerivation {
    lispSystem = "blackbird";
    src = pkgs.fetchFromGitHub {
      name = "blackbird-src";
      repo = "blackbird";
      owner = "orthecreedence";
      rev = "abe3696e1a128bd082fb5d3e211f33d8feb25bc8";
      sha256 = "sha256-VBmXHK6TKNcYbCdIhVSP08E0blGVJCL9N/VPNQ5JDuQ=";
    };
    lispDependencies = [ vom ];
    lispCheckDependencies = [ cl-async fiveam ];
  }) {};

  bordeaux-threads = callPackage (self: with self; lispDerivation rec {
    lispDependencies = [
      alexandria
      global-vars
      trivial-features
      trivial-garbage
    ];
    lispCheckDependencies = [ fiveam ];
    buildInputs = [ pkgs.libuv ];
    lispSystem = "bordeaux-threads";
    version = "v0.8.8";
    src = pkgs.fetchFromGitHub {
      name = "bordeaux-threads-src";
      owner = "sionescu";
      repo = "bordeaux-threads";
      rev = version;
      sha256 = "sha256-5mauBDg13zJlYkbu5C30dCOIPBE95bVu2AiR8d0gJKY=";
    };
  }) {};

  inherit (callPackage (self: with self;
    lispMultiDerivation rec {
      name = "cffi";
      version = "v0.24.1";
      src = pkgs.fetchFromGitHub {
        name = "cffi-src";
        owner = "cffi";
        repo = "cffi";
        rev = version;
        sha256 = "sha256-QzISoQ4JpLhnxnPlSgWYE0PbSionu+b7z2HR2EmNPp8=";
      };
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

  calispel = callPackage (self: with self; lispDerivation {
    lispSystem = "calispel";
    src = pkgs.fetchFromGitHub {
      owner = "hawkir";
      repo = "calispel";
      name = "calispel-src";
      rev = "e9f2f9c1af97f4d7bb4c8ac25fb2a8f3e8fada7a";
      sha256 = "6KeWzrKB1lFc0IyflOpe00jWWTFvYlxvU7DYE+9wdSE=";
    };
    lispDependencies = [ jpl-queues bordeaux-threads ];
    lispCheckDependencies = [ eager-future2 ];
  }) {};

  chipz = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "chipz-src";
    owner = "sharplispers";
    repo = "chipz";
    rev = "6f803684415704114f213c64e13b231627e7777f";
    sha256 = "sFTNTrIE8u4bxLex3cmhkCDn7zzD1MXCRa0d8mmg2hM=";
  })) {};

  chunga = callPackage (self: with self; lispify [ trivial-gray-streams ] (pkgs.fetchFromGitHub {
    name = "chunga-src";
    owner = "edicl";
    repo = "chunga";
    rev = "v1.1.7";
    sha256 = "sha256-DfqbKCuK4oTh1qrKHdOCdWhcdUrT5YFSfUK4sbwd9ks=";
  })) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      name = "coalton-src";
      repo = "coalton";
      owner = "coalton-lang";
      rev = "dc46c0ad48e2af8ed9afe7766d2a290555a3195d";
      sha256 = "v/7HUWznFYtqimsoE4V0w7gc5PX9I5TlEtlHV7hZOxE=";
    };
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

  circular-streams = callPackage (self: with self; lispDerivation {
    lispSystem = "circular-streams";
    src = pkgs.fetchFromGitHub {
      name = "circular-streams-src";
      owner = "fukamachi";
      repo = "circular-streams";
      rev = "e770bade1919c5e8533dd2078c93c3d3bbeb38df";
      sha256 = "sha256-OpeLjFbiiwycwZjMeYgu7YoyFYy7HieSY9hHxkoz/PI=";
    };
    lispDependencies = [ fast-io trivial-gray-streams ];
    lispCheckDependencies = [ cl-test-more flexi-streams ];
  }) {};

  cl-annot = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-annot";
    src = pkgs.fetchFromGitHub {
      name = "cl-annot-src";
      owner = "m2ym";
      repo = "cl-annot";
      rev = "c99e69c15d935eabc671b483349a406e0da9518d";
      sha256 = "sha256-lkyoenlsJLbc1etJyqTTeLcSTxPMgJ15NLU0KZN+AfM=";
    };
    lispDependencies = [ alexandria ];
    lispCheckDependencies = [ cl-test-more ];
  }) {};

  cl-ansi-text = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-ansi-text";
    src = pkgs.fetchFromGitHub {
      name = "cl-ansi-text-src";
      owner = "pnathan";
      repo = "cl-ansi-text";
      rev = "v2.0.1";
      sha256 = "sha256-JChf6zT7JPpm50RjVkB1ziO+pDTI/+Fj4Gck5bBUZ1o=";
    };
    lispDependencies = [ alexandria cl-colors2 ];
    lispCheckDependencies = [ fiveam ];
  }) {};

  inherit (callPackage (self: with self; lispMultiDerivation rec {
    name = "cl-async";
    version = "909c691ec7a3bfe98bbec536ab55d7eac8990a81";

    src = pkgs.fetchFromGitHub {
      name = "cl-async-src";
      owner = "orthecreedence";
      repo = "cl-async";
      rev = version;
      sha256 = "sha256-lonRpqW51lrf0zpOstYq261m2UR1YMrgKR23kLBrhfY=";
    };

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

  cl-base64 = callPackage (self: with self; lispDerivation rec {
    lispSystem = "cl-base64";
    version = "577683b18fd880b82274d99fc96a18a710e3987a";
    src = fetchKpePkg {
      inherit version;
      name = "cl-base64";
      sha256 = "sha256-cuVDuPj8gXiN9kLgWpWerkZgodno2s3OENZoByApUoo=";
    };
    lispCheckDependencies = [ ptester kmrcl ];
  }) {};

  cl-change-case = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-change-case";
    src = pkgs.fetchFromGitHub {
      name = "cl-change-case-src";
      repo = "cl-change-case";
      owner = "rudolfochrist";
      rev = "0.2.0";
      sha256 = "sha256-mPRkekxFg3t6hcWkPE0TDGgj9mh/ymISDr2h+mJQAmI=";
    };
    lispDependencies = [
      cl-ppcre
      cl-ppcre-unicode
    ];
    lispCheckDependencies = [ fiveam ];
  }) {};

  cl-colors = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-colors";
    lispCheckDependencies = [ lift ];
    lispDependencies = [ alexandria let-plus ];
    src = pkgs.fetchFromGitHub {
      name = "cl-colors-src";
      owner = "tpapp";
      repo = "cl-colors";
      rev = "827410584553f5c717eec6182343b7605f707f75";
      sha256 = "sha256-KvnhquSX+rXTeUuN0cKSaG93UqRy4JWqXh4Srxo1hFA=";
    };
  }) {};

  cl-colors2 = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-colors2";
    src = pkgs.fetchzip rec {
      pname = "cl-colors2-src";
      version = "cc37737fc70892ed97152842fafa086ad1b7beab";
      url = "https://notabug.org/cage/cl-colors2/archive/${version}.tar.gz";
      sha256 = "sha256-GXq3Q6MjdS79EKks2ayojI+ZYh8hRVkd0TNkpjWF9zI=";
    };
    lispDependencies = [ alexandria cl-ppcre ];
    lispCheckDependencies = [ clunit2 ];
  }) {};

  cl-containers = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "gwkkwg";
      repo = "cl-containers";
      name = "cl-containers-src";
      rev = "cc491c299ebeb607a875e119a826b3acd4e2b3bf";
      sha256 = "irffYp8F4rCKM4Ln8bNf8HIy0N1fBlP9qghO3HYA5j8=";
    };
    lispDependencies = [ metatilities-base ];
    lispCheckDependencies = [ lift ];
    lispSystem = "cl-containers";
  }) {};

  cl-cookie = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-cookie";
    src = pkgs.fetchFromGitHub {
      name = "cl-cookie-src";
      repo = "cl-cookie";
      owner = "fukamachi";
      rev = "e6babbf57c9c6e0b6998a5b5ecaea8fa59f88296";
      sha256 = "sha256-RBTuCVQA2DKjgznDvKRYI+TGDH1c5Xuk6LW321hVGB4=";
    };
    lispDependencies = [ alexandria cl-ppcre proc-parse local-time quri ];
    lispCheckDependencies = [ prove ];
  }) {};

  cl-coveralls = callPackage (self: with self; lispDerivation {
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
    src = pkgs.fetchFromGitHub {
      name = "cl-coveralls-src";
      owner = "fukamachi";
      repo = "cl-coveralls";
      rev = "69b2f05540392f204c0312f4be356145932b2787";
      sha256 = "sha256-4LM1pMzJkvR5Uo0A6mI7iT6RR9fP+P9FXP0IJJKektg=";
    };
  }) {};

  cl-custom-hash-table = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "metawilm";
      repo = "cl-custom-hash-table";
      name = "cl-custom-hash-table-src";
      rev = "7bd02a529d39065ca8190966403b984552e0212a";
      sha256 = "Y0LZvhSUucHhJdibuL9pe0QFyi5ZqacIsOIOjCEd19M=";
    };
    lispSystem = "cl-custom-hash-table";
    lispCheckDependencies = [ hu_dwim_stefil ];
  }) {};

  cl-difflib = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    owner = "wiseman";
    repo = "cl-difflib";
    name = "cl-difflib-src";
    rev = "98eb335c693f1881584b83ca7be4a0fe05355c4e";
    sha256 = "iOB6ichf4umGIByi+7m2oWCsHNr96PRZDyk8DJcCLiI=";
  })) {};

  cl-dot = callPackage ({}: lispify [] (pkgs.fetchFromGitHub {
    owner = "michaelw";
    repo = "cl-dot";
    name = "cl-dot-src";
    rev = "73dfbb6e015a28ebed873266e4e8190e509b43de";
    sha256 = "ql/MVIQLhiM/AvpuPRV1Lg4qRfZCKfQzyj+Xxxz+m1U=";
  })) {};

  cl-fad = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-fad";
    src = pkgs.fetchFromGitHub {
      name = "cl-fad-src";
      owner = "edicl";
      repo = "cl-fad";
      rev = "v0.7.6";
      sha256 = "sha256-6m6gvc5Hgby2K5U6sVuks4qZL8mkVEvBO3o+swWKiL0=";
    };
    lispDependencies = [ alexandria bordeaux-threads ];
    lispCheckDependencies = [ cl-ppcre unit-test ];
  }) {};

  cl-gopher = callPackage (self: with self; lispify [
    usocket
    flexi-streams
    drakma
    bordeaux-threads
    quri
  ] (pkgs.fetchFromGitHub {
    owner = "knusbaum";
    repo = "cl-gopher";
    name = "cl-gopher-src";
    rev = "0899e7fa2134206f9d9778c7d53c49b7a59ff070";
    sha256 = "TnA/NAeyLRhJHVd+YXqhDuORcr8iRIlV2xy0UsfQxM8=";
  })) {};

  cl-html-diff = callPackage (self: with self; lispify [ cl-difflib ] (pkgs.fetchFromGitHub {
    owner = "wiseman";
    repo = "cl-html-diff";
    name = "cl-html-diff-src";
    rev = "5a0b39d1c524278d6f60851d7786bb2585614310";
    sha256 = "6/OtMlQod7DqJvSxouD/Ixw9y0WfBVvjlaT9HWW0We0=";
  })) {};

  cl-interpol = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-interpol";
    src = pkgs.fetchFromGitHub {
      name = "cl-interpol-src";
      owner = "edicl";
      repo = "cl-interpol";
      rev = "v0.2.7";
      sha256 = "sha256-Q45Z61BtAhaelYLrJkE2cNa/kRIQSngrrABjieO+1OQ=";
    };
    lispDependencies = [ cl-unicode named-readtables ];
    lispCheckDependencies = [ flexi-streams ];
  }) {};

  cl-isaac = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-isaac";
    src = pkgs.fetchFromGitHub {
      name = "cl-isaac-src";
      owner = "thephoeron";
      repo = "cl-isaac";
      rev = "9cd88f39733be753facbf361cb0e08b9e42ff8d5";
      sha256 = "sha256-iV+7YkGPAA+e0SXODlSDAJIUUiL+pcj2ya7FHJGr4UU=";
    };
    lispCheckDependencies = [ prove ];
  }) {};

  cl-js = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-js";
    src = pkgs.fetchFromGitHub {
      owner = "akapav";
      repo = "js";
      name = "cl-js-src";
      rev = "3a9a1a887bef6b571922f2820f871935121052a5";
      sha256 = "p4KM37SGRI70iMO4XDy6QrOPed9V0VJdxbqyb0C5wq0=";
    };
    lispDependencies = [ parse-js cl-ppcre ];
  }) {};

  cl-json = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-json";
    lispCheckDependencies = [ fiveam ];
    src = pkgs.fetchFromGitHub {
      owner = "sharplispers";
      repo = "cl-json";
      name = "cl-json-src";
      rev = "994dd38c94344383f39f95d75987f6dc47a0cca1";
      sha256 = "JavUsbAPdJqsWYeemliL039HzBCVpfW4vyeGdsifaos=";
    };
  }) {};

  cl-libuv = callPackage (self: with self; lispDerivation rec {
    lispDependencies = [ alexandria cffi cffi-grovel ];
    propagatedBuildInputs = [ pkgs.libuv ];
    lispSystem = "cl-libuv";
    version = "ebe3e166d1b6608efdc575be55579a086356b3fc";
    src = pkgs.fetchFromGitHub {
      name = "cl-libuv-src";
      owner = "orthecreedence";
      repo = "cl-libuv";
      rev = version;
      sha256 = "sha256-sGN4sIM+yy7VXudzrU6jV/+DLEY12EOK69TXnh94rGU=";
    };
  }) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    # src = pkgs.fetchFromGitHub {
    #   owner = "archimag";
    #   repo = "cl-libxml2";
    #   name = "cl-libxml2-src";
    #   rev = "8d03110c532c1a3fe15503fdfefe82f60669e4bd";
    #   sha256 = "PCumcbKT2J8ffvbJgt3ESZ0mhTk809QN0+U6NgJLBCQ=";
    # };
    # Temporarily point at my own fork while figuring out Darwin build. Could
    # also use Nix patches but this is easier for me to manage.
    src = pkgs.fetchFromGitHub {
      owner = "hraban";
      repo = "cl-libxml2";
      rev = "6ca0386e9914f733cfcde38000e84f90ccee42cb";
      sha256 = "T5hEn517H2DlIaqLsSb6CtcV2z+6nDxnm9QqhsblsIc=";
    };
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

  cl-locale = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "fukamachi";
      repo = "cl-locale";
      name = "cl-locale-src";
      rev = "0a36cc0dcf5e0a8c8bf97869cd6199980ca25eec";
      sha256 = "N9mqMbFt7NZitXX792NYOPGhBiJVUXddeD5wfaG1CuY=";
    };
    lispDependencies = [ anaphora arnesi cl-annot cl-syntax cl-syntax-annot ];
    lispCheckDependencies = [ flexi-streams prove ];
    lispSystem = "cl-locale";
  }) {};

  cl-markdown = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-markdown";
    src = pkgs.fetchFromGitLab {
      name = "cl-markdown-src";
      domain = "gitlab.common-lisp.net";
      owner = "cl-markdown";
      repo = "cl-markdown";
      rev = "4808ef7657e58e52733f528fd9812dc2df9f4e90";
      sha256 = "sha256-b2NMT7o8Fp9W+w2BwPYUpkxjWTsQMlFxcRNNW8yJevI=";
    };
    lispDependencies = [
      anaphora
      cl-containers
      cl-ppcre
      dynamic-classes
      metabang-bind
      metatilities-base
    ];
    lispCheckDependencies = [ lift trivial-shell ];
  }) {};

  cl-plus-ssl = callPackage (self: with self; lispDerivation {
    lispSystem = "cl+ssl";
    src = pkgs.fetchFromGitHub {
      name = "cl+ssl-src";
      repo = "cl-plus-ssl";
      owner = "cl-plus-ssl";
      rev = "581dec69d32dfaac57215016a3f5167a40834517";
      sha256 = "EYZi1CPiBYGQLOd7haqJkyyUFSYYgX4c7NaXutLLopI=";
    };
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

  inherit (callPackage (self: with self; lispMultiDerivation rec {
    version = "v2.1.1";
    src = pkgs.fetchFromGitHub {
      name = "cl-ppcre-src";
      owner = "edicl";
      repo = "cl-ppcre";
      rev = version;
      sha256 = "sha256-UffzJ2i4wpkShxAJZA8tIILUbBZzbWlseezj2JLImzc=";
    };
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

  cl-prevalence = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-prevalence";
    src = pkgs.fetchFromGitHub {
      owner = "40ants";
      repo = "cl-prevalence";
      name = "cl-prevalence-src";
      rev = "e6b27640ce89ae5f8af38beb740e319bb6cd2368";
      sha256 = "4F6NNyRVd2GVvnXEDXXppWTCbNVwQwyvKfdBveMpadE=";
    };
    lispDependencies = [
      moptilities
      s-xml
      s-sysdeps
    ];
    lispCheckDependencies = [ fiveam find-port ];
  }) {};

  cl-qrencode = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-qrencode";
    src = pkgs.fetchFromGitHub {
      owner = "jnjcc";
      repo = "cl-qrencode";
      name = "cl-qrencode-src";
      rev = "0de2d8a3877b499a9a0bbb0a9e1247056ae4311e";
      sha256 = "uc/qh+eqJcWFbzMoPG4AF6QTxlG4I4UkM25B1sIIs9A=";
    };
    lispDependencies = [ zpng ];
    lispCheckDependencies = [ lisp-unit ];
  }) {};

  cl-quickcheck = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    owner = "mcandre";
    repo = "cl-quickcheck";
    name = "cl-quickcheck-src";
    rev = "a76e360f0ead6809269b06221492fb7b3bfc8169";
    sha256 = "wCzt4zfwsB28sgZFJ/HWtjODE1a9+9/wmG3TCdvq3jE=";
  })) {};

  cl-redis = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-redis";
    lispDependencies = [
      babel
      cl-ppcre
      flexi-streams
      rutils
      usocket
    ];
    lispCheckDependencies = [ bordeaux-threads should-test ];
    src = pkgs.fetchFromGitHub {
      owner = "vseloved";
      repo = "cl-redis";
      name = "cl-redis-src";
      rev = "7d592417421cf7cd1cffa96043b457af0490df7d";
      sha256 = "cSMnapc92NBgoUkFx8pNOYcKoWZesmF9XGd0VlaHqnQ=";
    };
  }) {};

  cl-slice = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-slice";
    src = pkgs.fetchFromGitHub {
      owner = "tpapp";
      repo = "cl-slice";
      name = "cl-slice-src";
      rev = "c531683f287216aebbb0affbe090611fa1b5d697";
      sha256 = "lLH2jnDGllr7W5Az14io8OOAhNxMDhPsMqrR4omzf/k=";
    };
    lispDependencies = [ alexandria anaphora let-plus ];
    lispCheckDependencies = [ clunit ];
  }) {};

  cl-speedy-queue = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "cl-speedy-queue-src";
    owner = "zkat";
    repo = "cl-speedy-queue";
    rev = "0425c7c62ad3b898a5ec58cd1b3e74f7d91eec4b";
    sha256 = "sha256-OGaqhBkHKNUwHY3FgnMbWGdsUfBn0QDTl2vTZPu28DM=";
  })) {};

  cl-strings = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-strings";
    src = pkgs.fetchFromGitHub {
      owner = "diogoalexandrefranco";
      repo = "cl-strings";
      name = "cl-strings-src";
      rev = "93ec4177fc51f403a9f1ef0a8933f36d917f2140";
      sha256 = "UpXjI9KsWvOhsjGSo1zVMNlD1I4Pwu9+cZoD60jREMk=";
    };
    lispCheckDependencies = [ prove ];
  }) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      name = "cl-syntax-src";
      owner = "m2ym";
      repo = "cl-syntax";
      rev = "03f0c329bbd55b8622c37161e6278366525e2ccc";
      sha256 = "sha256-nlD/ziiKCdFfMzcxxyE30CmeAuJo9zDoU1qdczuyKp8=";
    };

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

  cl-tld = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    owner = "1u4nx";
    repo = "cl-tld";
    name = "cl-tld-src";
    rev = "b6b24d9c63da77052775992463f0bfac63383234";
    sha256 = "5jbUt+yTUz0OkWbLw+UZ6TSRH4cav84cecVGkW44pPY=";
  })) {};

  cl-tls = callPackage (self: with self; lispify [ ironclad alexandria fast-io cl-base64 ] (pkgs.fetchFromGitHub {
    owner = "shrdlu68";
    repo = "cl-tls";
    name = "cl-tls-src";
    rev = "2ab4fc3ae7e79e451126a9bb6bc38ca2cd2cb4ba";
    sha256 = "Ry1Q+UPY3h2hOB8tYB7+LYHLHyel9h5aN3OuGMTmz8g=";
  })) {};

  cl-unicode = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-unicode";
    src = pkgs.fetchFromGitHub {
      name = "cl-unicode-src";
      owner = "edicl";
      repo = "cl-unicode";
      rev = "v0.1.6";
      sha256 = "sha256-6kPg5c5k9KKRUZms0GRiLrQfBR0zgn7DJYc6TJMWfXo=";
    };
    lispDependencies = [ cl-ppcre flexi-streams ];
  }) {};

  # The official location for this source is
  # "https://www.common-lisp.net/project/cl-utilities/cl-utilities-latest.tar.gz"
  # but I’m not a huge fan of including a "latest.tar.gz" in a Nix
  # derivation. That being said: it hasn’t been changed since 2006, so maybe
  # that is a better resource.
  cl-utilities = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-utilities";
    src = fetchDebianPkg {
      pname = "cl-utilities";
      version = "1.2.4";
      sha256 = "sha256-/CAF/qaLjd3t9P+0eSGoC18f3MJT1dB94VLUjnKbq7Y";
    };
  }) {};

  cl-who = callPackage (self: with self; lispDerivation {
    lispSystem = "cl-who";
    src = pkgs.fetchFromGitHub {
      name = "cl-who-src";
      owner = "edicl";
      repo = "cl-who";
      rev = "07dafe9b351c32326ce20b5804e798f10d4f273d";
      sha256 = "sha256-5T762W3qetAjXtHP77ko6YZR6w5bQ04XM6QZPELQu+U=";
    };
    lispCheckDependencies = [ flexi-streams ];
  }) {};

  inherit (callPackage (self: with self;
    lispMultiDerivation {
      src = pkgs.fetchFromGitHub {
        name = "clack-src";
        owner = "fukamachi";
        rev = "488cfb36381a4f4c56ad7f1184ea64b6ebcc2cee";
        sha256 = "ERAzpClsqO0xJ4MREnYpsmiodVeeYA7Fi2BL1P5/ffc=";
        repo = "clack";
      };

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

  closer-mop = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "closer-mop-src";
    repo = "closer-mop";
    owner = "pcostanza";
    rev = "477423a9020a4c848e31a62967ea8762b3aa7be7";
    sha256 = "Ph7v6DmFv64JG71fEDPR0vExWuh6NnvBJK2spBLTFgQ=";
  })) {};

  clss = callPackage (self: with self; lispify [ array-utils plump ] (pkgs.fetchFromGitHub {
    name = "clss-src";
    repo = "clss";
    owner = "Shinmera";
    rev = "f62b849189c5d1be378f0bd3d403cda8d4fe310b";
    sha256 = "sha256-24XWonW5plv83h9Sule6q6nEFUAZOlxofwxadSFrY4A=";
  })) {};

  clunit = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    owner = "tgutu";
    repo = "clunit";
    name = "clunit-src";
    rev = "6f6d72873f0e1207f037470105969384f8380628";
    sha256 = "BUGiep0Sm7s4rFMqCH9b19AQx6r3V5xXRhHSj20XrsU=";
  })) {};

  clunit2 = callPackage (self: with self; lispify [ ] (pkgs.fetchzip rec {
    pname = "clunit2-src";
    version = "200839e8e47e9212ded2d36520d84b9be681037c";
    url = "https://notabug.org/cage/clunit2/archive/${version}.tar.gz";
    sha256 = "sha256-5Pud/s5LywqrY+EjDG2iCtuuildTzfDmVYzqhnJ5iyQ=";
  })) {};

  collectors = callPackage (self: with self; lispDerivation {
    lispSystem = "collectors";
    lispDependencies = [ alexandria closer-mop symbol-munger ];
    lispCheckDependencies = [ lisp-unit2 ];
    src = pkgs.fetchFromGitHub {
      owner = "AccelerationNet";
      repo = "collectors";
      name = "collectors-src";
      rev = "748f0a1613ce161edccad4cc815eccd7fc55aaf3";
      sha256 = "K14tHE/klD3vX/Llaw5uUU1sSLswOpVGk4tLgfnBrNc=";
    };
  }) {};

  colorize = callPackage (self: with self; lispify [ alexandria html-encode split-sequence ] (pkgs.fetchFromGitHub {
    name = "colorize-src";
    repo = "colorize";
    owner = "kingcons";
    rev = "f5ed4b342c40257178ebe176108792c01d2e1187";
    sha256 = "zrtxCmLEAz0xclLaxXo4T7O8vbHYGEbsmCoSDV8Ib70=";
  })) {};

  common-doc = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "CommonDoc";
      repo = "common-doc";
      name = "common-doc-src";
      rev = "bcde4cfee3d34482d9830c8f9ea45454c73cf5aa";
      sha256 = "Sjnwj/rX8OK5JXFWApryqGBr9Iy/7xLaXLVgdgYn7C8=";
    };
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

  common-html = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "CommonDoc";
      repo = "common-html";
      name = "common-html-src";
      rev = "96987bd9db21639ed55d1b7d72196f9bc58243fd";
      sha256 = "vwcM5yHeUG36NC9j63nSAjLoZra5K7ti+cvbkijhIcQ=";
    };
    lispSystems = ["common-html"];
    lispDependencies = [ common-doc plump anaphora alexandria ];
    lispCheckDependencies = [ fiveam ];
  }) {};

  commondoc-markdown = callPackage (self: with self; lispDerivation {
    lispSystem = "commondoc-markdown";
    src = pkgs.fetchFromGitHub {
      owner = "40ants";
      repo = "commondoc-markdown";
      name = "commondoc-markdown-src";
      rev = "f428652528441d1133a3b5928c161c07fd740e7a";
      sha256 = "p5dKYXRaIHTHBkuIndrCgd9TfnTBg9P2LN36VJ94Exw=";
    };
    lispDependencies = [
      _3bmd
      _3bmd-ext-code-blocks
      common-doc
      common-html
      str
      ironclad
      f-underscore
    ];
    lispCheckDependencies = [ hamcrest rove ];
  }) {};

  concrete-syntax-tree = callPackage (self: with self; lispDerivation {
    lispDependencies = [ acclimation ];
    src = pkgs.fetchFromGitHub {
      owner = "robert-strandh";
      repo = "Concrete-Syntax-Tree";
      name = "Concrete-Syntax-Tree-src";
      rev = "37291727196a3bc88a7be67c1427c52078d4b82c";
      sha256 = "+2XSZ/UTTB9ddqWfIOaJTEgGCGLI1xRpEOkLqLGXCZc=";
    };
    lispSystem = "concrete-syntax-tree";
    lispAsdPath = [ "Lambda-list" ];
    preBuild = ''
      echo '(:source-registry-cache ' > .cl-source-registry.cache
      find . -name '*.asd' -exec printf '"%s" ' {} \; >> .cl-source-registry.cache
      echo ')' >> .cl-source-registry.cache
    '';
  }) {};

  data-lens = callPackage (self: with self; lispDerivation {
    lispDependencies = [ cl-ppcre alexandria serapeum ];
    lispSystems = [ "data-lens" "data-lens/beta/transducers" ];
    lispCheckDependencies = [ fiveam string-case ];
    src = pkgs.fetchFromGitHub {
      owner = "fiddlerwoaroof";
      repo = "data-lens";
      name = "data-lens-src";
      rev = "903c0aaceddb4012e76324bfba0245f387f09922";
      sha256 = "DY7wRGggVRjAJON8L+eX2nVcM4PVibPRHiX8jD/7eBM=";
    };
  }) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "fukamachi";
      repo = "cl-dbi";
      name = "cl-dbi-src";
      rev = "3d4b48c7b6736a4257043cde60687614775714d6";
      sha256 = "oDSwNPljs0PUGlftI24yALzdbMZhepLG1VmdVX7scE4=";
    };

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

  deflate = callPackage (self: with self; lispify [] (pkgs.fetchFromGitHub {
    owner = "pmai";
    repo = "Deflate";
    name = "Deflate-src";
    rev = "fb940e63b89a6c4d168153dbf046552e106eb8a5";
    sha256 = "usXImjvntDb5zrEUtJIWRUeRbNcigzMhaoIzA7uV7co=";
  })) {};

  dexador = callPackage (self: with self; lispDerivation {
    lispSystem = "dexador";
    src = pkgs.fetchFromGitHub {
      name = "dexador-src";
      repo = "dexador";
      owner = "fukamachi";
      rev = "138b08abcfef3c5723f810617c2a1da6b99123b7";
      sha256 = "hOtIVP1U+a4etCcdIrGC7cAVoBSaryaF7CthmszOcFI=";
    };
    lispDependencies = [
      alexandria
      babel
      bordeaux-threads
      chipz
      chunga
      cl-base64
      cl-cookie
      cl-plus-ssl
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

  dissect = callPackage (self: with self; lispDerivation {
    lispSystem = "dissect";
    src = pkgs.fetchFromGitHub {
      name = "dissect-src";
      owner = "Shinmera";
      repo = "dissect";
      rev = "6c15c887a8d3db2ce83037ff31f8a0b528aa446b";
      sha256 = "sha256-px1DT8MRzeqEwsV/sJBJHrlsHrWEDQopfGzuHc+QqoE=";
    };
    lispDependencies = l.optional ((lisp.pname or "") == "clisp") cl-ppcre;
  }) {};

  djula = callPackage (self: with self; lispDerivation {
    lispSystem = "djula";
    src = pkgs.fetchFromGitHub {
      owner = "mmontone";
      repo = "djula";
      name = "djula-src";
      rev = "cd2c9e33d4ee265597f4cc9eab2f23bc0640f2b5";
      sha256 = "ZKoCEZ9nVrzJKnQii1e6hK/dlTqgzxIwQeYMZH9e+ZI=";
    };
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

  dns-client = callPackage (self: with self; lispify [ punycode usocket documentation-utils ] (pkgs.fetchFromGitHub {
    name = "dns-client-src";
    owner = "Shinmera";
    repo = "dns-client";
    rev = "8d8d440e9454d629f7bb78491ead2237f5b54add";
    sha256 = "F858VVGq9m9uh1ZDJw2vlX3bjVDQ7F9GpxYmlIOB6OQ=";
  })) {};

  # Technically these could be two separate derivations, one per system, but it
  # doesn’t seem like people use it that way, and there’s no dependencies
  # anyway, so there’s little benefit. Just treat this as a monolith package.
  docs-builder = callPackage (self: with self; lispDerivation {
    lispSystems = [ "docs-builder" "docs-config" ];
    src = pkgs.fetchFromGitHub {
      owner = "40ants";
      repo = "docs-builder";
      name = "docs-builder-src";
      rev = "13dcd12a2b02cc1575148968d40cfaa794c66072";
      sha256 = "mHfgsxUws+SeUx2kCGOv3MdMlghQK7J5NsfpYaEyj4E=";
    };
    lispDependencies = [ log4cl _40ants-doc ];
  }) {};

  documentation-utils = callPackage (self: with self; lispDerivation {
    lispSystem = "documentation-utils";
    src = pkgs.fetchFromGitHub {
      name = "documentation-utils-src";
      repo = "documentation-utils";
      owner = "Shinmera";
      rev = "98630dd5f7e36ae057fa09da3523f42ccb5d1f55";
      sha256 = "sha256-uMUyzymyS19ODiUjQbE/iJV7HFeVjB45gbnWqfGEGCU=";
    };
    lispDependencies = [ trivial-indent ];
  }) {};

  drakma = callPackage (self: with self; lispDerivation {
    lispSystem = "drakma";
    src = pkgs.fetchFromGitHub {
      name = "drakma-src";
      owner = "edicl";
      repo = "drakma";
      rev = "v2.0.9";
      sha256 = "sha256-sKrtgEH65Vps/27GKgXjHBMI0OJgmgxg5Tg3lHNyufg=";
    };
    lispDependencies = [
      chipz
      chunga
      cl-base64
      cl-plus-ssl
      cl-ppcre
      flexi-streams
      puri
      usocket
    ];
    lispCheckDependencies = [ fiveam ];
  }) {};

  dynamic-classes = callPackage (self: with self; lispDerivation {
    lispSystem = "dynamic-classes";
    src = pkgs.fetchFromGitHub {
      owner = "gwkkwg";
      repo = "dynamic-classes";
      name = "dynamic-classes-src";
      rev = "844b077e5ac5ef2127603e692af983e9952ebae9";
      sha256 = "sivl+wrjb/9ToYxdH7AenmhpQb9JFsykKQFr2M1/XGk=";
    };
    lispDependencies = [ metatilities-base ];
    lispCheckDependencies = [ lift ];
  }) {};

  eager-future2 = callPackage (self: with self; lispify [ bordeaux-threads trivial-garbage ] (pkgs.fetchFromGitLab {
    name = "eager-future2-src";
    domain = "gitlab.common-lisp.net";
    owner = "vsedach";
    repo = "eager-future2";
    rev = "54df8effd9d9eccac917509590286b5ac5f9cb30";
    sha256 = "sha256-jeaCSUn0gszAGmqo9FJLWQjoM+vUafhZoShOUMdeQeM";
  })) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "robert-strandh";
      repo = "eclector";
      name = "eclector-src";
      rev = "32b74ad959bd5b2773f27ecc6e62c2b167bf6626";
      sha256 = "HpyJo06FGVk/I66w2u5wSbh3FxovDskSpTVydeJeqyE=";
    };
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

  enchant = callPackage (self: with self; lispDerivation {
    lispDependencies = [ cffi ];
    lispSystem = "enchant";
    src = pkgs.fetchFromGitHub {
      owner = "tlikonen";
      repo = "cl-enchant";
      name = "cl-enchant-src";
      rev = "b26850625b73c4b6f0edceb60b8d81cf130c525e";
      sha256 = "6UBJW+o6G3CF3m52yp1wqijNUC0H52SoLMeTN8hBC7Q=";
    };
  }) {};

  eos = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "eos-src";
    owner = "adlai";
    repo = "Eos";
    rev = "b4413bccc4d142cbe1bf49516c3a0a22c9d99243";
    sha256 = "sha256-E9p5yKay3nyGWxmOeQTpfA51B2X+EUD+9yd1S+um1Kk=";
  })) {};

  esrap = callPackage (self: with self; lispDerivation {
    lispSystem = "esrap";
    src = pkgs.fetchFromGitHub {
      name = "esrap-src";
      owner = "scymtym";
      repo = "esrap";
      rev = "d806138342a6b27327649fd5f36e0fe2e0966867";
      sha256 = "dPo43lWITpe0TC42ZHBVC9FFsHgdg0ktjAo2WpWrQD8=";
    };
    lispDependencies = [ alexandria trivial-with-current-source-form ];
    lispCheckDependencies = [ fiveam ];
  }) {};

  f-underscore = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitLab {
    name = "f-underscore-src";
    domain = "gitlab.common-lisp.net";
    owner = "bpm";
    repo = "f-underscore";
    rev = "7988171194cd259e12469dd7c30000be6ef1b31a";
    sha256 = "sha256-ZVkb87TCDSRU4fXg7gRAYrwY3EO3aiPpAR4B1bNYG1c=";
  })) {};

  fast-http = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      name = "fast-http-src";
      repo = "fast-http";
      owner = "fukamachi";
      rev = "502a37715dcb8544cc8528b78143a942de662c5a";
      sha256 = "sha256-sZo0osVlmeOwFfoVrYrvTL1L47pDrOO0pFKmIN55gio=";
    };
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

  fast-io = callPackage (self: with self; lispify [
    alexandria
    static-vectors
    trivial-gray-streams
  ] (pkgs.fetchFromGitHub {
    name = "fast-io-src";
    owner = "rpav";
    repo = "fast-io";
    rev = "a4c5ad600425842e8b6233b1fa22610ffcd874c3";
    sha256 = "sha256-YBTROnJyB8w3H+GDhlHI+6n7XvnyoGN+8lDh9ZQXAHI=";
  })) {};

  fare-mop = callPackage (self: with self; lispify [
    closer-mop
    fare-utils
  ] (pkgs.fetchFromGitHub {
    name = "fare-mop-src";
    owner = "fare";
    repo = "fare-mop";
    rev = "538aa94590a0354f382eddd9238934763434af30";
    sha256 = "sha256-LGx/Te7RgHr9zuSRe2OXHa5WRbX8G6UsdKMkkQbSXVU=";
  })) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      name = "fare-quasiquote-src";
      owner = "fare";
      repo = "fare-quasiquote";
      rev = "ccb0285b456c4d6bb09b9f931cf0ac5e72353ae5";
      sha256 = "sha256-9tCP0IqU4TDmt0sUb3oJgTVC2DlfI4y7LdhsCfrglQw=";
    };
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

  fare-utils = callPackage (self: with self; lispDerivation {
    lispSystem = "fare-utils";
    src = pkgs.fetchFromGitHub {
      name = "fare-utils-src";
      owner = "fare";
      repo = "fare-utils";
      rev = "2f9c48a23a5c0802566d869d73a58471c05e63f1";
      sha256 = "Eye1XJUNWhptVlkukrwVmYL9dKpyrn8PJEdMDPntYzw=";
    };
    lispCheckDependencies = [ hu_dwim_stefil ];
  }) {};

  # I’m defining this as a multideriv because it exposes lots of derivs. Even
  # though I only use one at the moment, it’s likely to change in the future.
  inherit (callPackage (self: with self; lispMultiDerivation {
    src = let
      rev = "9084944079736eac085494523a41c8265d4671b7";
      repo = "femlisp";
    in
      pkgs.fetchzip {
        name = "femlisp-src";
        url = "https://git.savannah.nongnu.org/cgit/${repo}.git/snapshot/${repo}-${rev}.tar.gz";
        sha256 = "sha256-SqsbPY7OD+mk8Fc0WDxLqFh0GGoychIqgtDtgWXogiI=";
      };
    systems = {
      infix = {};
    };
    dontConfigure = true;
    lispAsdPath = systems:
      l.optional (builtins.elem "infix" systems) "external/infix";
  }) {}) infix;

  fiasco = callPackage (self: with self; lispify [ alexandria trivial-gray-streams ] (pkgs.fetchFromGitHub {
    name = "fiasco-src";
    owner = "capitaomorte";
    repo = "fiasco";
    rev = "bb47d2fef4eb24cc16badc1c9a73d73c3a7e18f5";
    sha256 = "XB0VGAIkmoVf7PSt1wgIDYJRGu36uj/8XgGIU/AUEc0=";
  })) {};

  find-port = callPackage (self: with self; lispDerivation {
    lispSystem = "find-port";
    lispCheckDependencies = [ fiveam ];
    lispDependencies = [ usocket ];
    src = pkgs.fetchFromGitHub {
      owner = "eudoxia0";
      repo = "find-port";
      name = "find-port-src";
      rev = "666040f72abda155a87576652f0e0fae98b27c13";
      sha256 = "J5Za5qJ8FXSP/LnjVHs6J13tZ/88r/rKAaea+RWeq8I=";
    };
  }) {};

  fiveam = callPackage (self: with self; lispify [ alexandria asdf-flv trivial-backtrace ] (pkgs.fetchFromGitHub {
    name = "fiveam-src";
    owner = "lispci";
    repo = "fiveam";
    rev = "v1.4.2";
    sha256 = "sha256-ktwyRdDG3Z0KOnM0C8lbq7ZAZVqozTbwkiUsWuktsBI=";
  })) {};

  float-features = callPackage (self: with self; lispDerivation {
    lispSystem = "float-features";
    src = pkgs.fetchFromGitHub {
      name = "float-features-src";
      repo = "float-features";
      owner = "Shinmera";
      rev = "09684979127856ea3ad8acc8a1e53143e6557d27";
      sha256 = "IDqMj91A48LRjCOeH//4ybpo8PIo64Fp6i68KEHPjho=";
    };
    lispDependencies = [ documentation-utils ];
    lispCheckDependencies = [ parachute ];
  }) {};

  flexi-streams = callPackage (self: with self; lispify [ trivial-gray-streams ] (pkgs.fetchFromGitHub {
    name = "flexi-streams-src";
    owner = "edicl";
    repo = "flexi-streams";
    rev = "v1.0.19";
    sha256 = "sha256-4GRKx0BrVtO6CjsSEal2/MzeXK+bel5J++w3mi2B9Gw=";
  })) {};

  form-fiddle = callPackage (self: with self; lispDerivation {
    lispSystem = "form-fiddle";
    src = pkgs.fetchFromGitHub {
      name = "form-fiddle-src";
      repo = "form-fiddle";
      owner = "Shinmera";
      rev = "e0c23599dbb8cff3e83e012f3d86d0764188ad18";
      sha256 = "sha256-lsqBiHT6nYizomy8ZNe+Yq2btB8Jla0Bzd7dmpj9MRA=";
    };
    lispDependencies = [ documentation-utils ];
  }) {};

  fset = callPackage (self: with self; lispify [ misc-extensions mt19937 named-readtables ] (pkgs.fetchFromGitHub {
    name = "fset-src";
    owner = "slburson";
    repo = "fset";
    rev = "69c209e6eb15187da04f70ece3f800a6e3cc8639";
    sha256 = "sha256-XqPr1MK8rZvz+f+cumVoX/RynfMhsJnXhrSBxZQqSJQ=";
  })) {};

  garbage-pools = lispDerivation {
    lispSystem = "garbage-pools";
    src = pkgs.fetchFromGitHub {
      owner = "archimag";
      repo = "garbage-pools";
      name = "garbage-pools-src";
      rev = "9a7cb7f48b04197c0495df3b6d2e8395ad13f790";
      sha256 = "YRenK0wQuWkFWAr3MGSRflNSv+TZEsZNjRCNIE3mWBI=";
    };
    lispCheckDependencies = [ lift ];
  };

  gettext = callPackage (self: with self; lispDerivation {
    lispSystem = "gettext";
    src = pkgs.fetchFromGitHub {
      owner = "rotatef";
      repo = "gettext";
      name = "gettext-src";
      rev = "a432020cbad99fc22cbe6bb9aa8a83a35000d7aa";
      sha256 = "WZXXPxrCypuHhXCPnDOl7KZiahuL7rVMhGWaaF9V8N8=";
    };
    lispDependencies = [ split-sequence yacc flexi-streams ];
    lispCheckDependencies = [ stefil ];
    preCheck = ''
      export CL_SOURCE_REGISTRY="$PWD/gettext-tests:$CL_SOURCE_REGISTRY"
    '';
  }) {};

  global-vars = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "global-vars-src";
    owner = "lmj";
    repo = "global-vars";
    rev = "c749f32c9b606a1457daa47d59630708ac0c266e";
    sha256 = "sha256-bXxeNNnFsGbgP/any8rR3xBvHE9Rb4foVfrdQRHroxo=";
  })) {};

  hamcrest = callPackage (self: with self; lispDerivation {
    lispSystem = "hamcrest";
    lispCheckDependencies = [ prove rove ];
    lispDependencies = [
      _40ants-asdf-system
      alexandria
      iterate
      cl-ppcre
      split-sequence
    ];
    src = pkgs.fetchFromGitHub {
      owner = "40ants";
      repo = "cl-hamcrest";
      name = "hamcrest-src";
      rev = "9abb4978271907e11c21411ba350b0d6d7d9cb12";
      sha256 = "VY8QTbXnkxCagKrwv+kjuPF4jhHK8N6oaPjKxOb+rFQ=";
    };
  }) {};

  history-tree = callPackage (self: with self; lispDerivation {
    lispDependencies = [
      alexandria
      cl-custom-hash-table
      local-time
      nasdf
      nclasses
      trivial-package-local-nicknames
    ];
    src = pkgs.fetchFromGitHub {
      owner = "atlas-engineer";
      repo = "history-tree";
      name = "history-tree-src";
      rev = "c1ae76ff4b162e003b4a314666976d9133e6804a";
      sha256 = "lOORalyTybdut/If+dBXS4PlZt2AnZrEI/qjQWS03pk=";
    };
    lispCheckDependencies = [ lisp-unit2 ];
    lispSystem = "history-tree";
  }) {};

  http-body = callPackage (self: with self; lispDerivation {
    lispSystem = "http-body";
    src = pkgs.fetchFromGitHub {
      name = "http-body-src";
      owner = "fukamachi";
      repo = "http-body";
      rev = "3e4bedd6a9d9bc4e1dc0a45e5b55360ae30fd388";
      sha256 = "sha256-4n/aq/OntjQEzSaJTl8Rv8QJMBpJstTiz40cU+ggj00=";
    };
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

  html-encode = callPackage (self: with self; lispify [ ] (pkgs.fetchzip rec {
    pname = "html-encode-src";
    version = "1.2";
    url = "http://beta.quicklisp.org/orphans/html-encode-${version}.tgz";
    sha256 = "sha256-qw2CstJIDteQC4N1eQEsD9+HRm1i9GP/XjjIZXtZr/k=";
  })) {};

  html-entities = callPackage (self: with self; lispDerivation {
    lispSystem = "html-entities";
    src = pkgs.fetchFromGitHub {
      owner = "BnMcGn";
      repo = "html-entities";
      rev = "4af018048e891f41d77e7d680ed3aeb639e1eedb";
      sha256 = "2dkxvAPlweCb34Yyp9oySbF4bgFFF0v8CTpu46ihXqw=";
    };
    lispDependencies = [ cl-ppcre ];
    lispCheckDependencies = [ fiveam ];
  }) {};

  hu_dwim_asdf = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "hu.dwim.asdf-src";
    owner = "hu-dwim";
    repo = "hu.dwim.asdf";
    rev = "2017-04-07";
    sha256 = "sha256-7U72ZSEtUZc0HSFhq6tRQP5RRxxzpe2NXaUND/UEbS0=";
  })) {};

  hu_dwim_stefil = callPackage (self: with self; lispify [ alexandria hu_dwim_asdf ] (pkgs.fetchFromGitHub {
    name = "hu.dwim.stefil-src";
    owner = "hu-dwim";
    repo = "hu.dwim.stefil";
    rev = "2017-04-07";
    sha256 = "sha256-Ka3OO+cyafx0bcM9bdhZN2pHWjnVq116bU1mPS3ClSQ=";
  })) {};

  hunchentoot = callPackage (self: with self; lispDerivation {
    lispSystem = "hunchentoot";
    src = pkgs.fetchFromGitHub {
      name = "hunchentoot-src";
      owner = "edicl";
      repo = "hunchentoot";
      rev = "v1.3.0";
      sha256 = "sha256-ydfIWhBVRTvfBjHejyGVdYk28JCPEJrMS2Vnc2khFfw=";
    };
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
      cl-plus-ssl
      usocket
      bordeaux-threads
    ];
    lispCheckDependencies = [
      cl-ppcre
      cl-who
      drakma
    ];
  }) {};

  idna = callPackage (self: with self; lispify [ split-sequence ] (pkgs.fetchFromGitHub {
    owner = "antifuchs";
    repo = "idna";
    name = "idna-src";
    rev = "bf789e6029b695ecba635964deac38130f55c7b4";
    sha256 = "QpUK5znagLTN4d7GMiAmOiRj1DWhpfdIwBR25+rIywI=";
  })) {};

  ieee-floats = callPackage (self: with self; lispDerivation {
    lispSystem = "ieee-floats";
    src = pkgs.fetchFromGitHub {
      name = "ieee-floats-src";
      owner = "marijnh";
      repo = "ieee-floats";
      rev = "9566ce8adfb299faef803d95736c780413a1373c";
      sha256 = "sha256-7fD+0p1MunjjZ3GJANypsufM2XYAWsSqk81+mXBv4mI=";
    };
    lispCheckDependencies = [ fiveam ];
  }) {};

  inferior-shell = callPackage (self: with self; lispDerivation {
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
    src = pkgs.fetchFromGitHub {
      name = "inferior-shell-src";
      owner = "fare";
      repo = "inferior-shell";
      rev = "15c2d04a7398db965ea1c3ba2d49efa7c851f2c2";
      sha256 = "sha256-lUj2tqRhmXWwgK3Qio1U+9vNhcJingN57USW+f8ZHQs=";
    };
  }) {};

  infix-math = callPackage (self: with self; lispify [ alexandria serapeum wu-decimal parse-number ] (pkgs.fetchFromGitHub {
    owner = "ruricolist";
    repo = "infix-math";
    name = "infix-math-src";
    rev = "f5155ae9709e518061ace79887d78f8e79c61cac";
    sha256 = "bzW/xsvDqmw6XXkhdw7xNX4zS/JFUTyw4yMd2kkR18A=";
  })) {};

  introspect-environment = callPackage (self: with self; lispDerivation {
    lispSystem = "introspect-environment";
    lispCheckDependencies = [ fiveam ];
    src = pkgs.fetchFromGitHub {
      name = "introspect-environment-src";
      owner = "Bike";
      repo = "introspect-environment";
      rev = "8fb20a1a33d29637a22943243d1482a20c32d6ae";
      sha256 = "sha256-Os0XnUtgq+zqpPT9UyLecXEHSVY+MsCTKIfUGLKViNw=";
    };
  }) {};

  ironclad = callPackage (self: with self; lispDerivation {
    lispSystem = "ironclad";
    src = pkgs.fetchFromGitHub {
      name = "ironclad-src";
      owner = "sharplispers";
      repo = "ironclad";
      rev = "v0.58";
      sha256 = "sha256-KCLl7zcnpapHZoPQcxTWeorQE5Hat1jPK4IET4J69J4=";
    };
    lispDependencies = [ bordeaux-threads ];
    lispCheckDependencies = [ rt ];
  }) {};

  iterate = callPackage (self: with self; lispDerivation {
    lispSystem = "iterate";
    src = pkgs.fetchFromGitLab {
      name = "iterate-src";
      domain = "gitlab.common-lisp.net";
      owner = "iterate";
      repo = "iterate";
      rev = "1.5.3";
      sha256 = "sha256-giEXCF+9q5fcCmE3Q6NDCq+rV6+qcglArJdf9q5D1FA=";
    };
    lispCheckDependencies = l.optional ((lisp.pname or "") != "sbcl") rt;
  }) {};

  jonathan = callPackage (self: with self; lispDerivation {
    lispSystem = "jonathan";
    src = pkgs.fetchFromGitHub {
      name = "jonathan-src";
      owner = "Rudolph-Miller";
      repo = "jonathan";
      rev = "fb83ff094d330b2208b0febc8b25983c6050e378";
      sha256 = "sha256-z+p8Hj1eAS148KomWkX5yPvAqf4zfr3m1ivKWF13mtA=";
    };
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

  jpl-queues = callPackage (self: with self; lispDerivation rec {
    lispSystem = "jpl-queues";
    lispDependencies = [ bordeaux-threads jpl-util ];
    pname = "jpl-queues";
    version = "0.1";
    src = pkgs.fetchzip {
      inherit version;
      pname = "jpl-queues-src";
      url = "https://www.thoughtcrime.us/software/jpl-queues/jpl-queues-${version}.tar.gz";
      sha256 = "sha256-CMl5j4uzTlP6SSSm6Z3gKHZdhyRgMNqqZCC/oJxu7fU=";
    };
  }) {};

  jpl-util = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "hawkir";
      repo = "cl-jpl-util";
      name = "cl-jpl-util-src";
      rev = "0311ed374e19a49d43318064d729fe3abd9a3b62";
      sha256 = "34sG/rvzPGQEibNnp4VtrbIKORlc90LAeDM/ZNPMgFk=";
    };
    lispSystem = "jpl-util";
  }) {};

  json-streams = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "rotatef";
      repo = "json-streams";
      name = "json-streams-src";
      rev = "5da012e8133affbf75024e7500feb37394690752";
      sha256 = "gtI+OMlqppGHRpAoPMC/j16NGkKmTdfGwQTUGMQZKjI=";
    };
    lispSystem = "json-streams";
    lispCheckDependencies = [ cl-quickcheck flexi-streams ];
  }) {};

  kmrcl = callPackage (self: with self; lispDerivation rec {
    lispSystem = "kmrcl";
    version = "4a27407aad9deb607ffb8847630cde3d041ea25a";
    src = fetchKpePkg {
      inherit version;
      name = "kmrcl";
      sha256 = "sha256-oq28Xy1NrL/v4cipw4sObu3YkDBIAo0OR8wWqCoB/Rk=";
    };
    lispCheckDependencies = [ rt ];
  }) {};

  inherit (callPackage (self: with self;
    lispMultiDerivation {
      src = pkgs.fetchFromGitHub {
        repo = "lack";
        owner = "fukamachi";
        name = "lack-src";
        rev = "c2edb842247ced0071dc21987f97629575667fe8";
        sha256 = "vxeGBjOrbL/BmPEU4m99odUukJ7B6j44zCOqndYzTTU=";
      };
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
          lispDependencies =
            if pkgs.hostPlatform.isWindows
            then [ ironclad ]
            else [ cl-isaac ];
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

  lass = callPackage (self: with self; lispDerivation {
    lispSystems = [ "lass" "binary-lass" ];
    lispDependencies = [ trivial-indent trivial-mimes cl-base64 ];
    src = pkgs.fetchFromGitHub {
      owner = "Shinmera";
      repo = "LASS";
      name = "LASS-src";
      rev = "aa6e1e426bc992ce0178f19a934359d582749d8e";
      sha256 = "eCDkagN5V5vIeNIxxGNiC79LIt87JCG4CdCyqCxrnPc=";
    };
  }) {};

  legion = callPackage (self: with self; lispDerivation {
    lispSystem = "legion";
    src = pkgs.fetchFromGitHub {
      name = "legion-src";
      owner = "fukamachi";
      repo = "legion";
      rev = "599cca19f0e34246814621f7fe90322221c2e263";
      sha256 = "sha256-JmrSMxvpud5vQ3AFiwRGdDrOPs1dcEFkI20hVwG/AxU=";
    };
    lispDependencies = [
      vom
      # Not listed in the .asd but these are required
      bordeaux-threads
      cl-speedy-queue
    ];
    lispCheckDependencies = [ local-time prove ];
  }) {};

  let-plus = callPackage (self: with self; lispDerivation {
    lispSystem = "let-plus";
    lispCheckDependencies = [ lift ];
    lispDependencies = [ alexandria anaphora ];
    src = pkgs.fetchFromGitHub {
      name = "let-plus-src";
      owner = "tpapp";
      repo = "let-plus";
      rev = "7cf18b29ed0fe9c667a9a6a101b08ab9661a59e9";
      sha256 = "sha256-DhRC8uN5Aq5hAy0wJnuu+ktSX1RSQFXHmK1J3gpYw/c=";
    };
  }) {};

  lift = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "lift-src";
    owner = "gwkkwg";
    repo = "lift";
    rev = "979e1e7270bc2facc783a28f85dffe8dadb6ebfc";
    sha256 = "6+nxCJTTV6evgk397domqP1SzcRNNLbi/ak/PRxzB6I=";
  })) {};

  lisp-namespace = callPackage (self: with self; lispDerivation {
    lispSystem = "lisp-namespace";
    lispDependencies = [ alexandria ];
    lispCheckDependencies = [ fiveam ];
    src = pkgs.fetchFromGitHub {
      name = "lisp-namespace-src";
      owner = "guicho271828";
      repo = "lisp-namespace";
      rev = "699fccb6727027343bb5fca69162a3113996edfc";
      sha256 = "sha256-1/Sl03Kid+KgrQVYYwRvOU9XuFRo0Bv8VZCTpWpardw=";
    };
  }) {};

  lisp-unit = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    owner = "OdonataResearchLLC";
    repo = "lisp-unit";
    name = "lisp-unit-src";
    rev = "89653a232626b67400bf9a941f9b367da38d3815";
    sha256 = "Pqd7k08ZDvISuEVdGrokUy5xXfKJGdO2HWjck19tz1w=";
  })) {};

  lisp-unit2 = callPackage (self: with self; lispify [
    alexandria
    cl-interpol
    iterate
    symbol-munger
  ] (pkgs.fetchFromGitHub {
    owner = "AccelerationNet";
    repo = "lisp-unit2";
    name = "lisp-unit2-src";
    rev = "b5aa17b298cf2f669f4c0262c471e1ee4ab4699a";
    sha256 = "ySzQKSbsQjfVOksQNzQh2td+oICmD6iVwmP3YIWwFpA=";
  })) {};

  local-time = callPackage (self: with self; lispDerivation {
    lispSystem = "local-time";
    src = pkgs.fetchFromGitHub {
      name = "local-time-src";
      rev = "40169fe26d9639f3d9560ec0255789bf00b30036";
      repo = "local-time";
      owner = "dlowe-net";
      sha256 = "sha256-TwrL74zNmYA+gw1c4DcvSET6cL/mzOIq1P/jWf8Yd7U=";
    };
    lispCheckDependencies = [ hu_dwim_stefil ];
  }) {};

  log4cl = callPackage (self: with self; lispDerivation {
    lispSystem = "log4cl";
    src = pkgs.fetchFromGitHub {
      name = "log4cl-src";
      owner = "sharplispers";
      repo = "log4cl";
      rev = "fe3da517147d023029782ced7cd989ba24f1e62d";
      sha256 = "8/jWyw1+FTDWMIiQPaAsSumjEtfhKxQsoT7NMrxOIVg=";
    };
    lispDependencies = [ bordeaux-threads ];
    lispCheckDependencies = [ stefil ];
  }) {};

  log4cl-extras = callPackage (self: with self; lispDerivation {
    lispSystem = "log4cl-extras";
    lispCheckDependencies = [ hamcrest ];
    lispDependencies = [
      _40ants-doc
      _40ants-asdf-system
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
    src = pkgs.fetchFromGitHub {
      owner = "40ants";
      repo = "log4cl-extras";
      name = "log4cl-extras-src";
      rev = "920e5e551b116419aa82de46e4a8a0f787db7d82";
      sha256 = "Xl5Jj4BAyz1Fxh+MOLqbVl43M5JkIsutaTOFqhPUH1o=";
    };
  }) {};

  # Technically this package also contains a benchmark system with different
  # dependencies but I’m not going to bother exposing that to this scope.
  lparallel = callPackage (self: with self; lispify [ alexandria bordeaux-threads ] (pkgs.fetchFromGitHub {
    owner = "lmj";
    repo = "lparallel";
    name = "lparallel-src";
    rev = "9c11f40018155a472c540b63684049acc9b36e15";
    sha256 = "CfN9GsaW56v/c+wuSl0YSbDKyLQb8goV+BrntTL1Cjw=";
  })) {};

  lquery = callPackage (self: with self; lispDerivation {
    lispSystem = "lquery";
    src = pkgs.fetchFromGitHub {
      owner = "Shinmera";
      repo = "lquery";
      name = "lquery-src";
      rev = "c4f5568ee40498f0ee54fe52a4d28bb2c0c08a84";
      sha256 = "cW2HtTZ/DjWCnbZuBx0Pf2TO6Y6mrNz4nAC6PFrQMWo=";
    };
    lispCheckDependencies = [ fiveam ];
    lispDependencies = [ array-utils form-fiddle plump clss ];
  }) {};

  marshal = callPackage (self: with self; lispDerivation {
    lispSystem = "marshal";
    lispCheckDependencies = [ xlunit ];
    src = pkgs.fetchFromGitHub {
      owner = "wlbr";
      repo = "cl-marshal";
      name = "cl-marshal-src";
      rev = "0e48cd4ef4ba1896d38ea0a87f376c1ff25eec71";
      sha256 = "2ptzXESvKeHgsAqdT7EYflbtQYinpGvFona4QTDAlF0=";
    };
  }) {};

  md5 = callPackage (self: with self; lispify [ flexi-streams ] (pkgs.fetchFromGitHub {
    name = "md5-src";
    owner = "pmai";
    repo = "md5";
    rev = "release-2.0.5";
    sha256 = "sha256-BY+ui/h01KrJ5VdsUfQBQvAaxJm00oo+An5YmM21QLw=";
  })) {};

  metabang-bind = callPackage (self: with self; lispDerivation {
    lispSystem = "metabang-bind";
    src = pkgs.fetchFromGitHub {
      name = "metabang-bind-src";
      owner = "gwkkwg";
      repo = "metabang-bind";
      rev = "02b799ba5f5fe58655056c3046104528f22a437a";
      sha256 = "2YNkAblawTEBG/+Qt1n13oaCRKOXJgdKDOyFG5EYQ4o=";
    };
    lispCheckDependencies = [ lift ];
  }) {};

  metacopy = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      name = "metacopy-src";
      owner = "gwkkwg";
      repo = "metacopy";
      rev = "03a9cd58938b7aa6de7c9f2527614a1403cbb205";
      sha256 = "L3I3fbQO8St9exILm5PxNXSTuDajzJ93h0wYg2M/bWY=";
    };
    lispSystem = "metacopy";
    lispDependencies = [ moptilities ];
    lispCheckDependencies = [ lift ];
  }) {};

  metatilities = callPackage (self: with self; lispDerivation {
    lispSystem = "metatilities";
    src = pkgs.fetchFromGitHub {
      owner = "gwkkwg";
      repo = "metatilities";
      name = "metatilities-src";
      rev = "82e13df0545d0e47ae535ea35c5c99dd3a44e69e";
      sha256 = "bZuWup9boM8+Xo+D+BIw6XgnIMhU0yJnj4DsDG2zEG8=";
    };
    lispDependencies = [ moptilities cl-containers metabang-bind ];
    lispCheckDependencies = [ lift ];
  }) {};

  metatilities-base = callPackage (self: with self; lispDerivation {
    lispSystem = "metatilities-base";
    src = pkgs.fetchFromGitHub {
      owner = "gwkkwg";
      repo = "metatilities-base";
      name = "metatilities-base-src";
      rev = "ef04337759972fd622c9b27b53149f3d594a841f";
      sha256 = "M38SlEVrOJm4NPTbK/f34lDrY47d+Ln3t1ZuzmyZORk=";
    };
    lispCheckDependencies = [ lift ];
  }) {};

  mgl-pax = callPackage (self: with self; lispDerivation {
    lispSystem = "mgl-pax";
    src = pkgs.fetchFromGitHub {
      name = "mgl-pax-src";
      rev = "5d56e4ca22b595c1ac92b53518ca4b01f8ad8fc4";
      sha256 = "z0M2Gugv7Mow0xyUpqZRj8o0FIoeYZ+HYyIK8Za3gDA=";
      owner = "melisgl";
      repo = "mgl-pax";
    };
    lispDependencies = [ named-readtables pythonic-string-reader ];
    # This package is more complicated than this suggests
    lispCheckDependencies = [
      # mgl-pax/document
      _3bmd
      _3bmd-ext-code-blocks
      colorize
      md5
      try
      # mgl-pax/navigate
      swank
      # mgl-pax/transcribe
      alexandria
    ];
  }) {};

  misc-extensions = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitLab {
    name = "misc-extensions-src";
    domain = "gitlab.common-lisp.net";
    owner = "misc-extensions";
    repo = "devel";
    rev = "101c05112bf2f1e1bbf527396822d2f50ca6327a";
    sha256 = "sha256-YHt/r4deJnsr4oRTiDiTnNRkBYy0OKu7pfFjcC5x5T8=";
  })) {};

  moptilities = callPackage (self: with self; lispDerivation {
    lispSystem = "moptilities";
    lispDependencies = [ closer-mop ];
    lispCheckDependencies = [ lift ];
    src = pkgs.fetchFromGitHub {
      owner = "gwkkwg";
      repo = "moptilities";
      name = "moptilities-src";
      rev = "a436f16b357c96b82397ec018ea469574c10dd41";
      sha256 = "zJVnrgOv43bTfdMJEACiE7oHrXUz1OhR6vQQuSReIuA=";
    };
  }) {};

  mt19937 = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitLab {
    name = "mt19937-src";
    domain = "gitlab.common-lisp.net";
    owner = "nyxt";
    repo = "mt19937";
    rev = "831284f0c7fbda54ddfd135eee1e80afad7cc16e";
    sha256 = "sha256-j3YzNAJODcJR4nsp7Myl1K7889Kg3ojMAuYwZq3WAkA=";
  })) {};

  named-readtables = callPackage (self: with self; lispDerivation {
    lispSystem = "named-readtables";
    src = pkgs.fetchFromGitHub {
      name = "named-readtables-src";
      repo = "named-readtables";
      owner = "melisgl";
      rev = "a2cb9db06e11277693e26ac104bbc2d6eb19e433";
      sha256 = "l6cIepApJn4ZmeY9GqgplD8B5pEHUJ8SO+dpGKhjL9Q=";
    };
    lispCheckDependencies = [ try ];
  }) {};

  nclasses = callPackage (self: with self; lispDerivation {
    lispDependencies = [ moptilities nasdf ];
    src = pkgs.fetchFromGitHub {
      owner = "atlas-engineer";
      repo = "nclasses";
      name = "nclasses-src";
      rev = "12c183e8e53d243ea250f190d9d1cac6f1c6de56";
      sha256 = "CTRLaJ0t65Y8rgSDzZMyWEQK8QBTQc7k5MzTklqwaNk=";
    };
    lispCheckDependencies = [ lisp-unit2 ];
    lispSystem = "nclasses";
  }) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src =  pkgs.fetchFromGitHub {
      owner = "atlas-engineer";
      repo = "nfiles";
      rev = "56d19dd64ecc6763a53cd7faf1206f19670c642a";
      sha256 = "mDAkhZtpwby7flQBNcPQsA8TKl4PvflLXI6bsHDPzeY=";
    };
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

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      repo = "optima";
      owner = "m2ym";
      name = "optima-src";
      rev = "373b245b928c1a5cce91a6cb5bfe5dd77eb36195";
      sha256 = "sha256-VDUL5bTL+987bjOiNlNFg4P9OlZj7TkFGQnpenD1hPs=";
    };
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

  osicat = callPackage (self: with self; lispDerivation {
    lispSystem = "osicat";
    src = pkgs.fetchFromGitHub {
      owner = "osicat";
      repo = "osicat";
      name = "osicat-src";
      rev = "2421f0d9608aac44ac0e18b2b5e1ff23c953f190";
      sha256 = "HLxSeuRShhf5+zhpm9pofKg8jwg4/Qfq1QfO0BP8+Dw=";
    };
    # I am ashamed to say I /still/ don’t know how dynamic linking really works
    # in Nix. My God it’s not a learning curve it’s a fractal.
    postInstall = ''
      mkdir -p $out/lib
      ( cd $out/lib ; for f in ../posix/libosicat* ; do ln -s $f ./ ; done )
    '';
    lispDependencies = [ alexandria cffi trivial-features cffi-grovel ];
    lispCheckDependencies = [ rt ];
  }) {};

  parachute = callPackage (self: with self; lispify [ documentation-utils form-fiddle trivial-custom-debugger ] (pkgs.fetchFromGitHub {
    owner = "Shinmera";
    repo = "parachute";
    name = "parachute-src";
    rev = "db0c3fa2160ab740abdab45e833a87ebc8a5b762";
    sha256 = "ldrp6Jm6v6f2hJcoV0/291yV+muaYdgDnxjOBwCjdGs=";
  })) {};

  parenscript = callPackage (self: with self; lispDerivation {
    lispSystem = "parenscript";
    version = "2.7.1";
    src = pkgs.fetchzip {
      name = "parenscript-src";
      # TODO: Somehow create a versioned URL from this.
      url = "https://common-lisp.net/project/parenscript/release/parenscript-latest.tgz";
      sha256 = "0vg9b9j5psil5iba1d9k6vfxl5rn133qvy750dny20qkp9mf3a13";
    };
    lispDependencies = [ anaphora cl-ppcre named-readtables ];
    lispCheckDependencies = [ fiveam cl-js ];
  }) {};

  parse-declarations = callPackage ({}: lispDerivation {
    lispSystem = "parse-declarations-1.0";
    src = pkgs.fetchFromGitLab {
      name = "parse-declarations-src";
      domain = "gitlab.common-lisp.net";
      owner = "parse-declarations";
      repo = "parse-declarations";
      rev = "549aebbfb9403a7fe948654126b9c814f443f4f2";
      sha256 = "sha256-rd//Wwn0pmpua9KYgixE8BzoZqd6XURUrzYVRvTE5Q0=";
    };
  }) {};

  parse-js = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    owner = "marijnh";
    repo = "parse-js";
    name = "parse-js-src";
    rev = "fbadc6029bec7039602abfc06c73bb52970998f6";
    sha256 = "aey215BagBLQJSS78xl2ybuVmcGNkfuGLsrHWbLNrfE=";
  })) {};

  parse-number = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    owner = "sharplispers";
    repo = "parse-number";
    name = "parse-number-src";
    rev = "de944fd22c9e5db450d48cdf829abd38a375c07c";
    sha256 = "75VcTh+9ACghhHsw8dqQ1S8rh/SL4T6954UtGD6AudI=";
  })) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "Ramarren";
      repo = "cl-parser-combinators";
      name = "cl-parser-combinators-src";
      rev = "9c7569a4f6af5e60c0d3a51d9c15c16d1714c845";
      sha256 = "SMMWbY1xzivIMDYWvTTvI21ix3kc3+8VnUzUXhTcicw=";
    };
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

  path-parse = callPackage (self: with self; lispDerivation {
    lispSystem = "path-parse";
    lispCheckDependencies = [ fiveam ];
    lispDependencies = [ split-sequence ];
    src = pkgs.fetchFromGitHub {
      owner = "eudoxia0";
      repo = "path-parse";
      name = "path-parse-src";
      rev = "86183f3752374435f8933394b4c5d8e75a37a113";
      sha256 = "WKkQ1vDLEko0npTPhunrQSG1kEkTccHh2NcxYbCpvYI=";
    };
  }) {};

  plump = callPackage (self: with self; lispify [ array-utils documentation-utils ] (pkgs.fetchFromGitHub {
    owner = "Shinmera";
    repo = "plump";
    name = "plump-src";
    rev = "a59d822b73167d90a00bb438bef250c536e0bdfc";
    sha256 = "KMj4lTRJ6IHS0zN6C63cDgqc5GMBE1CaXVXAmot81pU=";
  })) {};

  proc-parse = callPackage (self: with self; lispDerivation {
    lispSystem = "proc-parse";
    lispDependencies = [ alexandria babel ];
    lispCheckDependencies = [ prove ];
    src = pkgs.fetchFromGitHub {
      owner = "fukamachi";
      repo = "proc-parse";
      name = "proc-parse-src";
      rev = "3afe2b76f42f481f44a0a495256f7abeb69cef27";
      sha256 = "sha256-gpNY32YrKMp86FhWRZHSTeckmPJYV1UZ5Z5gt4yQax8=";
    };
  }) {};

  prove = callPackage (self: with self; lispDerivation {
    # Old name for this project
    lispSystems = [ "prove" "cl-test-more" ];
    src = pkgs.fetchFromGitHub {
      name = "prove-src";
      repo = "prove";
      owner = "fukamachi";
      rev = "5d71f02795b89e36f34e8c7d50e69b67ec6ca2de";
      sha256 = "sha256-7H6JEkp9tD4bsQr2gOp4EETylja109TUwJNV+IeCRjE=";
    };
    lispDependencies = [
      alexandria
      cl-ansi-text
      cl-colors
      cl-ppcre
    ];
    lispCheckDependencies = [ alexandria split-sequence ];
  }) {};

  ptester = callPackage (self: with self; lispDerivation rec {
    lispSystem = "ptester";
    version = "20160829.gitfe69fde";
    src = fetchDebianPkg {
      inherit version;
      sha256 = "sha256-jjc7JP+T7jrbSsPU+RNhQrxOKYkQDfiJwyLbxg51FNA=";
      pname = "cl-ptester";
    };
  }) {};

  punycode = callPackage (self: with self; lispDerivation {
    lispSystem = "punycode";
    src = pkgs.fetchFromGitHub {
      name = "punycode-src";
      owner = "Shinmera";
      repo = "punycode";
      rev = "c79374a2ed1d9385f3db630887a0528e1b25abfb";
      sha256 = "dlyAmiDrddYYY1PczdkN3QNzhgRPjKEgSHwwuiSgERU=";
    };
    lispCheckDependencies = [ parachute ];
  }) {};

  puri = callPackage (self: with self; lispDerivation {
    lispSystem = "puri";
    src = pkgs.fetchFromGitLab {
      name = "puri-src";
      domain = "gitlab.common-lisp.net";
      owner = "clpm";
      repo = "puri";
      rev = "4bbab89d9ccbb26346899d1f496c97604fec567b";
      sha256 = "sha256-rV5ViV0082r3PQlmUdYo+GtCW934kw3EBxpGBbLOAj8=";
    };
    lispCheckDependencies = [ ptester ];
  }) {};

  pythonic-string-reader = callPackage (self: with self; lispify [ named-readtables ] (pkgs.fetchFromGitHub {
    name = "pythonic-string-reader-src";
    repo = "pythonic-string-reader";
    owner = "smithzvk";
    sha256 = "sha256-cuBcaLKD1lv8c2NELdJMg9Vnc0a/Tsa1GVB3xLHPsaw=";
    rev = "47a70ba1e32362e03dad6ef8e6f36180b560f86a";
  })) {};

  quickhull = callPackage (self: with self; lispify [ _3d-vectors documentation-utils ] (pkgs.fetchFromGitHub {
    name = "quickhull-src";
    owner = "Shirakumo";
    repo = "quickhull";
    rev = "a67173317f078f28320f9a0da74b8856e33da9e4";
    sha256 = "bp6vdnuqMwplU3RpvM4WHKgntnWZQ6AtB255qYFixSk=";
  })) {};

  quri = callPackage (self: with self; lispDerivation {
    lispSystem = "quri";
    lispDependencies = [ alexandria babel cl-utilities split-sequence ];
    lispCheckDependencies = [ prove ];
    src = pkgs.fetchFromGitHub {
      name = "quri-src";
      repo = "quri";
      owner = "fukamachi";
      rev = "0.6.0";
      sha256 = "sha256-nET11vDMR08TztEA+hYk4u0rHtnLQTh8gZeSPOSCOfM=";
    };
  }) {};

  reblocks  = callPackage (self: with self; lispDerivation {
    lispSystem = "reblocks";
    src = pkgs.fetchFromGitHub {
      owner = "40ants";
      repo = "reblocks";
      name = "reblocks-src";
      rev = "efa61a8972bc3c34838291376ccb0ee841f22aea";
      sha256 = "M4UIrR7qQGmrOenF52Ul4fMbutZSEdwZH/sbYqbXS+4=";
    };
    lispCheckDependencies = [ hamcrest ];
    lispDependencies = [
      _40ants-doc
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
      spinneret-cl-markdown
      trivial-open-browser
      trivial-timeout
      uuid
    ];
  }) {};

  rfc2388 = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitLab {
    name = "rfc2388-src";
    domain = "gitlab.common-lisp.net";
    owner = "rfc2388";
    repo = "rfc2388";
    rev = "51bf93e91cb6c2d515c7674db19cc87d4550fd0b";
    sha256 = "sha256-RqFzdYyAEvJZKcSjSNXHog2KYxxFmyHupiX2DphUV4U=";
  })) {};

  routes = callPackage (self: with self; lispDerivation {
    lispSystem = "routes";
    src = pkgs.fetchFromGitHub {
      owner = "archimag";
      repo = "cl-routes";
      name = "cl-routes-src";
      rev = "1b79e85aa653e1ec87e21ca745abe51547866fa9";
      sha256 = "IS+9osD50/fjph6iLEohe59BcvcgUHkvKBWiLS4b8/4=";
    };
    lispDependencies = [ puri iterate split-sequence ];
    lispCheckDependencies = [ lift ];
  }) {};

  # For some reason none of these dependencies are specified in the .asd
  rove = callPackage (self: with self; lispify [
    bordeaux-threads
    dissect
    trivial-gray-streams
  ] (pkgs.fetchFromGitHub {
    name = "rove-src";
    owner = "fukamachi";
    repo = "rove";
    rev = "0.10.0";
    sha256 = "sha256-frJlBDdnoJjhKwqas/3zq414xQULCeN4XtzpgJL44ek=";
  })) {};

  rt = callPackage (self: with self; lispDerivation rec {
    lispSystem = "rt";
    version = "a6a7503a0b47953bc7579c90f02a6dba1f6e4c5a";
    src = fetchKpePkg {
      inherit version;
      name = "rt";
      sha256 = "sha256-KxlltS8zCpuYX6Yp05eC2t/eWcTavD0XyOsp1XMWUY8=";
    };
  }) {};

  # rutils and rutilsx have the same dependencies etc, it’s not worth the hassle
  # creating separate derivations for them.
  rutils = callPackage (self: with self; lispDerivation {
    lispSystems = [ "rutils" "rutilsx" ];
    src = pkgs.fetchFromGitHub {
      name = "rutils-src";
      owner = "vseloved";
      repo = "rutils";
      rev = "79cb02922f025e818ef4100957abdc9f8d671e2c";
      sha256 = "GHZ1iHupzMSeE9R/Hghzfio+RM2TKA7uq3BBfCYxFIE=";
    };
    lispDependencies = [ named-readtables closer-mop ];
    lispCheckDependencies = [ should-test ];
  }) {};

  s-sysdeps = callPackage (self: with self; lispify [ usocket usocket-server bordeaux-threads ] (pkgs.fetchFromGitHub {
    owner = "svenvc";
    repo = "s-sysdeps";
    name = "s-sysdeps-src";
    rev = "7f8de283b7fbd8b038fdf08493063a736db36ce7";
    sha256 = "liyR8vIFlrxkU+hS4XOFAalHX0Le1cUbRoS+DHAM6GY=";
  })) {};

  s-xml = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitLab {
    domain = "gitlab.common-lisp.net";
    name = "s-xml-src";
    owner = "s-xml";
    repo = "s-xml";
    rev = "194cceaf90fb1a268d63f25f9b36e570af07cfb1";
    sha256 = "sha256-wcXT9OGaCdEbkwWPYV4JA6FNGlppTXAuK+8QR/MvTv8=";
  })) {};

  salza2 = callPackage (self: with self; lispDerivation {
    lispSystem = "salza2";
    src = pkgs.fetchzip {
      name = "salza2-src";
      # TODO: Somehow create a versioned URL from this.
      url = "http://www.xach.com/lisp/salza2.tgz";
      sha256 = "sha256-IGjFOcpN/ZG++w2LsXqt6xy2wbSVFehvLvraFVuniNw=";
    };
    lispDependencies = [ trivial-gray-streams ];
    lispCheckDependencies = [
      chipz
      flexi-streams
      parachute
    ];
  }) {};

  serapeum = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "ruricolist";
      repo = "serapeum";
      name = "serapeum-src";
      rev = "9b2458e1d238638072216e465f4f43a2837f8880";
      sha256 = "ljjgYixEASYuhUxE+vjfPX1okx/1Q3LUza43tfPaBIw=";
    };
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

  should-test = callPackage (self: with self; lispDerivation {
    lispSystem = "should-test";
    lispDependencies = [ rutils local-time osicat cl-ppcre];
    # TODO: This should be propagated from osicat somehow, not in every client
    # using osicat.
    preBuild = ''
export LD_LIBRARY_PATH=''${LD_LIBRARY_PATH+$LD_LIBRARY_PATH:}${osicat}/lib
'';
    buildInputs = [ osicat ];
    src = pkgs.fetchFromGitHub {
      owner = "vseloved";
      repo = "should-test";
      name = "should-test-src";
      rev = "48facb9f9c07aeceb71fc0c48ce17fd7d54a09d4";
      sha256 = "1dbuhCwkseODlRebU/ohx7NJ/VyRpiiBeRgJB+lRGLs=";
    };
  }) {};

  simple-date-time = callPackage (self: with self; lispify [ cl-ppcre ] (pkgs.fetchFromGitHub {
    owner = "quek";
    repo = "simple-date-time";
    name = "simple-date-time-src";
    rev = "d6992afddedf67a8172a0120a1deac32afcaa2e8";
    sha256 = "pAqI7g0bUFi1dIMF0BkhtC0cEW1Os+n+hNg39kZwPBo=";
  })) {};

  slynk = callPackage (self: with self; lispDerivation {
    lispSystem = "slynk";
    src = pkgs.fetchFromGitHub {
      owner = "joaotavora";
      repo = "sly";
      name = "sly-src";
      rev = "fa3bcf0237b420d1a3b1670eb35d7c5f96f94c62";
      sha256 = "7UUZbYRqd5cIdAlp9FxlSExYwcAdKKpSM3gIQ0sEShc=";
    };
    lispAsdPath = [ "slynk" ];
  }) {};

  smart-buffer = callPackage (self: with self; lispDerivation {
    lispSystem = "smart-buffer";
    src = pkgs.fetchFromGitHub {
      name = "smart-buffer-src";
      owner = "fukamachi";
      repo = "smart-buffer";
      rev = "619759d8a6f821773bbc65c0bda553d30e51e6f3";
      sha256 = "sha256-+d58K2b6y8umupE3Yw9Hxw/DqEG6R/EeVqeGdFQwPuU=";
    };
    lispCheckDependencies = [ babel prove ];
    lispDependencies = [ flexi-streams xsubseq ];
  }) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "ruricolist";
      repo = "spinneret";
      name = "spinneret-src";
      rev = "6a53009714ca641e86e1f9010400256bfc81b8c1";
      sha256 = "h+kEf090aAJMOhqkk624O1YjfLuJKtpyMH2Lo11jiSA=";
    };
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

  split-sequence = callPackage (self: with self; lispDerivation {
    lispSystem = "split-sequence";
    lispCheckDependencies = [ fiveam ];
    src = pkgs.fetchFromGitHub {
      name = "split-sequence-src";
      owner = "sharplispers";
      repo = "split-sequence";
      rev = "89a10b4d697f03eb32ade3c373c4fd69800a841a";
      sha256 = "sha256-faF2EiQ+xXWHX9JlZ187xR2mWhdOYCpb4EZCPNoZ9uQ=";
    };
  }) {};

  # N.B.: Soon won’t depend on cffi-grovel
  static-vectors = callPackage (self: with self; lispDerivation {
    lispSystem = "static-vectors";
    src = pkgs.fetchFromGitHub {
      name = "static-vectors-src";
      owner = "sionescu";
      repo = "static-vectors";
      rev = "v1.8.9";
      sha256 = "sha256-3BGtfPZH4qJKrZ6tJxf18QMbkn4qEofD198qSIFQOB0=";
    };
    lispDependencies = [ alexandria cffi cffi-grovel ];
    lispCheckDependencies = [ fiveam ];
  }) {};

  stefil = callPackage (self: with self; lispify [
    alexandria
    iterate
    metabang-bind
    swank
  ] (pkgs.fetchFromGitLab {
    domain = "gitlab.common-lisp.net";
    name = "stefil-src";
    owner = "stefil";
    repo = "stefil";
    rev = "0398548ec95dceb50fc2c2c03e5fb0ce49b86c7a";
    sha256 = "sha256-kLKFBG6ZD3cRQAHoLAgxqp2fd9XaY/9DcvB/LTAxHy8=";
  })) {};

  stem = callPackage (self: with self; lispify [] (pkgs.fetchFromGitHub {
    owner = "hanshuebner";
    repo = "stem";
    name = "stem-src";
    rev = "901e859bdc2b8cc5d8e91dbaca8909e6db05fa84";
    sha256 = "t54TpV0YGoKAV1mKU8k3NN3iHy6hZmRNeJzhwRLIUyg=";
  })) {};

  str = callPackage (self: with self; lispDerivation {
    lispSystem = "str";
    src = pkgs.fetchFromGitHub {
      name = "str-src";
      repo = "cl-str";
      owner = "vindarel";
      sha256 = "sha256-s7WmfIitBoNFEwapslN1ou6uPG8PvP5isLRLkGsAS1A=";
      rev = "b1c83802a323ebd843b82b30c8473c84cb09cea3";
    };
    lispDependencies = [
      cl-change-case
      cl-ppcre
      cl-ppcre-unicode
    ];
    lispCheckDependencies = [ prove ];
  }) {};

  string-case = callPackage ({}: lispify [ ] (pkgs.fetchFromGitHub {
    owner = "pkhuong";
    repo = "string-case";
    name = "string-case-src";
    rev = "718c761e33749e297cd2809c7ba3ade1985c49f7";
    sha256 = "rYKpJYSaXVhj9ZQAlWekTubhMZfHcsuyGUYXCKAfsdg=";
  })) {};

  swank = callPackage (self: with self; lispDerivation {
    lispSystem = "swank";
    # The Swank Lisp system is bundled with SLIME
    src = pkgs.fetchFromGitHub {
      name = "slime-src";
      owner = "slime";
      repo = "slime";
      rev = "v2.27";
      sha256 = "sha256-FUXICb0X9z7bDIewE3b2HljzheJAugAiT4pxmoY+OHM=";
    };
    patches = ./patches/slime-fix-swank-loader-fasl-cache-pwd.diff;
  }) {};

  symbol-munger = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "AccelerationNet";
      repo = "symbol-munger";
      name = "symbol-munger-src";
      rev = "e96558e8315b8eef3822be713354787b2348b25e";
      sha256 = "31n3osRTSRq6QcTCeP8iYTt1S69U7vAHKCKIdLuF2pk=";
    };
    lispSystem = "symbol-munger";
    lispDependencies = [ alexandria iterate ];
    lispCheckDependencies = [ lisp-unit2 ];
  }) {};

  tmpdir = callPackage (self: with self; lispify [ cl-fad ] (pkgs.fetchFromGitHub {
    owner = "moderninterpreters";
    repo = "tmpdir";
    name = "tmpdir-src";
    rev = "e1981284b969e04a48a3e7f3b98a50435e853eb6";
    sha256 = "aBJb+MCxWT2NKuNdQwRvubQwQqVzece5L6d5Ll6F2oc=";
  })) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      name = "trivia-src";
      owner = "guicho271828";
      repo = "trivia";
      rev = "9e38bf25c46f44c31fde689cfee09cc0aaf36176";
      sha256 = "NbyC1XMcXW7Oi310dhoB78pTvHBBO66/CW94wmYwAo8=";
    };

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

  trivial-arguments = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    owner = "Shinmera";
    name = "trivial-arguments-src";
    repo = "trivial-arguments";
    rev = "d3e376d0f47622c7b93810b8a49b0b5e565a5edc";
    sha256 = "xCne5/RM5Lj/PeK3LW5UXWqwGpppXC+aHNeGKG9aM30=";
  })) {};

  trivial-backtrace = callPackage (self: with self; lispify [ lift ] (pkgs.fetchFromGitLab {
    name = "trivial-backtrace-src";
    domain = "gitlab.common-lisp.net";
    owner = "trivial-backtrace";
    repo = "trivial-backtrace";
    rev = "version-1.1.0";
    sha256 = "sha256-RKNfjk5IrZSSOyc13VnR9GQ7mHj3IEWzizKmjVeHVu4=";
  })) {};

  trivial-benchmark = callPackage (self: with self; lispify [ alexandria ] (pkgs.fetchFromGitHub {
    name = "trivial-benchmark-src";
    owner = "Shinmera";
    repo = "trivial-benchmark";
    rev = "7d132c3d8d937bc17d3ae1fa5872cc069629e2a2";
    sha256 = "CY0qZyxs+x3YQAUVXVrYtwqwgvtbTi8dRt2FPeUbF9k=";
  })) {};

  trivial-cltl2 = callPackage (self: with self; lispDerivation {
    lispSystem = "trivial-cltl2";
    src = pkgs.fetchFromGitHub {
      name = "trivial-cltl2-src";
      owner = "Zulu-Inuoe";
      repo = "trivial-cltl2";
      rev = "2ada8722dc1d7bae1f49832a2ca26b25b90055d3";
      sha256 = "sha256-Q43ISShYRiNXVtFczzlpTxJ6upnNrR9CqEOY20DepXc=";
    };
  }) {};

  trivial-custom-debugger = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      name = "trivial-custom-debugger-src";
      owner = "phoe";
      repo = "trivial-custom-debugger";
      rev = "a560594a673bbcd88136af82086107ee5ff9ca81";
      sha256 = "sha256-0yPROdgl/Rv6oQ+o5hBrJafT/kGSkZFwcYHpdDUvMcc=";
    };
    lispSystem = "trivial-custom-debugger";
    lispCheckDependencies = [ parachute ];
  }) {};

  trivial-extract = callPackage ({ zip, ...}@self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "eudoxia0";
      repo = "trivial-extract";
      name = "trivial-extract-src";
      rev = "320a0bd7fe02a5551f311fa8f1a4df16dd7322f5";
      sha256 = "XaeBgqGDErKZDCDsXChs9XkQcVSPe9Q4Mct04sLpAwE=";
    };
    lispSystem = "trivial-extract";
    lispDependencies = [
      archive
      zip
      deflate
      which
      cl-fad
      alexandria
    ];
    lispCheckDependencies = [
      fiveam
    ];
  }) {};

  trivial-features = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      name = "trivial-features-src";
      owner = "trivial-features";
      repo = "trivial-features";
      rev = "v1.0";
      sha256 = "sha256-+Bp7YXl+Ys4/nkxNeE8D06uBwLJW7cJtpxF/+wNUWEs=";
    };
    lispSystem = "trivial-features";
    lispCheckDependencies = [ rt cffi cffi-grovel alexandria ];
  }) {};

  trivial-file-size = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "ruricolist";
      repo = "trivial-file-size";
      name = "trivial-file-size-src";
      rev = "77e98d99d04e017d227a64157f3f8db4b0e0dfe4";
      sha256 = "3CF84lgakSdFmN8Q4+ffUf1DckoFevF4f65C/f6QJUo=";
    };
    lispCheckDependencies = [ fiveam ];
    lispSystem = "trivial-file-size";
  }) {};

  trivial-garbage = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      name = "trivial-garbage-src";
      owner = "trivial-garbage";
      repo = "trivial-garbage";
      rev = "v0.21";
      sha256 = "sha256-NnF43ZB6ag+0RSgB43HMrkCRbJjqI955UOye51iUQgQ=";
    };
    lispSystem = "trivial-garbage";
    lispCheckDependencies = [ rt ];
  }) {};

  trivial-gray-streams = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "trivial-gray-streams-src";
    owner = "trivial-gray-streams";
    repo = "trivial-gray-streams";
    rev = "2b3823edbc78a450db4891fd2b566ca0316a7876";
    sha256 = "sha256-9vN74Gum7ihKSrCygC3hRLczNd15nNCWn5r60jjHN8I=";
  })) {};

  trivial-indent = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "trivial-indent-src";
    repo = "trivial-indent";
    owner = "Shinmera";
    rev = "f25275094b80df8aa158af46db980bbc3ce2f88b";
    sha256 = "3bfhjJpZLFrAwFtcsufXjMMee1m/fNx7luziHrxn6P0=";
  })) {};

  trivial-macroexpand-all = callPackage ({}: lispify [ ] (pkgs.fetchFromGitHub {
    owner = "cbaggers";
    repo = "trivial-macroexpand-all";
    name = "trivial-macroexpand-all-src";
    rev = "933270ac7107477de1bc92c1fd641fe646a7a8a9";
    sha256 = "bRGt5l/XhpyM/NXIj+iBQM4wRF2f1uYzG5HIsoi1MKQ=";
  })) {};

  trivial-mimes = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "trivial-mimes-src";
    repo = "trivial-mimes";
    owner = "Shinmera";
    rev = "fd07c43e6bc39fefee7608a41cc4c9286ef81e59";
    sha256 = "8xzwY4GBtPfSRyXN/XLYm3qqCaQXX2IoMVodFOtwoms=";
  })) {};

  trivial-open-browser = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    owner = "eudoxia0";
    repo = "trivial-open-browser";
    name = "trivial-open-browser-src";
    rev = "7ab4743dea9d592639f15c565bfa0756e828c427";
    sha256 = "q2nskSt9tyO+p6LMt/OZ0dBCOMSCmN6UiUAQHG/wqkc=";
  })) {};

  trivial-package-local-nicknames = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    owner = "phoe";
    repo = "trivial-package-local-nicknames";
    name = "trivial-package-local-nicknames-src";
    rev = "8a4d09c1c5cb2b5349aecbd796164433df7a6cc5";
    sha256 = "+YweT2sPT4pNvMjWvoEJAiPPpC8Ykwbvgdh9Rg7RAF0=";
  })) {};

  trivial-rfc-1123 = callPackage (self: with self; lispify [ cl-ppcre ] (pkgs.fetchFromGitHub {
    owner = "stacksmith";
    repo = "trivial-rfc-1123";
    name = "trivial-rfc-1123-src";
    rev = "9ef59c3fdec08b0e3c9ed02d39533887b6d1b8e3";
    sha256 = "3cCwIsm8Wd2jq/YKey8l01v0aKe/CaM8O9c6EOTlnvA=";
  })) {};

  trivial-shell = callPackage (self: with self; lispDerivation {
    lispSystem = "trivial-shell";
    src = pkgs.fetchFromGitHub {
      owner = "gwkkwg";
      repo = "trivial-shell";
      name = "trivial-shell-src";
      rev = "ad4218b62bea99ef10c1675eeba5cd96c763e46e";
      sha256 = "oZQSD55XdLazzouSbvOBFjC6kTFWILw+vui62BRpRlo=";
    };
    lispCheckDependencies = [ lift ];
  }) {};

  trivial-sockets = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "trivial-sockets-src";
    owner = "usocket";
    repo = "trivial-sockets";
    rev = "v0.4";
    sha256 = "sha256-oNmzHkPgmyf4qrOM9n3H0ZXOdQ8fJ8HSVbjrO37pSXY=";
  })) {};

  trivial-timeout = callPackage (self: with self; lispDerivation {
    lispSystem = "trivial-timeout";
    lispCheckDependencies = [ lift ];
    src = pkgs.fetchFromGitHub {
      owner = "gwkkwg";
      repo = "trivial-timeout";
      name = "trivial-timeout-src";
      rev = "126340fc64fb08f24940f9228fe941cd59e27d37";
      sha256 = "HQfpir7UlGQ0bG6xvVkmbaBmzmI2HKkIznaKaeuC9b8=";
    };
  }) {};

  trivial-types = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "trivial-types-src";
    owner = "m2ym";
    repo = "trivial-types";
    rev = "ee869f2b7504d8aa9a74403641a5b42b16f47d88";
    sha256 = "sha256-gQwbqW6730IPGPpVIO53e2X+Jg/u8IMPIcgu2la6jOg=";
  })) {};

  trivial-utf-8 = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitLab {
    name = "trivial-utf-8-src";
    domain = "gitlab.common-lisp.net";
    owner = "trivial-utf-8";
    repo = "trivial-utf-8";
    rev = "6ca9943588cbc61ad22a3c1ff81beb371e122394";
    sha256 = "sha256-Wg8g/aQHNyiQpMnrgK0Olyzi3RaoC0yDL97Ctb5f7z8=";
  })) {};

  trivial-with-current-source-form = callPackage (self: with self; lispify [ alexandria ] (pkgs.fetchFromGitHub {
    name = "trivial-with-current-source-form-src";
    owner = "scymtym";
    repo = "trivial-with-current-source-form";
    rev = "3898e09f8047ef89113df265574ae8de8afa31ac";
    sha256 = "sha256-IKJOyJYqGBx0b6Oomddvb+2K6q4W508s3xnplleMJIQ=";
  })) {};

  try = callPackage (self: with self; lispify [ alexandria closer-mop ieee-floats mgl-pax trivial-gray-streams ] (pkgs.fetchFromGitHub {
    owner = "melisgl";
    repo = "try";
    name = "try-src";
    rev = "55844c4b2e6ced7cfc919f57519e29103f5de6f2";
    sha256 = "hEbmFKD2JnkN1pqTS1ByvQFwdFj++jXTd6YN3j5oPGY=";
  })) {};

  type-i = callPackage (self: with self; lispDerivation {
    lispSystem = "type-i";
    src = pkgs.fetchFromGitHub {
      name = "type-i-src";
      owner = "guicho271828";
      repo = "type-i";
      rev = "4407a6852e76e795f697180dfb01749b49cc7b0c";
      sha256 = "Go6X/9gNN/MrAYqyFV2LEjcoeVVAU1/c5W/s+GOALfk=";
    };
    lispDependencies = [
      alexandria
      introspect-environment
      trivia-trivial
      lisp-namespace
    ];
    lispCheckDependencies = [ fiveam ];
  }) {};

  typo = callPackage (self: with self; lispDerivation {
    lispSystem = "typo";
    lispDependencies = [
      alexandria
      closer-mop
      introspect-environment
      trivia
      trivial-arguments
      trivial-garbage
    ];
    src = pkgs.fetchFromGitHub {
      owner = "marcoheisig";
      repo = "Typo";
      rev = "b16e40099e44e9de464f3a69b4f38bb29c9eff8c";
      sha256 = "Ki08/b2wYPWFQupw+oJvOQfSkSDXnmlANhpRsi+LnKE=";
    };
    lispAsdPath = [ "code" ];
    preCheck = ''
      export CL_SOURCE_REGISTRY="$PWD/code/test-suite:$CL_SOURCE_REGISTRY"
    '';
  }) {};

  unit-test = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "unit-test-src";
    owner = "hanshuebner";
    repo = "unit-test";
    rev = "266afaf4ac091fe0e8803bac2ae72d238144e735";
    sha256 = "sha256-SU7doHkJFZSaCTYr74RIsiU7MlLiFsHl2RNHU76eF4Y=";
  })) {};

  inherit (callPackage (self: with self; lispMultiDerivation {
    src = pkgs.fetchFromGitHub {
      name = "usocket-src";
      repo = "usocket";
      owner = "usocket";
      rev = "v0.8.5";
      sha256 = "sha256-anFwnv/E5WtuJO+WgdFcrvlM84EVdLcBPGu81Iirxd4=";
    };
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

  uuid = callPackage (self: with self; lispify [ ironclad trivial-utf-8 ] (pkgs.fetchFromGitHub {
    owner = "dardoria";
    repo = "uuid";
    name = "uuid-src";
    rev = "f0052f34a006ec995086aa3b2e42182a178fe228";
    sha256 = "oN+MXp7i+9r/AiyZtTsZsVGa5yXtcC3/vPy9D7iHnNk=";
  })) {};

  vom = callPackage (self: with self; lispify [ ] (pkgs.fetchFromGitHub {
    name = "vom-src";
    owner = "orthecreedence";
    repo = "vom";
    rev = "1aeafeb5b74c53741b79497e0ef4acf85c92ff24";
    sha256 = "sha256-nqVv41WDV5ncToM8UWchvWrp5rWCbNgzJV2ZI++dZhQ=";
  })) {};

  which = callPackage (self: with self; lispDerivation {
    lispSystem = "which";
    src = pkgs.fetchFromGitHub {
      owner = "eudoxia0";
      repo = "which";
      name = "which-src";
      rev = "b2333e4fcacab6e5d85eecd28b5ef4944bda1448";
      sha256 = "02H845n6zOQyCB2ymUzOYsLvbFXbF96USpzUTGCq94g=";
    };
    lispCheckDependencies = [ fiveam ];
    lispDependencies = [ path-parse cl-fad ];
  }) {};

  wild-package-inferred-system = callPackage (self: with self; lispDerivation {
    lispCheckDependencies = [ fiveam ];
    lispSystem = "wild-package-inferred-system";
    src = pkgs.fetchFromGitHub {
      owner = "privet-kitty";
      repo = "wild-package-inferred-system";
      name = "wild-package-inferred-system-src";
      rev = "800b5f89b61cc4a0a9cf14706fd3f7e7fcd3e539";
      sha256 = "AH23HE+NpJ8aZkvyAHWKPtNoQSJatkFXwh6rgeKQ42o=";
    };
  }) {};

  with-output-to-stream = callPackage (self: with self; lispDerivation {
    lispSystem = "with-output-to-stream";
    version = "1.0";
    src = pkgs.fetchzip {
      name = "with-output-to-stream-src";
      # TODO: Somehow create a versioned URL from this.
      url = "https://tarballs.hexstreamsoft.com/libraries/latest/with-output-to-stream_latest.tar.gz";
      sha256 = "sha256-VRszRJil9IltmwkrobOwAN+k1bfXscXPZm/2JRmbaV8=";
    };
  }) {};

  wu-decimal = callPackage (self: with self; lispify [] (pkgs.fetchFromGitHub {
    owner = "Wukix";
    repo = "wu-decimal";
    name = "wu-decimal-src";
    rev = "5b348bdb32a0f83e80e17aa68cd51787ae8c8a45";
    sha256 = "taH7Odn1nqGyZ1brxpC3xJjuJ3ctksqrOkkcFiFR9tw=";
  })) {};

  xml-emitter = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      owner = "VitoVan";
      repo = "xml-emitter";
      name = "xml-emitter-src";
      rev = "0afb8e2a90d68f63fdc4387d0e660cee8d5f4054";
      sha256 = "POjrOBNZYBB2+eiSquYkqUObav9kT3HYUKegHdrz8eA=";
    };
    lispSystem = "xml-emitter";
    lispDependencies = [ cl-utilities ];
    lispCheckDependencies = [ _1am ];
  }) {};

  xlunit = callPackage (self: with self; lispDerivation rec {
    lispSystem = "xlunit";
    version = "3805d34b1d8dc77f7e0ee527a2490194292dd0fc";
    src = fetchKpePkg {
      inherit version;
      name = "xlunit";
      sha256 = "sha256-g/dCnf5PqvhTLfsASs8SKzqcIENuSA+jJho+m251Lys=";
    };
  }) {};

  xsubseq = callPackage (self: with self; lispDerivation {
    src = pkgs.fetchFromGitHub {
      name = "xsubseq-src";
      repo = "xsubseq";
      owner = "fukamachi";
      rev = "5ce430b3da5cda3a73b9cf5cee4df2843034422b";
      sha256 = "sha256-/aaUy8um0lZpJXuBMrLO3azbfjSOR4n1cJRVcQFO5/c=";
    };
    lispSystem = "xsubseq";
    lispCheckDependencies = [ prove ];
  }) {};

  # QL calls this "cl-yacc", but the system name is "yacc", so I’m sticking to
  # "yacc". Regardless of the repo name--that’s not authoritative. The system
  # name is.
  yacc = callPackage (self: with self; lispDerivation {
    lispSystem = "yacc";
    src = pkgs.fetchFromGitHub {
      owner = "jech";
      repo = "cl-yacc";
      name = "cl-yacc-src";
      rev = "1812e05317dcab1e97905625c018c043d71f9187";
      sha256 = "58XGb6nm51ljEhgQYcmz8/r1OudxmIetnpnWE7UnJ7k=";
    };
  }) {};

  yason = callPackage (self: with self; lispify [ alexandria trivial-gray-streams ] (pkgs.fetchFromGitHub {
    name = "yason-src";
    owner = "phmarek";
    repo = "yason";
    rev = "f4ad893e9dc4142396a86bc518ff6bc814fd43da";
    sha256 = "zeNoFytBPZ1D8g0xDugsMBaRyG9vtWG8WZxnAna7PAI=";
  })) {};

  zip = callPackage (self: with self; lispify [ trivial-gray-streams babel cl-fad salza2 ] (pkgs.fetchFromGitHub {
      owner = "bluelisp";
      repo = "zip";
      name = "zip-src";
      rev = "688b1545dd7a4fe355556768bb03f8bd9b847a87";
      sha256 = "xvjyYCvmc55ath3ePTnrz2BK28Iwbu+W/k6ggJ1RCGg=";
  })) {};

  zpng = callPackage (self: with self; lispify [ salza2 ] (pkgs.fetchzip {
    version = "1.2.2";
    pname = "zpng-src";
    url = "https://www.xach.com/lisp/zpng.tgz";
    sha256 = "sha256-leVkFuyTE0dQSubMHzMuHEKne9MNqqFpm+cPCuV4aiw=";
  })) {};
}))
