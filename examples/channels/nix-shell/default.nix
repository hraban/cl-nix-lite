{
  cl-nix-lite ? import ../../..,
  pkgs ? import <nixpkgs> { overlays = [ cl-nix-lite ]; },
}:

with pkgs.lispPackagesLite;
lispDerivation {
  src = pkgs.lib.cleanSource ./.;
  lispSystem = "dev";
  lispDependencies = [ arrow-macros ];
  buildInputs = [ pkgs.sbcl ];
}
