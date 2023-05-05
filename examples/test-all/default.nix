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
    "dbi"
    "dynamic-classes"
    "fare-quasiquote"
    "gettext" # I’m confused as to why this one is failing
    "hamcrest"
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
  ] ++ pkgs.lib.optionals pkgs.hostPlatform.isLinux (
    [
      "hunchentoot"
      "usocket"
    ] ++ pkgs.lib.optionals pkgs.hostPlatform.isx86 [
      # There’s a deadlock bug in tests on x86 linux
      "bordeaux-threads"
    ]
  )
  # ?? Windows ??
}:

with pkgs.lib;

pipe (import ../.. { inherit pkgs; }) [
  (attrsets.filterAttrs (n: d:
    (pkgs.lib.isDerivation d) &&
    ! ((d.meta or {}).broken or false) &&
    ! (builtins.elem n skip)))
  (builtins.mapAttrs (k: v: v.enableCheck))
]
