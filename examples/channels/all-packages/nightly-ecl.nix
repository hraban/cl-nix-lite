# Build all packages with latest ECL

{ pkgs ? import <nixpkgs> {} }:

let
  url = "https://gitlab.com/embeddable-common-lisp/ecl.git";
  src = builtins.fetchGit { inherit url; };
  lisp = pkgs.ecl.overrideAttrs {
    src = builtins.trace "ECL from ${url}@${src.rev}" src;
  };
in
import ./. { inherit lisp; }
