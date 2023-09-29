{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

with rec {
  lispPackagesLite = pkgs.lispPackagesLiteFor (f: "${pkgs.sbcl}/bin/sbcl --dynamic-space-size 4000 --script ${f}");
};
with pkgs.lib;

lispPackagesLite.lispWithSystems (
  pipe lispPackagesLite [
    builtins.attrValues
    (builtins.filter (d: (isDerivation d) && ! ((d.meta or {}).broken or false)))
  ])
