{
  pkgs ? import <nixpkgs> {}
, cl-nix-lite ? import ../..
}:

with (pkgs.extend cl-nix-lite).lispPackagesLite;

lispDerivation {
  lispDependencies = [ alexandria arrow-macros cl-async cl-async-ssl ];
  lispSystem = "with-cffi";
  version = "0.0.1";
  src = pkgs.lib.cleanSource ./.;
}
