{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
}:

with pkgs.lispPackagesLite;

pkgs.mkShell {
  inputsFrom = [
    (lispWithSystems [ arrow-macros ])
  ];
}
