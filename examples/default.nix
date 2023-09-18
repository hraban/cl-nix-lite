# Top-level derivation that builds all examples and discards them. This is
# mostly useful for CI, or if you want to build everything locally and push it
# to a binary cache.

{
  cl-nix-lite ? ../.
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
, lisp ? pkgs.sbcl
}:

let
  inherit (pkgs.lib) isDerivation;
  # Massage a test input into a list of derivations (for later flattening)
  all-inputs = input:
    if builtins.isPath input
    then all-inputs (pkgs.callPackage input { })
    else if isDerivation input
    then [ input ]
    else
      assert pkgs.lib.isAttrs input;
      builtins.filter isDerivation (builtins.attrValues input);
  # Simple paths which can just be imported directly
  channel-based-tests = builtins.map all-inputs [
    ./channels/all-packages
    ./channels/all-packages-wrapped
    ./channels/hello-binary
    ./channels/override-package
    ./channels/test-all
    ./channels/with-cffi
  ];
  # These need some more work
  flake-tests = [
    ./flakes/make-binary
    ./flakes/override-input
  ];
  flake-to-deriv = f: (builtins.getFlake (builtins.toString f)).packages.${builtins.currentSystem}.default;
in
# Outputting a list of all derivations (instead of e.g. a mock wrapper
# derivation) allows me to later filter this down to only derivations that need
# to be /built/, on CI. That allows you to exclude anything that already exists
# on cache. This is useful because otherwise it will redownload everything, just
# to throw it away immediately again.
pkgs.lib.lists.flatten (channel-based-tests ++ (map flake-to-deriv flake-tests))
