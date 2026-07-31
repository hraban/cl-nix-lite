{
  cl-nix-lite ? import ../../..,
  pkgs ? import <nixpkgs> { overlays = [ cl-nix-lite ]; },
  lisp ? pkgs.sbcl,
}:

with pkgs.lispPackagesLiteFor lisp;

lispMultiDerivation {
  systems = {
    multiderivation = { };
    "multiderivation/a" = {
      lispDependencies = [ alexandria ];
    };
    "multiderivation/b" = { };
  };
  src = pkgs.lib.cleanSource ./.;
}
