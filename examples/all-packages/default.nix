{ pkgs ? import ../../../../.. {} }:

# To build all packages:
#
#     nix-build

pkgs.lispPackagesLite.lispWithSystems (
  pkgs.lib.pipe pkgs.lispPackagesLite [
    builtins.attrValues
    (builtins.filter pkgs.lib.isDerivation)
  ])
