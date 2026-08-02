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
    flake-parts.lib.mkFlake { inherit inputs; } ({
      systems = import inputs.systems;
      imports =
        let
          checksModule = {
            perSystem =
              {
                config,
                self',
                lib,
                pkgs,
                ...
              }:
              let
                cfg = config.cl-nix-lite;
                examples = pkgs.callPackage ./examples {
                  cl-nix-lite = lib.composeExtensions (import ./.) (
                    final: prev: {
                      _lispPackagesLitePackages = lib.composeExtensions prev._lispPackagesLitePackages (
                        final.callPackage cfg.packages { }
                      );
                    }
                  );
                  withFlakes = false;
                };
                examplesDrvs = builtins.listToAttrs (
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
                  ) (builtins.filter lib.isDerivation examples)
                );
              in
              {
                options.cl-nix-lite = {
                  checks.enable = lib.mkEnableOption "Enable flake check outputs for this lisp module";
                  packages = lib.mkOption {
                    description = "lisp module package for this flake";
                    default = { }: _: _: { };
                    type = with lib.types; either path anything;
                  };
                  _examples = lib.mkOption {
                    description = "Full set of cl-nix-lite example derivations, for testing";
                    readOnly = true;
                    type = lib.types.package;
                  };
                };
                config = {
                  legacyPackages.lisp-examples = lib.mkIf cfg.checks.enable (
                    pkgs.linkFarm "lisp-examples" examplesDrvs
                  );
                  cl-nix-lite._examples = examplesDrvs;
                };
              };
          };
        in
        [
          inputs.treefmt-nix.flakeModule
          flake-parts.flakeModules.flakeModules
          checksModule
          ({
            flake.flakeModules.lispChecks = checksModule;
            flake.overlays.default = import ./.;
            perSystem =
              {
                config,
                lib,
                self',
                pkgs,
                ...
              }:
              let
                cl-nix-lite = import ./.;
                sources = import ./sources { inherit (pkgs) callPackage; };
                pkgs' = pkgs.extend cl-nix-lite;
              in
              {
                treefmt = import ./treefmt.nix { };
                packages.examples = config.cl-nix-lite._examples;
                packages.sources = pkgs.linkFarm "sources" sources;
                legacyPackages =
                  let
                    lisps = {
                      inherit (pkgs)
                        abcl
                        clisp
                        ecl
                        sbcl
                        ;
                      clasp = pkgs.clasp-common-lisp;
                    };
                  in
                  builtins.mapAttrs (
                    _: lisp:
                    let
                      lpl = pkgs'.lispPackagesLiteFor lisp;
                    in
                    lpl
                  ) lisps;
                #   checks = examples // {
                #     inherit (self'.packages) sources;
                #     unit-tests = (pkgs'.callPackage ./tests.nix { }).deriv;
                #     markdown-links =
                #       pkgs.runCommand "mkdocs-linkcheck"
                #         {
                #           nativeBuildInputs = [ pkgs.markdown-link-check ];
                #           cfg = builtins.toFile "mlc-config.json" (
                #             builtins.toJSON { ignorePatterns = [ { pattern = "^http"; } ]; }
                #           );
                #         }
                #         ''
                #           markdown-link-check -c $cfg ${./.}
                #           touch $out
                #         '';
                #   };
              };
          })
        ];
    });
}
