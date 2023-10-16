{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
, lisp ? pkgs.sbcl
}:

with pkgs.lispPackagesLiteFor lisp;

lispDerivation {
  lispSystem = "hello-binary";
  version = "0.0.1";
  dontStrip = true;
  src = pkgs.lib.cleanSource ./.;
}
