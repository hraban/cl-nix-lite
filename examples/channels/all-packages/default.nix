{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

with pkgs.lib;
with rec {
  # Compiling Shinmera/3d-math requires a lot of memory, might as well grant it
  lispPackagesLite = pkgs.lispPackagesLiteFor (f: "${pkgs.sbcl}/bin/sbcl --dynamic-space-size 4000 --script ${f}");
  isSafeLisp = d: let
    ev = builtins.tryEval (isDerivation d && !(d.meta.broken or false));
  in ev.success && ev.value;
};

attrsets.filterAttrs (_: isSafeLisp) lispPackagesLite
