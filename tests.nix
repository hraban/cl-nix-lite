{
  lib,
  lispPackagesLite,
  runCommand,
}:

let
  emptyDir = runCommand "empty" { } "mkdir $out";
  results = lib.runTests {
    testInstallPhase = {
      expr =
        let
          d =
            with lispPackagesLite;
            lispDerivation {
              lispSystem = "test";
              src = emptyDir;
              installPhase = "foobar";
            };
        in
        d.installPhase;
      expected = "foobar";
    };
  };
  deriv = runCommand "tests" {
    result = builtins.toJSON ([ ] == (builtins.deepSeq (map (x: lib.traceValSeq x) results) results));
  } "$result && touch $out";
in
{
  inherit results deriv;
}
