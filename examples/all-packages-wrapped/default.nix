{
  cl-nix-lite ? ../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

with pkgs;

lispPackagesLite.lispWithSystems (
  lib.pipe lispPackagesLite [
    builtins.attrValues
    (builtins.filter (d: (lib.isDerivation d) && ! ((d.meta or {}).broken or false)))
  ])
