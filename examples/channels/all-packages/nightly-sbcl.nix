# Build all packages with latest SBCL
#
# Pass ‘rev’ to build a specific git revision by its ID
# Pass ‘ref’ to build a git reference, e.g. HEAD or refs/heads/mybranch

{ pkgs ? import <nixpkgs> {}
, url ? "https://git.code.sf.net/p/sbcl/sbcl"
# A single arg sbclOverride can be passed to change top-level options of the
# SBCL derivation in nixpkgs. Only really useful as a short-cut for CI.
, sbclOverride ? {}
, ...
}@args:

let
  src = builtins.fetchGit ({ inherit url; } // builtins.removeAttrs args ["pkgs" "sbclOverride"]);
  lisp = (pkgs.sbcl.override ({
    bootstrapLisp = pkgs.lib.getExe pkgs.sbcl;
  } // sbclOverride)).overrideAttrs {
    src = builtins.trace "SBCL from ${url} @ ${src.rev}" src;
  };
in
import ./. { inherit lisp; }
