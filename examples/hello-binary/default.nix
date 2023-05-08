{
  pkgs ? import <nixpkgs> {}
, lispPackagesLite ? import ../.. { inherit pkgs; }
}:

with lispPackagesLite;

lispDerivation {
  lispSystem = "hello-binary";
  version = "0.0.1";
  dontStrip = true;
  lispDependencies = [ arrow-macros ];
  src = pkgs.lib.cleanSource ./.;
}
