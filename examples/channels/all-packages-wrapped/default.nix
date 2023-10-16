{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
, lisp ? (f: "${pkgs.sbcl}/bin/sbcl --dynamic-space-size 4000 --script ${f}")
}:

with pkgs.lib;
with rec {
  lispPackagesLite = pkgs.lispPackagesLiteFor lisp;
  isSafeLisp = d: let
    ev = builtins.tryEval (isDerivation d && !(d.meta.broken or false));
  in ev.success && ev.value;
};

lispPackagesLite.lispWithSystems (
  pipe lispPackagesLite [
    builtins.attrValues
    (builtins.filter isSafeLisp)
  ])
