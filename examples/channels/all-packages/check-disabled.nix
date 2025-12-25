{
  cl-nix-lite ? import ../../..,
  pkgs ? import <nixpkgs> { overlays = [ cl-nix-lite ]; },
  lisp ? pkgs.sbcl,
}:

with pkgs.lib;
with rec {
  lispPackagesLite = pkgs.lispPackagesLiteFor lisp;
  isSafeLisp =
    d:
    let
      ev = builtins.tryEval (isDerivation d && !(d.meta.broken or false));
    in
    ev.success && ev.value;
};

attrsets.filterAttrs (_: isSafeLisp) lispPackagesLite
