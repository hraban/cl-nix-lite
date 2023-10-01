# This is necessary because this flake compat layer uses fixed output
# derivations, which use nixpkgs fetchers. The final derivation won’t use this
# pkgs tho--that’s an overlay, and it uses the nixpkgs on which it’s overlayed.
{ pkgs ? import <nixpkgs> {} }:

let
  lock = builtins.fromJSON (builtins.readFile ./flake/flake.lock);
  sourceInfo = lock.nodes.flake-compat.locked;
  flake-compat = fetchTarball {
    url = "https://github.com/${sourceInfo.owner}/${sourceInfo.repo}/archive/${sourceInfo.rev}.tar.gz";
    sha256 = sourceInfo.narHash;
  };
  # Use callPackage just in case we sub for a flake-compat which doesn’t need
  # nixpkgs.
  flake = (pkgs.callPackage flake-compat { src = ./flake; }).defaultNix;
in
flake.overlays.default
