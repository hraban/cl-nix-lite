{
  cl-nix-lite ? import ../../..,
  pkgs ? import <nixpkgs> { overlays = [ cl-nix-lite ]; },
  lisp ? pkgs.sbcl,
}:

let
  inherit (pkgs) lib;
  lispPackagesLite = pkgs.lispPackagesLiteFor lisp;
  isSafeLisp =
    d:
    let
      ev = builtins.tryEval (lib.isDerivation d && !(d.meta.broken or false));
    in
    ev.success && ev.value;
in

lispPackagesLite.lispWithSystems (
  lib.pipe lispPackagesLite [
    builtins.attrValues
    (builtins.filter isSafeLisp)
  ]
)
