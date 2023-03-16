{
  pkgs ? import <nixpkgs> {}
  , lispPackagesLite ? import ../.. { inherit pkgs; }
}:

with lispPackagesLite;

lispDerivation {
  src = pkgs.lib.cleanSource ./.;
  lispSystem = "dev";
  lispDependencies = [ arrow-macros ];
  buildInputs = [ pkgs.sbcl ];
}
