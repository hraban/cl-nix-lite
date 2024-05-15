{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
, lisp ? pkgs.sbcl
}@args:

let
  derivs = p: builtins.attrValues (pkgs.lib.callPackageWith args p {});
  inherit (pkgs) lib;
in

lib.filter lib.isDerivation (lib.flatten (map derivs [ ./check-disabled.nix ./check-enabled.nix ]))
