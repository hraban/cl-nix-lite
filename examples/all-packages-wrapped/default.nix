{
  pkgs ? import <nixpkgs> {}
}:

# TODO: This doesn’t work, committing this for future reference only

with rec {
  lispPackagesLite = import ../.. { inherit pkgs; };
};

lispPackagesLite.lispWithSystems (
  pkgs.lib.pipe lispPackagesLite [
    builtins.attrValues
    (builtins.filter (d: (pkgs.lib.isDerivation d) && ! ((d.meta or {}).broken or false)))
  ])
