{
  pkgs ? import ../../../../.. {}
  , lispPackagesLite ? pkgs.lispPackagesLite
}:

with lispPackagesLite;

lispDerivation {
  # cl-async is a good litmus test dependency because it uses CFFI
  lispDependencies = [ alexandria cl-async cffi ];
  lispSystem = "demo";
  version = "0.0.1";
  src = pkgs.lib.cleanSource ./.;
}
