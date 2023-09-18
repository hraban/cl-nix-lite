{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

with pkgs.lib;

attrsets.filterAttrs
  (_: d: (isDerivation d) && ! ((d.meta or {}).broken or false))
  pkgs.lispPackagesLite
