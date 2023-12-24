{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
, lisp ? pkgs.sbcl
}:

with pkgs.lispPackagesLiteFor lisp;

let
  hello-world = lispDerivation {
    src = pkgs.fetchFromSourcehut {
      owner = "~hraban";
      repo = "hello-world";
      rev = "9c5cf168d0cacfb3dc623bf5b669d04ba29ef2f9";
      hash = "sha256-4MlMYGoQWUHcJwZlPM0hNfxES/fZ3B2W2xag745nbLs=";
    };
    lispSystem = "hello-world";
    # If this needed dependencies from cl-nix-lite, you could pass them here:
    # lispDepencies = [ ... ];
  };
in

lispDerivation {
  lispSystem = "external-dependency";
  version = "0.0.1";
  dontStrip = true;
  src = pkgs.lib.cleanSource ./.;
  # You can now include this just like any other dependency
  lispDependencies = [ hello-world ];
}
