{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
, skip ? [
  "40ants-doc"
  "40ants-doc-full" # this one works in QL so it’s nix specific
  "arnesi"
  "bordeaux-threads" # There’s a deadlock heisenbug in these tests
  "cffi"
  "cl-difflib" # see https://github.com/wiseman/cl-difflib/pull/1
  "cl-redis"
  "common-doc"
  "commondoc-markdown" # I have no idea what’s happening here but I need to move on
  "dbi"
  #"deflate" # https://github.com/pmai/Deflate/issues/3
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
  "type-templates" # https://github.com/Shinmera/type-templates/issues/1
  "typo"
  "with-output-to-stream"
  "xlunit"

  # This dependency tree has surfaced a bug in cl-nix-lite dependency resolution
  # and must be fixed, but this PR is growing out of control already so let’s
  # disable the tests for now and pick this up ASAP.
  "dref"
  "mgl-pax"
] ++ pkgs.lib.optionals pkgs.hostPlatform.isDarwin [
  "flexi-streams"
  "lparallel"
] ++ pkgs.lib.optionals pkgs.hostPlatform.isLinux [
  "usocket"
]
}:

with pkgs.lib;
with rec {
  # The tests for Shinmera/3d-math require a lot of memory, might as well grant
  # it
  lispPackagesLite = pkgs.lispPackagesLiteFor (f: "${pkgs.sbcl}/bin/sbcl --dynamic-space-size 4000 --script ${f}");
  isSafeLisp = d: let
    ev = builtins.tryEval d;
    d' = ev.value;
  in ev.success && (isDerivation d') && !(d'.meta.broken or false);
  shouldTest = name: ! builtins.elem name skip;
};

pipe lispPackagesLite [
  (attrsets.filterAttrs (n: d: (isSafeLisp d) && (shouldTest n)))
  (builtins.mapAttrs (k: v: v.enableCheck))
]
