{
  cl-nix-lite ? import ../../..,
  pkgs ? import <nixpkgs> { overlays = [ cl-nix-lite ]; },
  lisp ? pkgs.sbcl,
}@args:

let
  inherit (pkgs) lib;
  lispPackagesLite = pkgs.lispPackagesLiteFor lisp;
in

lib.pipe lispPackagesLite [
  (builtins.mapAttrs (
    name: value:
    let
      ev = builtins.tryEval (
        let
          d = value.overrideAttrs { doCheck = true; };
        in
        if lib.isDerivation value && !(d.meta.broken or false) then d else null
      );
    in
    if ev.success then ev.value else null
  ))
  (lib.filterAttrs (n: d: d != null))
]
