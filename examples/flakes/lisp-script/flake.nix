{
  inputs = {
    cl-nix-lite.url = "github:hraban/cl-nix-lite";
  };

  outputs = { self, nixpkgs, flake-utils, cl-nix-lite }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.extend cl-nix-lite.overlays.default;
      in {
        packages.default = with pkgs.lispPackagesLite; lispScript {
          name = "format-json";
          dependencies = [ yason ];
          src = ./main.lisp;
        };
      });
}
