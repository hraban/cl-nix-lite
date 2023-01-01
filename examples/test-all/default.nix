{
  pkgs ? import ../../../../.. {}
  , lispPackagesLite ? pkgs.lispPackagesLite
  , skip ? [
    # https://github.com/AccelerationNet/arnesi/issues/2
    "arnesi"
    "arnesi-cl-ppcre-extras"
    "arnesi-slime-extras"

    "fare-quasiquote"
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

pkgs.lib.pipe lispPackagesLite [
  (pkgs.lib.attrsets.filterAttrs (n: v:
    (pkgs.lib.attrsets.isDerivation v) && !(builtins.elem n skip)
  ))
  (builtins.mapAttrs (k: v: v.enableCheck))
]
