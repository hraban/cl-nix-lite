{
  description = "Nix develop shell using lispPackagesLite";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    cl-nix-lite = {
      flake = false;
      url = "github:hraban/cl-nix-lite";
    };
  };
  outputs = {
    self, nixpkgs, cl-nix-lite, flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lispPackagesLite = import cl-nix-lite { inherit pkgs; };
      in
      with lispPackagesLite;
      {
        devShells = {
          default = lispDerivation {
            src = pkgs.lib.cleanSource ./.;
            lispSystem = "dev";
            lispDependencies = [ arrow-macros ];
            buildInputs = [ pkgs.sbcl ];
          };
        };
      });
  }
