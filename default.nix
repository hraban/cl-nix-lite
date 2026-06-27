# nixpkgs overlay
final: prev: import ./lisp-packages-lite.nix { pkgs = prev; }
