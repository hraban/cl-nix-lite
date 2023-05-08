# Top-level derivation that builds all examples and discards them. This is
# mostly useful for CI, or if you want to build everything locally and push it
# to a binary cache.

{
  pkgs ? import <nixpkgs> {}
, lisp ? pkgs.sbcl
}:

let
  inherit (pkgs.lib) isDerivation;
  allInputs = input:
    if builtins.isPath input
    then allInputs (pkgs.callPackage input { })
    else if isDerivation input
    then [ input ]
    else
      assert pkgs.lib.isAttrs input;
      builtins.filter isDerivation (builtins.attrValues input);
in
# Outputting a list of all derivations (instead of e.g. a mock wrapper
# derivation) allows me to later filter this down to only derivations that need
# to be /built/, on CI. That allows you to exclude anything that already exists
# on cache. This is useful because otherwise it will redownload everything, just
# to throw it away immediately again.
pkgs.lib.lists.flatten (builtins.map allInputs [
  ./all-packages
  ./all-packages-wrapped
  ./hello-binary
  ./override-package
  ./test-all
  ./with-cffi
])
