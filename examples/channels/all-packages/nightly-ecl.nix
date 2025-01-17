# Latest ECL from git
#
# Pass ‘rev’ to build a specific git revision by its ID
# Pass ‘ref’ to build a git reference, e.g. HEAD or refs/heads/mybranch

{ pkgs ? import <nixpkgs> {}
, url ? "https://gitlab.com/embeddable-common-lisp/ecl.git"
, ...
}@args:

let
  src = builtins.fetchGit ({ inherit url; } // builtins.removeAttrs args ["pkgs"]);
in
pkgs.ecl.overrideAttrs (old: {
  src = builtins.trace "ECL from ${url} @ ${src.rev}" src;
  version = "${old.version}-next";
})
