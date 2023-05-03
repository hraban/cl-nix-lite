{
  pkgs ? import <nixpkgs> {}
  , skip ? [
    "_40ants-doc"
    "_40ants-doc-full" # this one works in QL so it’s nix specific
    "arnesi"
    "cffi"
    "cl-markdown"
    "cl-redis"
    "common-doc"
    "commondoc-markdown" # https://github.com/40ants/commondoc-markdown/pull/6
    "dbi"
    "dynamic-classes"
    "fare-quasiquote"
    "flexi-streams"
    "gettext" # I’m confused as to why this one is failing
    "hamcrest"
    "lack"
    "lack-full"
    "lack-request"
    "lift"
    "log4cl"
    "log4cl-extras"
    "lparallel"
    "moptilities"
    "reblocks"
    "routes"
    "rutils"
    "spinneret"
    "str"
    "trivial-backtrace"
    "trivial-timeout"
    "try"
    "typo"
    "with-output-to-stream"
    "xlunit"
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
