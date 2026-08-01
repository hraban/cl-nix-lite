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
    testCheckDependencies = with lispPackagesLite; {
      expr =
        let
          d1 = lispDerivation {
            lispSystem = "d1";
            src = emptyDir;
            lispCheckDependencies = [ fiveam ];
          };
          d2 = lispDerivation (self: {
            lispSystem = "d1";
            src = emptyDir;
            lispDependencies = lib.optionals (self.doCheck or false) [ fiveam ];
          });
        in
        {
          nocheck1 = d1.passthru._origLispDependencies;
          nocheck2 = d2.passthru._origLispDependencies;
          check1 = (d1.overrideAttrs { doCheck = true; }).passthru._origLispDependencies;
          check2 = (d2.overrideAttrs { doCheck = true; }).passthru._origLispDependencies;
        };
      expected = {
        nocheck1 = [ ];
        nocheck2 = [ ];
        check1 = [ fiveam ];
        check2 = [ fiveam ];
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
