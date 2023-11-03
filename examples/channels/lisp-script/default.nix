{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
, lisp ? pkgs.sbcl
}:

with pkgs.lispPackagesLiteFor lisp;

lispScript {
  name = "format-json";
  dependencies = [ yason ];
  src = ./main.lisp;
}
