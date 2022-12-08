{
  pkgs ? import <nixpkgs> {}
  , lispPackagesLite ? import ../.. { inherit pkgs; }
}:

with lispPackagesLite;

lispDerivation {
  # Added a bunch of unnecessary deps to see how this system handles
  # deduplication
  lispDependencies = [ alexandria arrow-macros cl-async cl-async-ssl ];
  lispSystem = "with-cffi";
  version = "0.0.1";
  src = pkgs.lib.cleanSource ./.;
}