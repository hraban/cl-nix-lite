# Top-level derivation that builds all examples and discards them. This is
# mostly useful for CI, or if you want to build everything locally and push it
# to a binary cache.

{
  pkgs ? import <nixpkgs> {}
, lisp ? pkgs.sbcl
}:

let
  inherit (pkgs) lib;
  callPackageClisp = pkgs.newScope (pkgs // {
    lispPackagesLite = pkgs.callPackage ./.. {
      lisp = pkgs.clisp;
    };
  });
  # Massage a test input into a list of derivations (for later flattening)
  all-inputs' = input:
    if lib.isDerivation input
    then [ input ]
    else if lib.isAttrs input
    then builtins.attrValues input
    # Ignore non-derivation inputs
    else [];
  all-inputs = input:
    (all-inputs' (pkgs.callPackage input { })) ++
    (all-inputs' (callPackageClisp input { }));
  # Simple paths which can just be imported directly
  channel-based-tests = builtins.map all-inputs [
    ./all-packages
    ./all-packages-wrapped
    ./hello-binary
    ./override-package
    ./test-all
    ./with-cffi
  ];
  # These need some more work
  flake-tests = [
    ./flake-app
  ];
  flake-to-deriv = f: (builtins.getFlake (builtins.toString f)).packages.${builtins.currentSystem}.default;
in
# Outputting a list of all derivations (instead of e.g. a mock wrapper
# derivation) allows me to later filter this down to only derivations that need
# to be /built/, on CI. That allows you to exclude anything that already exists
# on cache. This is useful because otherwise it will redownload everything, just
# to throw it away immediately again.
pkgs.lib.lists.flatten (channel-based-tests ++ (map flake-to-deriv flake-tests))
