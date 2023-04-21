{
  pkgs ? import <nixpkgs> {}
  , lispPackagesLite ? import ../.. { inherit pkgs; }
}:

with lispPackagesLite;

lispDerivation {
  lispDependencies = [ alexandria arrow-macros cl-async cl-async-ssl ];
  lispSystem = "with-cffi";
  version = "0.0.1";
  src = pkgs.lib.cleanSource ./.;
}
