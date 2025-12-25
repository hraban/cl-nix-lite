{
  cl-nix-lite ? import ../../..,
  pkgs ? import <nixpkgs> { overlays = [ cl-nix-lite ]; },
  lisp ? pkgs.sbcl,
}:

with pkgs.lispPackagesLiteFor lisp;

lispScript {
  name = "format-json";
  dependencies = [ yason ];
  src = ./main.lisp;
}
