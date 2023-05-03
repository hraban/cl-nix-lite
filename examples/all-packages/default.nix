{
  pkgs ? import <nixpkgs> {}
}:

with pkgs.lib;

pipe (import ../.. { inherit pkgs; }) [
  (attrsets.filterAttrs (_: d: (pkgs.lib.isDerivation d) && ! ((d.meta or {}).broken or false)))
]
