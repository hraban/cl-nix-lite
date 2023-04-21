{
  pkgs ? import <nixpkgs> {}
  , lispPackagesLite ? import ../.. { inherit pkgs; }
}:

with lispPackagesLite;

lispDerivation {
  lispSystem = "hello-binary";
  version = "0.0.1";
  dontStrip = true;
  src = pkgs.lib.cleanSource ./.;
}
