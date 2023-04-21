{
  pkgs ? import <nixpkgs> {}
  , lispPackagesLite ? import ../.. { inherit pkgs; }
}:

# To build all packages:
#
#     nix-build
#
# To build only one package, e.g. alexandria:
#
#     nix-build -A alexandria

lispPackagesLite
