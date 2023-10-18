{
  description = "Demo lispPackagesLite app using flakes";
  inputs = {
    cl-nix-lite.url = "github:hraban/cl-nix-lite";
  };
  outputs = {
    self, nixpkgs, cl-nix-lite, flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.extend cl-nix-lite.overlays.default;
      in
        {
          packages = {
            default = with pkgs.lispPackagesLite; lispDerivation {
              name = "flake-app";
              lispSystem = "flake-app";
              lispDependencies = [
                alexandria
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
