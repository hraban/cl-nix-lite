{
  description = "Demo cl-nix-lite app using flakes input overriding";
  inputs = {
    cl-nix-lite.url = "github:hraban/cl-nix-lite";
    fauxlexandria = {
      url = "github:hraban/fauxlexandria";
      flake = false;
    };
  };

  outputs = {
    self, nixpkgs, cl-nix-lite, fauxlexandria, flake-utils, ...
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
          cl-nix-lite.overlays.default
          (final: prev: {
            lispPackagesLite = prev.lispPackagesLite.overrideScope' (lfinal: lprev: {
              alexandria = lprev.alexandria.overrideAttrs (_: {
                src = fauxlexandria;
              });
            });
          })
        ];
      in
        {
          packages = {
            default = with pkgs.lispPackagesLite; lispDerivation {
              name = "flake-override-input";
              lispSystem = "flake-override-input";
              lispDependencies = [
                alexandria
                asdf
                arrow-macros
              ];
              src = pkgs.lib.cleanSource ./.;
              dontStrip = true;
              meta = {
                license = pkgs.lib.licenses.agpl3Only;
              };
            };
          };
        });
  }
