{ callPackage }:

let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  sourceInfo = lock.nodes.flake-compat.locked;
  flake-compat = fetchTarball {
    url = "https://github.com/${sourceInfo.owner}/${sourceInfo.repo}/archive/${sourceInfo.rev}.tar.gz";
    sha256 = sourceInfo.narHash;
  };
  flake = (callPackage flake-compat { src = ./.; }).defaultNix;
in
flake.inputs
