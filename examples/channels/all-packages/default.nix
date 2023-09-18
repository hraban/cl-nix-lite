{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

with rec {
  # Compiling Shinmera/3d-math requires a lot of memory, might as well grant it
  lispPackagesLite = pkgs.lispPackagesLiteFor (f: "${pkgs.sbcl}/bin/sbcl --dynamic-space-size 4000 --script ${f}");
};
with pkgs.lib;

attrsets.filterAttrs
  (_: d: (isDerivation d) && ! ((d.meta or {}).broken or false))
  lispPackagesLite
