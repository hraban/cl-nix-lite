{
  description = "Demo lispPackagesLite app using flakes";
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
          packages = {
            default = lispDerivation {
              name = "flake-app";
              lispSystem = "flake-app";
              lispDependencies = [
                alexandria
                asdf
                arrow-macros
              ];
              src = pkgs.lib.cleanSource ./.;
              meta = {
                license = pkgs.lib.licenses.agpl3Only;
              };
            };
          };
        });
  }
