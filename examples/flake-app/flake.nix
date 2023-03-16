{
  description = "Demo lispPackagesLite app using flakes";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    cl-nix-lite = {
      flake = false;
      # Use "github:hraban/cl-nix-lite" here instead
      url = "path:../..";
    };
    # This is how you would override a package or include a new one
    asdf-src = {
      url = "git+https://gitlab.common-lisp.net/asdf/asdf";
      flake = false;
    };
  };
  outputs = {
    self, nixpkgs, asdf-src, cl-nix-lite, flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lispPackagesLite = import cl-nix-lite { inherit pkgs; };
      in
      with lispPackagesLite;
      let
        # Create a new lisp dependency on the fly from source. Note: this is not
        # the same as overridePackage - for overriding a deeper dependency to
        # automatically be picked up by other dependencies, make sure to see
        # that example. This is just for adding an entirely new dependency.
        asdf = lispDerivation {
          src = asdf-src;
          lispSystem = "asdf";
        };
      in
        {
          packages = {
            default = lispDerivation {
              name = "flake-app";
              lispSystem = "flake-app";
              lispDependencies = [
                # This is our own copy of asdf
                asdf
                # This came from the with lispPackagesLite scope
                alexandria
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
