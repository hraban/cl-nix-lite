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
  lisps = with pkgs'; [ abcl clisp ecl sbcl ];
  # Massage a test input into a list of derivations (for later flattening)
  allInputs = input:
    if isDerivation input
    then [ input ]
    else if isAttrs input
    then allInputs (builtins.attrValues input)
    else
      assert isList input;
      builtins.filter isDerivation input;
  # Simple paths which can just be imported directly
  channelTestPaths = lisp: [
    ./channels/all-packages
    ./channels/all-packages-wrapped
    ./channels/lisp-script
    ./channels/override-package
  ] ++ optionals (lisp.pname != "abcl") [
    ./channels/external-dependency
    ./channels/hello-binary
  ] ++ optionals (! (builtins.elem lisp.pname [ "abcl" "clisp" ])) [
    ./channels/with-cffi
  ];
  channelTestsFor = lisp:
    let
      callPackage = pkgs'.lib.callPackageWith {
        pkgs = pkgs';
        inherit lisp cl-nix-lite;
      };
    in
      map
        (p: allInputs (callPackage p { }))
        (channelTestPaths lisp);
  channelTests = [
    (pkgs'.callPackage ./channels/override-lisp { })
  ] ++ (map channelTestsFor lisps);

  # These need some more work
  flakeTests = [
    ./flakes/external-dependency
    ./flakes/lisp-script
    ./flakes/make-binary
    ./flakes/override-input
  ];
  flakeToDerivs = f: pipe f [
    builtins.toString
    builtins.getFlake
    (x: x.packages.${pkgs.system})
    builtins.attrValues
  ];
in
# Outputting a list of all derivations (instead of e.g. a mock wrapper
# derivation) allows me to later filter this down to only derivations that need
# to be /built/, on CI. That allows you to exclude anything that already exists
# on cache. This is useful because otherwise it will redownload everything, just
# to throw it away immediately again.
flatten channelTests ++ (map flakeToDerivs flakeTests)
