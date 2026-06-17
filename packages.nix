{
  inputs,
  lib,
  lisp,
}:

let
  packages =
    final: prev:
    let
      inherit (final) callPackage;
    in
    {
      _1am = callPackage (
        { lispDerivation }:
        lispDerivation {
          lispSystem = "1am";
          src = inputs."1am";
        }
      ) { };

      inherit
        (callPackage (
          {
            lispMultiDerivation,
            alexandria,
            esrap,
            split-sequence,
            _3bmd,
            _3bmd-ext-code-blocks,
            colorize,
            fiasco,
          }:
          lispMultiDerivation {
            src = inputs."3bmd";
            systems = {
              _3bmd = {
                lispSystem = "3bmd";
                lispDependencies = [
                  alexandria
                  esrap
                  split-sequence
                ];
                lispCheckDependencies = [
                  _3bmd-ext-code-blocks
                  fiasco
                ];
              };
              _3bmd-ext-code-blocks = {
                lispSystem = "3bmd-ext-code-blocks";
                lispDependencies = [
                  _3bmd
                  alexandria
                  colorize
                  split-sequence
                ];
              };
              _3bmd-ext-tables = {
                lispSystem = "3bmd-ext-tables";
                lispDependencies = [ _3bmd ];
              };
            };
          }
        ) { })
        _3bmd
        _3bmd-ext-code-blocks
        _3bmd-ext-tables
        ;

      _3d-math = callPackage (
        {
          documentation-utils,
          lispDerivation,
          parachute,
          type-templates,
        }:
        lispDerivation {
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
        }
      ) { };

      _3d-vectors = callPackage (
        {
          documentation-utils,
          lispDerivation,
          parachute,
        }:
        lispDerivation {
          lispDependencies = [ documentation-utils ];
          lispCheckDependencies = [ parachute ];
          src = inputs."3d-vectors";
          lispSystem = "3d-vectors";
        }
      ) { };

      inherit
        (callPackage (
          {
            _40ants-doc,
            _40ants-doc-full,
            cl-fad,
            cl-ppcre,
            commondoc-markdown,
            dexador,
            docs-builder,
            fare-utils,
            jonathan,
            lass,
            lispMultiDerivation,
            named-readtables,
            pythonic-string-reader,
            rove,
            slynk,
            spinneret,
            stem,
            str,
            swank,
            tmpdir,
            trivial-extract,
            xml-emitter,
          }:
          lispMultiDerivation {
            src = inputs."40ants-doc";
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
          }
        ) { })
        _40ants-doc
        _40ants-doc-full
        ;

      "40ants-asdf-system" = callPackage (
        {
          lispDerivation,
          asdf,
          rove,
        }:
        lispDerivation {
          lispSystem = "40ants-asdf-system";
          src = inputs."40ants-asdf-system";
          # Depends on a modern ASDF. SBCL’s built-in ASDF crashes this. Explicitly
          # listing self. here to avoid grabbing nixpkgs.asdf.
          lispDependencies = [ asdf ];
          lispCheckDependencies = [ rove ];
        }
      ) { };

      access = callPackage (
        {
          alexandria,
          closer-mop,
          iterate,
          cl-ppcre,
          lisp-unit2,
          lispDerivation,
        }:
        lispDerivation {
          lispSystem = "access";
          src = inputs.access;
          lispDependencies = [
            alexandria
            closer-mop
            iterate
            cl-ppcre
          ];
          lispCheckDependencies = [ lisp-unit2 ];
        }
      ) { };

      acclimation = callPackage (
        { lispDerivation }:
        lispDerivation {
          lispSystem = "acclimation";
          src = inputs.acclimation;
        }
      ) { };

      alexandria = callPackage (
        { lispDerivation, rt }:
        lispDerivation {
          lispSystem = "alexandria";
          src = inputs.alexandria;
          # Contrary to what its .asd file suggests, Alexandria now requires rt even
          # on SBCL. This is recent (introduced after v1.4).
          lispCheckDependencies = [ rt ];
        }
      ) { };

      alien-ring = callPackage (
        {
          lispDerivation,
          cffi,
          trivial-gray-streams,
        }:
        lispDerivation {
          lispSystem = "alien-ring";
          src = inputs.alien-ring;
          lispDependencies = [
            cffi
            trivial-gray-streams
          ];
        }
      ) { };

      anaphora = callPackage (
        { lispDerivation, rt }:
        lispDerivation {
          lispSystem = "anaphora";
          lispCheckDependencies = [ rt ];
          src = inputs.anaphora;
        }
      ) { };

      anypool = callPackage (
        {
          lispDerivation,
          bordeaux-threads,
          cl-speedy-queue,
          rove,
        }:
        lispDerivation {
          src = inputs.anypool;
          lispSystem = "anypool";
          lispDependencies = [
            bordeaux-threads
            cl-speedy-queue
          ];
          lispCheckDependencies = [ rove ];
        }
      ) { };

      archive = callPackage (
        {
          lispDerivation,
          cl-fad,
          trivial-gray-streams,
        }:
        lispDerivation {
          lispSystem = "archive";
          src = inputs.archive;
          lispDependencies = [
            cl-fad
            trivial-gray-streams
          ];
        }
      ) { };

      cl-difflib = callPackage (
        { lispDerivation }:
        lispDerivation {
          lispSystem = "cl-difflib";
          src = inputs.cl-difflib;
        }
      ) { };
    };
  vanity = final: prev: {
    "1am" = final._1am;
    "3bmd" = final._3bmd;
    "3bmd-ext-code-blocks" = final._3bmd-ext-code-blocks;
    "3bmd-ext-tables" = final._3bmd-ext-tables;
    "3d-math" = final._3d-math;
    "40ants-doc" = final._40ants-doc;
    "40ants-doc-full" = final._40ants-doc-full;
  };
in
lib.composeExtensions vanity packages
