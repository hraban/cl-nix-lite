# Build all packages with latest SBCL

{ pkgs ? import <nixpkgs> {} }:

let
  url = "https://git.code.sf.net/p/sbcl/sbcl";
  src = builtins.fetchGit { inherit url; };
  lisp = (pkgs.sbcl.override {
    bootstrapLisp = pkgs.lib.getExe pkgs.sbcl;
  }).overrideAttrs {
    src = builtins.trace "SBCL from ${url}@${src.rev}" src;
  };
in
import ./. { inherit lisp; }
