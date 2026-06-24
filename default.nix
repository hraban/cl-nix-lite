# nixpkgs overlay
final: prev:
import ./lisp-packages-lite.nix {
  sources = import ./sources { inherit (prev) callPackage; };
  pkgs = prev;
}
