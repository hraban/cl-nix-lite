{
  cl-nix-lite ? ../../..
, pkgs ? import <nixpkgs> { overlays = [ (import cl-nix-lite) ]; }
, lisp ? pkgs.sbcl
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
  "lack" # broken test configuration in asdf declarations
  "lift"
  "log4cl"
  "log4cl-extras"
  "moptilities"
  "reblocks"
  "reblocks-ui" # The test definition in the .asd looks broken
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
] ++ pkgs.lib.optionals pkgs.hostPlatform.isLinux [
  "usocket"
] ++ pkgs.lib.optionals (lisp.pname == "clisp") [
  "float-features" # *** - APPLY: too few arguments given to FIND
  "kmrcl" # odd floating point error on clisp
  "trivial-custom-debugger" # *** - Condition of type TRIVIAL-CUSTOM-DEBUGGER/TEST::MY-ERROR.
] ++ pkgs.lib.optionals (lisp.pname == "ecl") [
  "data-lens" # Tests fail
  "cl-markdown" # > The function LIFT::GET-BACKTRACE-AS-STRING is undefined..
  "cl-prevalence" # Tests fail
  "legion" # hangs forever on ECL
  "trivial-custom-debugger" #An error occurred during initialization: #<a TRIVIAL-CUSTOM-DEBUGGER/TEST::MY-ERROR 0x105c49d80>.
  "type-i" # hangs forever on ECL
] ++ pkgs.lib.optionals (lisp.pname == "clisp" && pkgs.hostPlatform.isLinux) [
  "3bmd-ext-code-blocks"
] ++ pkgs.lib.optionals ((lisp.pname == "ecl" && pkgs.hostPlatform.isLinux) || pkgs.hostPlatform.isDarwin) [
  # On ECL & Linux: ;;; Unknown keyword :HANDLED
  "lparallel"
] ++ pkgs.lib.optionals (builtins.elem lisp.pname [ "ecl" "clisp" ]) [
  "fset" # https://github.com/slburson/fset/issues/42
] ++ pkgs.lib.optionals (! (builtins.elem lisp.pname [ "ecl" "clisp" ]) && pkgs.system == "x86_64-darwin") [
  # Oddly specific failure: "https://github.com/fukamachi/anypool/issues/5".
  "anypool"
] ++ pkgs.lib.optionals (! (builtins.elem lisp.pname [ "ecl" "clisp" ]) && pkgs.system == "x86_64-linux") [
  # https://github.com/edicl/flexi-streams/issues/51".  This technically only
  # affects SBCL 2.4.4 but I can’t check the SBCL version here.  Oh well.
  "flexi-streams"
]
}@args:

let
  inherit (pkgs) lib;
  lispPackagesLite = pkgs.lispPackagesLiteFor lisp;
  shouldTest = name: ! builtins.elem name skip;
in

lib.pipe lispPackagesLite [
  (builtins.mapAttrs (name: value: let
    ev = builtins.tryEval (let
      d = value.enableCheck;
    in
      if shouldTest name && lib.isDerivation value && !(d.meta.broken or false)
      then d
      else null);
    in
      if ev.success && ev.value != null
      then ev.value
      else null))
  (lib.filterAttrs (n: d: d != null))
]
