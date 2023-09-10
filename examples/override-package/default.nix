# Imagine wanting to use a very specific version of a package, e.g. to fix a
# regression, or a bug:

{
  pkgs ? import <nixpkgs> {}
, cl-nix-lite ? import ../..
}:

let
  pkgs' = pkgs.extend cl-nix-lite;
  myAlexandria = pkgs'.lispPackagesLite.lispDerivation {
    lispSystem = "alexandria";
    src = pkgs'.fetchFromGitHub {
      name = "fauxlexandria-src";
      owner = "hraban";
      repo = "fauxlexandria";
      rev = "aa0dc79717b4284cdcf1b5900bc6dbf2047b67bc";
      sha256 = "sha256-sTz9MI5vVORG8olmoUtYNreAkqW34yQZ0cu78AhAevM=";
    };
  };
in

# Just overriding alexandria will automatically make packages that /depend/ on
# alexandria pick up on the new definition. Like arrow-macros, for example:
(pkgs'.lispPackagesLite.overrideScope' (self: super: {
  alexandria = myAlexandria;
})).arrow-macros
