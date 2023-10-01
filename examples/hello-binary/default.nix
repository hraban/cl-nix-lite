{
  pkgs ? import <nixpkgs> {}
, cl-nix-lite ? pkgs.callPackage ../.. {}
}:

let
  pkgs' = pkgs.extend cl-nix-lite;
in

pkgs'.lispPackagesLite.lispDerivation {
  lispSystem = "hello-binary";
  version = "0.0.1";
  dontStrip = true;
  src = pkgs'.lib.cleanSource ./.;
}
