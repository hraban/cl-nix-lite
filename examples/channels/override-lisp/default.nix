# Imagine wanting to use a very specific version of a package, e.g. to fix a
# regression, or a bug:

{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

with pkgs.lispPackagesLiteFor pkgs.clisp;
lispDerivation {
  lispSystem = "override-lisp";
  version = "0.0.1";
  dontStrip = true;
  src = pkgs.lib.cleanSource ./.;
}
