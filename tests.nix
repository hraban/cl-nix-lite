{
  lib,
  lispPackagesLite,
  runCommand,
}:

let
  emptyDir = runCommand "empty" { } "mkdir $out";
  results = lib.runTests {
    testPhases = {
      expr =
        let
          d =
            with lispPackagesLite;
            lispDerivation {
              lispSystem = "test";
              src = emptyDir;
              buildPhase = "build";
              checkPhase = "check";
              installPhase = "install";
            };
        in
        {
          inherit (d) buildPhase checkPhase installPhase;
        };
      expected = {
        buildPhase = "build";
        checkPhase = "check";
        installPhase = "install";
      };
    };
    testOverrideAttrs = {
      expr =
        let
          d =
            with lispPackagesLite;
            lispDerivation {
              lispSystem = "test";
              src = emptyDir;
              installPhase = "original";
            };
          d' = d.overrideAttrs { installPhase = "override"; };
        in
        {
          pre = d.installPhase;
          post = d'.installPhase;
        };
      expected = {
        pre = "original";
        post = "override";
      };
    };
    testFixpoint = {
      expr =
        let
          d =
            with lispPackagesLite;
            lispDerivation (self: {
              lispSystem = "test";
              src = emptyDir;
              installPhase = "foo" + lib.optionalString (self.doCheck or false) "bar";
            });
          d' = d.overrideAttrs { doCheck = true; };
        in
        {
          pre = d.installPhase;
          post = d'.installPhase;
        };
      expected = {
        pre = "foo";
        post = "foobar";
      };
    };
  };
  deriv = runCommand "tests" {
    result = builtins.toJSON ([ ] == (builtins.deepSeq (map (x: lib.traceValSeq x) results) results));
  } "$result && touch $out";
in
{
  inherit results deriv;
}
