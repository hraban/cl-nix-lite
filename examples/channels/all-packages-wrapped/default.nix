{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

with pkgs.lib;
with rec {
  lispPackagesLite = pkgs.lispPackagesLiteFor (f: "${pkgs.sbcl}/bin/sbcl --dynamic-space-size 4000 --script ${f}");
  isSafeLisp = d: let
    ev = builtins.tryEval d;
    d' = ev.value;
  in ev.success && (isDerivation d') && !(d'.meta.broken or false);
};

lispPackagesLite.lispWithSystems (
  pipe lispPackagesLite [
    builtins.attrValues
    (builtins.filter isSafeLisp)
  ])
