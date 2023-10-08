{
  cl-nix-lite ? ../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
, skip ? [
  "_40ants-doc"
  "_40ants-doc-full" # this one works in QL so it’s nix specific
  "arnesi"
  "bordeaux-threads" # There’s a deadlock heisenbug in these tests
  "cffi"
  "cl-difflib" # see https://github.com/wiseman/cl-difflib/pull/1
  "cl-redis"
  "common-doc"
  "dbi"
  "dynamic-classes"
  "fare-quasiquote"
  "gettext" # I’m confused as to why this one is failing
  "hamcrest"
  "hunchentoot" # https://github.com/edicl/hunchentoot/issues/217
  "lack"
  "lack-full"
  "lack-request"
  "lift"
  "log4cl"
  "log4cl-extras"
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
] ++ pkgs.lib.optionals pkgs.hostPlatform.isDarwin [
  "flexi-streams"
  "lparallel"
] ++ pkgs.lib.optionals pkgs.hostPlatform.isLinux [
  "usocket"
]
}:

with pkgs.lib;

pipe pkgs.lispPackagesLite [
  (attrsets.filterAttrs (n: d:
    (isDerivation d) &&
    ! ((d.meta or {}).broken or false) &&
    ! (builtins.elem n skip)))
  (builtins.mapAttrs (k: v: v.enableCheck))
]
