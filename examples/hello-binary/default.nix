{
  pkgs ? import <nixpkgs> {}
  , lispPackagesLite ? import ../.. { inherit pkgs; }
}:

with lispPackagesLite;

lispDerivation {
  lispSystem = "hello-binary";
  version = "0.0.1";
  src = pkgs.lib.cleanSource ./.;
}
