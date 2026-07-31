# Copyright © 2022  Hraban Luyat
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

{ pkgs, lib }:

rec {
  # Like foldr but without a nul-value. Doesn’t support actual ‘null’ in the
  # list because I don’t know how to make singletons (is that even possible in
  # Nix?) and because I don’t care.
  reduce = (
    op: seq:
    assert !builtins.elem null seq; # N.B.: THIS MAKES IT STRICT!
    lib.foldr (a: b: if b == null then a else (op a b)) null seq
  );

  # Turn a derivation path into a context-less string. I suspect this isn’t in
  # the stdlib because this is a perversion of a low-level feature, not intended
  # for casual access in regular derivations.
  drvStrWithoutContext = x: builtins.head (builtins.attrNames (builtins.getContext (toString x)));

  # optionalKeys [ "a" "b" ] { a = 1; b = 2; c = 3; }
  # => { a = 1; b = 2; }
  # optionalKeys [ ] { a = 1; b = 2; c = 3; }
  # => { }
  # optionalKeys [ "a" "b" ] { a = 1; }
  # => { a = 1; }
  # optionalKeys [ "a" "b" ] { }
  # => { }
  optionalKeys = keys: lib.filterAttrs (k: v: builtins.elem k keys);

  # Like the inverse of lists.remove but takes a test function instead of an
  # element
  # (a -> Bool) -> [a] -> [a]
  keepBy = f: lib.foldr (a: b: lib.optionals (f a) [ a ] ++ b) [ ];

  # If argument is a function, call it with a constant value. Otherwise pass it
  # through.
  callIfFunc = val: f: if lib.isFunction f then f val else f;

  flatMap = f: xs: lib.flatten (map f xs);

  normaliseStrings = s: lib.unique (lib.naturalSort s);

  # This is a /nested/ union operation on attrsets: if you have e.g. a 2-layer
  # deep set (so a set of sets, so [ { String => { String => T } } ]), you can
  # pass 2 here to union them all.
  #
  # s = [
  #       { foo = { foo-bar = true ; foo-bim = true ; } ; }
  #       { foo = { foo-zom = true ; } ; bar = { bar-a = true ; } ; }
  # ]
  #
  # nestedUnion (_: true) 1 s
  # => { foo = true; bar = true; }
  # nestedUnion (_: true) 2 s
  # => {
  #      bar = { bar-a = true; };
  #      foo = { foo-bar = true; foo-bim = true; foo-zom = true; };
  #    }
  #
  # This convention is inspired by the representation of string context.
  #
  # The item function is a generator for the leaf nodes. It is passed the list
  # of values to union.
  #
  # Tip:
  # - nestedUnion head 1 [ a b ] == b // a
  # - nestedUnion tail 1 [ a b ] == a // b
  nestedUnion =
    item: n: sets:
    if n == 0 then item sets else lib.zipAttrsWith (_: vals: nestedUnion item (n - 1) vals) sets;

  getLispDeps = x: x.CL_SOURCE_REGISTRY or "";

  # Get a context-less string representing this source derivation, come what
  # come may.
  derivPath =
    src:
    drvStrWithoutContext (
      if
        builtins.isPath src
      # Purely a developer ergonomics feature. Don’t rely on this for published
      # libs. It breaks pure eval.
      then
        builtins.path { path = src; }
      else
        src
    );

  isLispDeriv = x: x ? lispSystems;

  # For a “lisp callable” function (see public API), get an array of all its
  # derivations. E.g. for ‘f: "${pkgs.sbcl}/bin/sbcl --script ${f}"’ this
  # returns [ pkgs.sbcl ].
  lispFuncDerivations =
    lisp:
    assert lib.isFunction lisp;
    # Extremely hacky but it works. Assume that any derivation we’re interested
    # in lives in the string context. This is painful because we’re doing
    # runtime imports for every single derivation, only really for nix-shell
    # purposes which is a tiny fraction of actual use. But it’s just such a nice
    # feature to have the correct lisp right there in your shell that I’m loath
    # to remove this until it’s absolutely necessary.
    map (d: import d) (builtins.attrNames (builtins.getContext (lisp "sentinel")));

  # Normalize the external lisp argument (see API of scope) to an easy-to-use
  # attrset.
  makeLisp =
    lisp:
    if builtins.isFunction lisp then
      rec {
        call = lisp;
        name = lib.getName deriv;
        # This is getting insane, and I’m sure I will come to regret this as it’s
        # _way_ too much magic, but here goes: this is a heuristic, do-what-I-mean
        # extraction of a sensible "derivation" from a "lisp" argument. Of course,
        # if the passed lisp is an actual derivation like pkgs.sbcl: easy, that’s
        # what it is.  But what if it’s a callback function, like (f:
        # "${pkgs.sbcl}/bin/sbcl --some-options ... ${f}")? Well... there’s still
        # the real sbcl hidden in there. Extract it through the string context
        # (which could have multiple derivations but that’s crazy talk, so just
        # choose the "first" one which is basically a random one).  Holy
        # guacamole, this has to be a sign that my function callback API for
        # passing lisps is just not a good API. But how else? 🥲 It’s so clean...
        deriv = builtins.elemAt (lispFuncDerivations lisp) 0;
      }
    else
      assert lib.isDerivation lisp;
      rec {
        deriv = lisp;
        name = lib.getName lisp;
        call =
          {
            abcl =
              file: "${lib.getExe lisp} --batch --noinform --noinit --nosystem --load ${wrapAbclToplevel file}";
            clasp = file: "${lib.getExe lisp} --script ${lib.escapeShellArg file}";
            clisp = file: "${lib.getExe lisp} -E UTF-8 -norc ${lib.escapeShellArg file}";
            ecl = file: "${lib.getExe lisp} --shell ${lib.escapeShellArg file}";
            sbcl = file: "${lib.getExe lisp} --script ${lib.escapeShellArg file}";
          }
          .${name};
      };

  # ABCL doesn’t support running scripts with debugger disabled and "exit
  # non-zero on any error" mode.
  wrapAbclToplevel =
    file:
    builtins.toFile "abcl-wrapper.lisp" ''
      (handler-case (load #p"${file}")
        (error (e)
          (format *error-output* "~A~%" e)
          (ext:quit :status 1)))
    '';
}
