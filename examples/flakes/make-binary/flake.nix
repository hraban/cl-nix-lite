{
  description = "Demo lispPackagesLite app using flakes";
  inputs = {
    cl-nix-lite.url = "github:hraban/cl-nix-lite";
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
              # ECL has very bespoke build instructions. See
              # https://ecl.common-lisp.dev/static/manual/System-building.html#Build-it-as-an-single-executable
              lispBuildPhase = ''
                (load "${asdf}/build/asdf.lisp")
                (let ((sys "flake-app"))
                  (asdf:load-system sys)
                  (asdf:make-build sys
                                   :type :program
                                   :move-here #P"./bin/"
                                   :epilogue-code `(progn
                                                    (,(read-from-string
                                                       (asdf::component-entry-point
                                                        (asdf:find-system sys))))
                                                    (quit))))
              '';
              src = pkgs.lib.cleanSource ./.;
              meta = {
                license = pkgs.lib.licenses.agpl3Only;
              };
            };
          };
        });
  }
