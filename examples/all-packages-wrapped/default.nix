{
  pkgs ? import <nixpkgs> {}
, cl-nix-lite ? import ../..
}:

with pkgs.extend cl-nix-lite;

lispPackagesLite.lispWithSystems (
  lib.pipe lispPackagesLite [
    builtins.attrValues
    (builtins.filter (d: (lib.isDerivation d) && ! ((d.meta or {}).broken or false)))
  ])
