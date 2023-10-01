# Export an overlay
final: prev:
let
  lock = builtins.fromJSON (builtins.readFile ./inputs/flake.lock);
  sourceInfo = lock.nodes.flake-compat.locked;
  flake-compat = fetchTarball {
    url = "https://github.com/${sourceInfo.owner}/${sourceInfo.repo}/archive/${sourceInfo.rev}.tar.gz";
    sha256 = sourceInfo.narHash;
  };
  flake = (prev.callPackage flake-compat { src = ./inputs; }).defaultNix;
in
import ./lisp-packages-lite.nix { inherit (flake) inputs; pkgs = prev; }
