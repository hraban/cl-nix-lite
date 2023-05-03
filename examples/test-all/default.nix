{
  pkgs ? import <nixpkgs> {}
  , skip ? [
    "_40ants-doc"
    "_40ants-doc-full"
    "arnesi"
    "fare-quasiquote"
    "flexi-streams"
    # I’m confused as to why this one is failing
    "gettext"
    "lack"
    "lack-request"
    "lift"
    "log4cl"
    "lparallel"
    "trivial-backtrace"
    "try"
    "typo"
  ]
}:

with pkgs.lib;

pipe (import ../.. { inherit pkgs; }) [
  (attrsets.filterAttrs (n: d:
    (pkgs.lib.isDerivation d) &&
    ! ((d.meta or {}).broken or false) &&
    ! (builtins.elem n skip)))
  (builtins.mapAttrs (k: v: v.enableCheck))
]
