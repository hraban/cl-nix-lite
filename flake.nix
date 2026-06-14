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
      { lib, config, ... }:
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
              let
                examplesList = builtins.filter lib.isDerivation (
                  pkgs.callPackage ./examples {
                    cl-nix-lite = config.flake.overlays.default;
                    withFlakes = false;
                  }
                );
                examples = builtins.listToAttrs (
                  lib.imap0 (
                    i: d:
                    let
                      lispName = lib.optionalString (d ? lisp) "-${d.lisp.pname or d.lisp.name}";
                      # Periods are valid names for nix flake check
                      # attributes, but not if you pass the resulting attrset
                      # to ‘nix build’.  I’m not sure whence the discrepancy,
                      # but 🤷.  Passing the flake’s check attrset through a
                      # --dry-run to avoid building what’s already in the
                      # cache is a useful trick used on CI, so it’s worth
                      # keeping compatibility.
                      name = lib.replaceString "." "_" "${d.name}${lispName}-${toString i}";
                    in
                    lib.nameValuePair name d
                  ) examplesList
                );
              in
              {
                treefmt = import ./treefmt.nix { };
                packages.examples = pkgs.linkFarm "examples" examples;
                checks = examples // {
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
