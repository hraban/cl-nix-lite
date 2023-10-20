{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
, lisp ? (f: "${pkgs.sbcl}/bin/sbcl --dynamic-space-size 4000 --script ${f}")
}:

with pkgs.lispPackagesLiteFor lisp;

lispDerivation {
  lispDependencies = [ alexandria arrow-macros cl-async cl-async-ssl ];
  lispSystem = "with-cffi";
  version = "0.0.1";
  src = pkgs.lib.cleanSource ./.;
}
