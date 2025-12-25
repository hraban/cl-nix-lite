{
  cl-nix-lite ? import ../../..,
  pkgs ? import <nixpkgs> { overlays = [ cl-nix-lite ]; },
  lisp ? pkgs.sbcl,
}:

with pkgs.lispPackagesLiteFor lisp;

lispDerivation {
  lispDependencies = [
    alexandria
    arrow-macros
    cl-async
    cl-async-ssl
  ];
  lispSystem = "with-cffi";
  version = "0.0.1";
  src = pkgs.lib.cleanSource ./.;
}
