{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    # All below for local dev only, not used for actual overlay
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    systems.url = "github:nix-systems/default";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  nixConfig = {
    extra-substituters = [ "https://cl-nix-lite.cachix.org" ];
    extra-trusted-public-keys = [
      "cl-nix-lite.cachix.org-1:ab6+b0u2vxymMLcZ5DDqPKnxz0WObbMszmC+BDBHpFc="
    ];
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { config, ... }:
      {
        systems = import inputs.systems;
        imports = [
          inputs.treefmt-nix.flakeModule
          ({
            flake.overlays.default = import ./.;
            perSystem =
              {
                self,
                lib,
                pkgs,
                ...
              }:
              {
                treefmt = import ./treefmt.nix { };
                checks =
                  let
                    examples = pkgs.callPackage ./examples {
                      cl-nix-lite = config.flake.overlays.default;
                      withFlakes = false;
                    };
                  in
                  builtins.listToAttrs (map (d: lib.nameValuePair d.name d) (lib.flatten examples))
                  // {
                    markdown-links =
                      pkgs.runCommand "mkdocs-linkcheck"
                        {
                          nativeBuildInputs = [ pkgs.markdown-link-check ];
                          cfg = builtins.toFile "mlc-config.json" (
                            builtins.toJSON { ignorePatterns = [ { pattern = "^http"; } ]; }
                          );
                        }
                        ''
                          markdown-link-check -c $cfg ${./.}
                          touch $out
                        '';
                  };
              };
          })
        ];
      }
    );
}
