{
  pkgs ? import <nixpkgs> {}
  , lispPackagesLite ? import ../.. { inherit pkgs; }
}:

# TODO: This doesn’t work, committing this for future reference only
lispPackagesLite.lispWithSystems (
  pkgs.lib.pipe lispPackagesLite [
    builtins.attrValues
    (builtins.filter pkgs.lib.isDerivation)
  ])
