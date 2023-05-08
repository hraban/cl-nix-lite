{
  pkgs ? import <nixpkgs> {}
, lispPackagesLite ? import ../.. { inherit pkgs; }
}:

with pkgs.lib;

pipe lispPackagesLite [
  (attrsets.filterAttrs (_: d: (pkgs.lib.isDerivation d) && ! ((d.meta or {}).broken or false)))
]
