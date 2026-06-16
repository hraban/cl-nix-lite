{ inputs }:

final: prev:
let
  inherit (final) callPackage;
in
{
  "1am" = callPackage (
    { lispDerivation }:
    lispDerivation {
      lispSystem = "1am";
      src = inputs."1am";
    }
  ) { };

  cl-difflib = callPackage (
    { lispDerivation }:
    lispDerivation {
      lispSystem = "cl-difflib";
      src = inputs.cl-difflib;
    }
  ) { };
}
