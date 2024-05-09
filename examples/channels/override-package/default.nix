# Imagine wanting to use a very specific version of a package, e.g. to fix a
# regression, or a bug:

{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> {}
, lisp ? (f: "${pkgs.sbcl}/bin/sbcl --dynamic-space-size 4000 --script ${f}")
}:

let
  fauxlexandria = pkgs.fetchFromGitHub {
    owner = "hraban";
    repo = "fauxlexandria";
    rev = "aa0dc79717b4284cdcf1b5900bc6dbf2047b67bc";
    sha256 = "sha256-sTz9MI5vVORG8olmoUtYNreAkqW34yQZ0cu78AhAevM=";
  };
  # To override alexandria _everywhere_ on your entire nixpkgs, including the
  # lispPackagesLite that was set on nixpkgs itself, you can specify a nixpkgs
  # overlay, which overrides lispPackagesLite, with an overlay that just
  # overrides alexandria in there:
  pkgs' = pkgs.appendOverlays [
    # Set lispPackagesLite
    (import cl-nix-lite)
    # Now override alexandria in it
    (final: prev: {
      lispPackagesLite = (prev.lispPackagesLiteFor lisp).overrideScope (lfinal: lprev: {
        # And because I’m only overriding the source, not any build
        # instructions, I’m just overriding the existing derivation. But here of
        # course you could also set this to an entirely custom lispDerivation
        # you create yourself.
        alexandria = lprev.alexandria.overrideAttrs {
          src = fauxlexandria;
        };
      });
    })
  ];
in

# Just overriding alexandria will automatically make packages that /depend/ on
# alexandria pick up on the new definition. Like arrow-macros, for example:
pkgs'.lispPackagesLite.arrow-macros
