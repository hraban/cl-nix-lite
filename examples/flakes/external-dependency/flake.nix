{
  description = "Demo lispPackagesLite app using an external dependency";

  inputs = {
    cl-nix-lite.url = "github:hraban/cl-nix-lite/v0";
    hello-world = {
      url = "sourcehut:~hraban/hello-world";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, cl-nix-lite, hello-world }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.extend cl-nix-lite.overlays.default;
      in {
        packages = with pkgs.lispPackagesLite; {
          # I like exposing these "internal" packages as top-level flake outputs
          # because it makes debugging easier, but you can also declare this in
          # the ‘let’ block higher up and use that, instead.
          hello = lispDerivation {
            src = hello-world;
            lispSystem = "hello-world";
          };
          default = lispDerivation {
            lispSystem = "external-dependency";
            name = "external-dependency";
            version = "0.0.1";
            dontStrip = true;
            src = pkgs.lib.cleanSource ./.;
            # You can now include this just like any other dependency
            lispDependencies = [ self.packages.${system}.hello ];
          };
        };
      });
}
