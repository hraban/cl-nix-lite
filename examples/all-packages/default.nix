{ pkgs ? import ../../../../.. {} }:

# To build all packages:
#
#     nix-build

with pkgs.lib;

let
  lispPackagesLite = pkgs.lispPackagesLite;
in

lispPackagesLite.lispWithSystems (
  pipe lispPackagesLite [
    builtins.attrValues
    (builtins.filter isDerivation)
  ])
