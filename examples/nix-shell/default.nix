{
  cl-nix-lite ? ../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

with pkgs.lispPackagesLite; lispDerivation {
  src = pkgs.lib.cleanSource ./.;
  lispSystem = "dev";
  lispDependencies = [ arrow-macros ];
  buildInputs = [ pkgs.sbcl ];
}
