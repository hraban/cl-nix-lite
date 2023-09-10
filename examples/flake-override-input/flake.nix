{
  description = "Demo lisp-packages-lite app using flakes input overriding";
  inputs = {
    cl-nix-lite = {
      url = "github:hraban/cl-nix-lite/flake?dir=flake/";
      inputs.alexandria = {
        url = "github:hraban/fauxlexandria";
	      flake = false;
      };
    };
  };

  outputs = {
    self, nixpkgs, cl-nix-lite, flake-utils, ...
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.extend cl-nix-lite.overlays.default;
      in
        {
          packages = {
            default = with pkgs.lisp-packages-lite; lispDerivation {
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
