{
  description = "Demo lispPackagesLite app using flakes";
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
          # This is a demo of how to use lispPackagesLite, not a demo of how to
          # write the perfect minimal DRY flake.nix. Hence the code duplication
          # 🙂
          packages = {
            # This is how you would create a derivation using SBCL (the default)
            sbcl = with pkgs.lispPackagesLite; lispDerivation {
              name = "flake-app";
              lispSystem = "flake-app";
              lispDependencies = [
                alexandria
                arrow-macros
              ];
              src = pkgs.lib.cleanSource ./.;
              dontStrip = true;
              meta = {
                license = pkgs.lib.licenses.agpl3Only;
              };
            };
            # This uses CLISP
            clisp = with pkgs.lispPackagesLiteFor pkgs.clisp; lispDerivation {
              name = "flake-app";
              lispSystem = "flake-app";
              lispDependencies = [
                alexandria
                arrow-macros
              ];
              src = pkgs.lib.cleanSource ./.;
              meta = {
                license = pkgs.lib.licenses.agpl3Only;
              };
            };
            # This uses ECL
            ecl = with pkgs.lispPackagesLiteFor pkgs.ecl; lispDerivation {
              name = "flake-app";
              lispSystem = "flake-app";
              lispDependencies = [
                alexandria
                arrow-macros
              ];
              src = pkgs.lib.cleanSource ./.;
              meta = {
                license = pkgs.lib.licenses.agpl3Only;
              };
            };
            # Error using ABCL:
            # Not (currently) implemented on ABCL: UIOP/IMAGE:DUMP-IMAGE dumping an executable
          };
        });
  }
