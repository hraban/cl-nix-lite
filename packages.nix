{ lib, inputs }:

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
  };
in
lib.composeExtensions vanity packages
