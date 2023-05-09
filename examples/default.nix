# Top-level derivation that builds all examples and discards them. This is
# mostly useful for CI, or if you want to build everything locally and push it
# to a binary cache.

{
  pkgs ? import <nixpkgs> {}
}:

let
  inherit (pkgs.lib) isDerivation;
  # HACK: I can’t find a better / cleaner way to do this. It’s pretty
  # frustrating. Problems with this solution:
  #
  # - it’s not recursive (for speed)
  # - it doesn’t check all possible input sources (depsHostHost etc) (for
  #   legibility)
  # - It doesn’t catch any derivation included through string formatting
  #   (e.g. "${pkgs.clisp}/bin/clisp ...").
  #
  # Ideally I’d have something like tryEval { ... } catch (isBroken) or
  # whatever, but for some reason that’s not supported.
  isBroken' = drv: drv.meta.broken;
  isNotBroken = drv:
    ! (
      drv.meta.broken ||
      builtins.any (drv: drv.meta.broken)
                   (drv.buildInputs ++ drv.nativeBuildInputs)
    );
  # Extract all derivations from this path / set of derivations
  allDerivations = input:
    if builtins.isPath input
    then
      allDerivations (pkgs.callPackage input { }) ++
      # If CLISP is available on this system, and if the example allows
      # overriding lispPackagesLite, import the example again but offer it an
      # argument of lispPackagesLite with its lisp set to CLISP.
      (pkgs.lib.optionals (!pkgs.clisp.meta.broken) [(
        let
          callPackage = pkgs.newScope (pkgs // {
            lispPackagesLite = pkgs.callPackage ./.. {
              lisp = pkgs.clisp;
            };
          });
        in
          allDerivations (callPackage input { }))])
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
pkgs.lib.pipe [
  ./all-packages
  ./all-packages-wrapped
  ./hello-binary
  ./override-package
  ./test-all
  ./with-cffi
] [
  (builtins.map allDerivations)
  pkgs.lib.lists.flatten
  (builtins.filter isNotBroken)
]
