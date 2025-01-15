{
  description = "Nix develop shell using lispPackagesLite";
  inputs = {
    cl-nix-lite.url = "github:hraban/cl-nix-lite/v0";
  };
  outputs = {
    self, nixpkgs, cl-nix-lite, flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.extend cl-nix-lite.overlays.default;
      in
      {
        devShells = {
          default = with pkgs.lispPackagesLite; lispDerivation {
            src = pkgs.lib.cleanSource ./.;
            lispSystem = "dev";
            lispDependencies = [ arrow-macros ];
          };
        };
      });
  }
