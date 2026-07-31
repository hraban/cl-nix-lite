{
  cl-nix-lite ? import ../../..,
  pkgs ? import <nixpkgs> { overlays = [ cl-nix-lite ]; },
  lisp ? pkgs.sbcl,
}:

with pkgs.lispPackagesLiteFor lisp;

# Legacy option.  Will be removed in next version.
alexandria.enableCheck
