{
  pkgs ? import <nixpkgs> {}
, cl-nix-lite ? import ../..
}:

with rec {
  pkgs' = pkgs.extend cl-nix-lite;
};
with pkgs'.lib;

pipe pkgs'.lispPackagesLite [
  (attrsets.filterAttrs (_: d: (isDerivation d) && ! ((d.meta or {}).broken or false)))
]
