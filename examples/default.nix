# Top-level derivation that builds all examples and discards them. This is
# mostly useful for CI, or if you want to build everything locally and push it
# to a binary cache.

{
  cl-nix-lite ? ../.
, pkgs ? import <nixpkgs> { }
}:

with pkgs.lib;

let
  pkgs' = pkgs.extend (import cl-nix-lite);
  sbcl = f: "${pkgs'.sbcl}/bin/sbcl --dynamic-space-size 4000 --script ${f}";
  lisps = [ sbcl pkgs'.clisp pkgs'.ecl ];
  # Massage a test input into a list of derivations (for later flattening)
  allInputs = input:
    if isDerivation input
    then [ input ]
    else
      assert isAttrs input;
      builtins.filter isDerivation (builtins.attrValues input);
  # Simple paths which can just be imported directly
  channelTestPaths = lisp: [
    ./channels/all-packages
    ./channels/all-packages-wrapped
    ./channels/hello-binary
    ./channels/override-package
    ./channels/test-all
  ] ++ optionals (lisp.pname or "" != "clisp") [
    ./channels/with-cffi
  ];
  channelTestsFor = lisp:
    let
      callPackage = pkgs'.lib.callPackageWith { inherit lisp; };
    in
      map
        (p: allInputs (callPackage p { }))
        (channelTestPaths lisp);
  channelTests = [
    (pkgs'.callPackage ./channels/override-lisp { })
  ] ++ (map channelTestsFor lisps);

  # These need some more work
  flakeTests = [
    ./flakes/make-binary
    ./flakes/override-input
  ];
  flakeToDeriv = f: (builtins.getFlake (builtins.toString f)).packages.${builtins.currentSystem}.default;
in
# Outputting a list of all derivations (instead of e.g. a mock wrapper
# derivation) allows me to later filter this down to only derivations that need
# to be /built/, on CI. That allows you to exclude anything that already exists
# on cache. This is useful because otherwise it will redownload everything, just
# to throw it away immediately again.
flatten channelTests ++ (map flakeToDeriv flakeTests)
