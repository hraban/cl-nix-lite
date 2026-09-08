{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    # All below for local dev only, not used for actual overlay
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
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
      let
        flakeModule = {
          perSystem =
            {
              config,
              lib,
              pkgs,
              system,
              ...
            }:
            let
              cfg = config.cl-nix-lite;
              examples = import ./examples {
                inherit pkgs;
                # Because pkgs here already has a cl-nix-lite overlay applied to
                # it, no need to reapply it.  However, the tests are written
                # assuming that pkgs doesn’t have it, and that cl-nix-lite must
                # be applied by the tests.  Easiest way to solve that: pass a
                # stub cl-nix-lite which is just a NOP overlay.
                cl-nix-lite = _: _: { };
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
                enable = lib.mkEnableOption "Enable the cl-nix-lite flake module";
                checks.enable = lib.mkEnableOption "Enable flake check outputs for this lisp module";
                packages = lib.mkOption {
                  description = "lisp module packages overlay for this flake";
                  default = _: _: { };
                  type = with lib.types; either path anything;
                };
                _examples = lib.mkOption {
                  description = "Full set of cl-nix-lite example derivations, for testing";
                  readOnly = true;
                  type = with lib.types; attrsOf package;
                };
                setPkgs = lib.mkOption {
                  type = lib.types.bool;
                  description = "Apply cl-nix-lite overlay to the flake's pkgs";
                  default = false;
                };
              };
              config = lib.mkIf cfg.enable {
                cl-nix-lite._examples = examplesDrvs;
                checks = lib.mkIf cfg.checks.enable examplesDrvs;
                _module.args.pkgs = lib.mkIf cfg.setPkgs (
                  import inputs.nixpkgs {
                    inherit system;
                    overlays = [
                      (import ./.)
                      (final: prev: {
                        _lispPackagesLitePackages = final.lib.composeExtensions prev._lispPackagesLitePackages cfg.packages;
                      })
                    ];
                  }
                );
              };
            };
        };
      in
      {
        systems = import inputs.systems;
        imports = [
          inputs.treefmt-nix.flakeModule
          flake-parts.flakeModules.flakeModules
          flakeModule
          ({
            flake.flakeModules.default = flakeModule;
            flake.overlays.default = import ./.;
            perSystem =
              {
                config,
                lib,
                self',
                pkgs,
                ...
              }:
              {
                cl-nix-lite = {
                  enable = true;
                  checks.enable = true;
                  setPkgs = true;
                };
                treefmt = import ./treefmt.nix { };
                packages.examples = pkgs.linkFarm "examples" config.cl-nix-lite._examples;
                packages.sources = pkgs.linkFarm "sources" pkgs.lispPackagesLite._sources;
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
                      lpl = pkgs.lispPackagesLiteFor lisp;
                    in
                    lpl
                  ) lisps;
                checks = {
                  inherit (self'.packages) sources;
                  unit-tests = (pkgs.callPackage ./tests.nix { }).deriv;
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
