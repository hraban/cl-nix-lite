{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

# To use CLISP instead of SBCL:
with pkgs.lispPackagesLiteFor pkgs.clisp;

lispDerivation {
  lispSystem = "override-lisp";
  version = "0.0.1";
  dontStrip = true;
  src = pkgs.lib.cleanSource ./.;
}
