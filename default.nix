# Export an overlay
final: prev:
import ./lisp-packages-lite.nix {
  inputs = import ./sources { inherit (prev) callPackage; };
  pkgs = prev;
}
