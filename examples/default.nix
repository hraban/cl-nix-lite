# Top-level derivation that builds all examples and discards them. This is
# mostly useful for CI, or if you want to build everything locally and push it
# to a binary cache.

{
  cl-nix-lite ? import ../.,
  pkgs ? import <nixpkgs> { },
  withFlakes ? true,
}:

let
  inherit (pkgs) lib;
  pkgs' = pkgs.extend cl-nix-lite;
  lisps =
    builtins.filter
      (drv: !drv.meta.broken && lib.meta.availableOn { inherit (pkgs.stdenv.hostPlatform) system; } drv)
      (
        with pkgs';
        [
          abcl
          clasp-common-lisp
          clisp
          ecl
          sbcl
        ]
      );
  # Massage a test input into a list of derivations (for later flattening)
  allInputs =
    input:
    if lib.isDerivation input then
      [ input ]
    else if lib.isAttrs input then
      allInputs (builtins.attrValues input)
    else
      assert lib.isList input;
      builtins.filter lib.isDerivation input;
  # Simple paths which can just be imported directly
  channelTestPaths =
    lisp:
    [
      ./channels/all-packages
      ./channels/all-packages-wrapped
      ./channels/lisp-script
      ./channels/override-package
    ]
    ++ lib.optionals (lisp.pname != "abcl" && lisp.pname != "clasp") [
      ./channels/external-dependency
      ./channels/hello-binary
    ]
    ++ lib.optionals (
      !(builtins.elem lisp.pname [
        "abcl"
        "clisp"
        "clasp"
      ])
    ) [ ./channels/with-cffi ];
  channelTestsFor =
    lisp:
    let
      callPackage = pkgs'.lib.callPackageWith {
        pkgs = pkgs';
        inherit lisp cl-nix-lite;
      };
    in
    map (p: allInputs (callPackage p { })) (channelTestPaths lisp);
  channelTests = [ (pkgs'.callPackage ./channels/override-lisp { }) ] ++ (map channelTestsFor lisps);

  # These need some more work
  flakeTests = lib.optionals withFlakes [
    ./flakes/external-dependency
    ./flakes/lisp-script
    ./flakes/make-binary
    ./flakes/override-input
  ];
  flakeToDerivs =
    f:
    lib.pipe f [
      builtins.toString
      builtins.getFlake
      (x: x.packages.${pkgs.stdenv.hostPlatform.system})
      builtins.attrValues
    ];
in
# Outputting a list of all derivations (instead of e.g. a mock wrapper
# derivation) allows me to later filter this down to only derivations that need
# to be /built/, on CI. That allows you to exclude anything that already exists
# on cache. This is useful because otherwise it will redownload everything, just
# to throw it away immediately again.
lib.flatten channelTests ++ (map flakeToDerivs flakeTests)
