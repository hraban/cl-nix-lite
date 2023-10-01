{
  cl-nix-lite ? ../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

with pkgs.lispPackagesLite;

lispDerivation {
  lispDependencies = [ alexandria arrow-macros cl-async cl-async-ssl ];
  lispSystem = "with-cffi";
  version = "0.0.1";
  src = pkgs.lib.cleanSource ./.;
}
