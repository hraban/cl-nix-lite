{
  description = "Emacs, SLIME and SBCL in one derivation";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    cl-nix-lite = {
      flake = false;
      url = "github:hraban/cl-nix-lite";
    };
  };
  outputs = {
    self, nixpkgs, cl-nix-lite, flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lispPackagesLite = import cl-nix-lite { inherit pkgs; };
      in
        {
          packages = {
            emacs = with pkgs; ((emacsPackagesFor emacs).emacsWithPackages (e: [
              e.slime
            ]));
            lisp = lispPackagesLite.lispWithSystems (
              pkgs.lib.pipe lispPackagesLite [
                builtins.attrValues
                (builtins.filter (d: (pkgs.lib.isDerivation d) && ! ((d.meta or {}).broken or false)))
              ]);
            default = pkgs.stdenv.mkDerivation {
              pname = "emacs";
              version = "0.1";
              dontUnpack = true;
              nativeBuildInputs = [ pkgs.makeWrapper ];
              installPhase = ''
                mkdir -p $out/bin
                cd ${self.packages.${system}.emacs}/bin
                for f in *; do
                  makeWrapper $f $out/bin/$f --suffix PATH : ${self.packages.${system}.lisp}/bin
                done
              '';
            };
          };
        });
  }
