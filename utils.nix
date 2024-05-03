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

{
  pkgs
  , lib
}:

with lib;

rec {
  a = attrsets;
  b = builtins;
  l = lists;
  s = strings;
  t = trivial;

  # The obvious signature for pipe. Who wants ltr? (Clarification: putting the
  # function pipeline first and the value second allows using rpipe in
  # point-free context. See other uses in this file.)
  rpipe = flip pipe;

  # Like foldr but without a nul-value. Doesn’t support actual ‘null’ in the
  # list because I don’t know how to make singletons (is that even possible in
  # Nix?) and because I don’t care.
  reduce = (op: seq:
    assert ! b.elem null seq; # N.B.: THIS MAKES IT STRICT!
    foldr (a: b: if b == null then a else (op a b)) null seq);

  # Create an empty string with the same context as the given string
  emptyCopyWithContext = str: s.addContextFrom str "";

  # Turn a derivation path into a context-less string. I suspect this isn’t in
  # the stdlib because this is a perversion of a low-level feature, not intended
  # for casual access in regular derivations.
  drvStrWithoutContext = rpipe [ toString b.getContext attrNames l.head ];

  # optionalKeys [ "a" "b" ] { a = 1; b = 2; c = 3; }
  # => { a = 1; b = 2; }
  # optionalKeys [ ] { a = 1; b = 2; c = 3; }
  # => { }
  # optionalKeys [ "a" "b" ] { a = 1; }
  # => { a = 1; }
  # optionalKeys [ "a" "b" ] { }
  # => { }
  optionalKeys = keys: a.filterAttrs (k: v: b.elem k keys);

  # Like the inverse of lists.remove but takes a test function instead of an
  # element
  # (a -> Bool) -> [a] -> [a]
  keepBy = f: foldr (a: b: l.optional (f a) a ++ b) [];

  # If argument is a function, call it with a constant value. Otherwise pass it
  # through.
  callIfFunc = val: f: if isFunction f then f val else f;

  flatMap = f: rpipe [ (map f) l.flatten ];

  normaliseStrings = rpipe [ l.unique l.naturalSort ];

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
  nestedUnion = item: n: sets:
    if n == 0
    then item sets
    else
      a.zipAttrsWith (_: vals: nestedUnion item (n - 1) vals) sets;

  getLispDeps = x: x.CL_SOURCE_REGISTRY or "";

  asdf = pkgs.fetchFromGitLab {
    name = "asdf-src";
    domain = "gitlab.common-lisp.net";
    owner = "asdf";
    repo = "asdf";
    rev = "3.3.6";
    sha256 = "sha256-GCmGUMLniPakjyL/D/aEI93Y6bBxjdR+zxXdSgc9NWo=";
  };

  # Get a context-less string representing this source derivation, come what
  # come may.
  derivPath = src: drvStrWithoutContext (
    if b.isPath src
    # Purely a developer ergonomics feature. Don’t rely on this for published
    # libs. It breaks pure eval.
    then b.path { path = src; }
    else src);

  isLispDeriv = x: x ? lispSystems;

  # Manage a { key => drv } attrset, describing all dependencies, recursively,
  # as a flattened set. Worst edge case:
  #
  #                -> foo-b -> zim
  #              /               \
  # foo-a -> bar                  \
  #              \                 v
  #                ------------> foo-c
  #
  # Assuming foo-* are all systems in the same source derivation. This edge case
  # is the most complicated, and it’s the reason for this entire
  # pre-parsing-dependency-tracking quagmire. It’s not unusual with -test
  # derivations. This graph is solved by incrementally including the dependent
  # systems in the parent derivations, and rebuilding them all. So, with an
  # arrow indicating the lispDependencies:
  #
  # [foo-a & foo-b & foo-c] -> bar -> [foo-b & foo-c] -> zim -> foo-c
  #
  # Complications:
  # - The derivation doing the deduplication of foo-b and foo-c is not, itself,
  #   a foo, so it doesn’t have easy access to an authoritative definition of
  #   foo. It must recognize from the two separate derivations that they are
  #   equal, and construct an entirely new foo that encapsulates them both.
  # - If any of the systems is defined with doCheck = true, this affects the
  #   build, and the final combined derivation must also be built with checks.
  # - If you rebuild fully from source every time, e.g. foo-{a,b,c}, foo-c will
  #   only be built because it is a dependency of zim. ASDF’s cache tracking
  #   mechanism causes any system /whose dependencies must be rebuilt/ itself
  #   also stale. This means a rebuild of foo-c would cause a rebuild of
  #   zim--that will fail, because zim is in the store. The only solution to
  #   this is to fetch the prebuilt cache of foo-c by making foo-c the src of
  #   foo-b, and foo-b the src of foo-a.
  #
  # Note that bar only depends on a single "foo" derivation, which is built with
  # foo-b and foo-c; not on two copies of foo, one with b & c, one with just c.
  ancestryWalker = {
    # Function to convert a derivation to a string identifying it
    # uniquely. Think src path.
    key
    # This derivation, if it were built as-is, no deduplication applied. Think
    # stdenv.mkDerivation ...
    , me
    # How to merge this derivation with another one.
    , merge
    # My directly defined top-level dependencies.
    , dependencies
  }: let
    # Create a single source map entry for this derivation. This is the core
    # datastructure around which the derivation deduplication detection
    # mechanism is built.
    entryFor = drv: { ${key drv} = drv; };
    # Given a lispDerivation, get all its dependencies in the { src-drv =>
    # lisp-drv } format. The invariant for ancestry._depsMap is that it
    # can’t contain itself, so this is a non-destructive operation.
    depsFor = drv: drv.ancestry._depsMap // (entryFor drv);
    # Always order dependencies deterministically.  If either of the two is not
    # a lisp deriv, we’re basically in the foo-b situation. This situation only
    # happens when we are in a derivation that has itself as a dependency. It
    # never occurs from an unrelated dependency, because those will never have
    # an entry for this src anyway.
    #
    # We are in the “bar” situation, above. Or perhaps in this situation:
    #
    #          -- blub-a
    #        /
    # bim --
    #        \
    #          -- blub-b
    #
    # Either way, the solution is the same: create an entirely new derivation
    # that unions the two dependencies.
    allDepsIncMyself = nestedUnion (reduce (x: x.ancestry.merge)) 1 (map depsFor dependencies);
    depsMap = removeAttrs allDepsIncMyself [ (key me) ];
  in
  # The resulting ancestry object. This must be assigned to the output
  # derivation’s passthru object, in a key called ‘ancestry’.
  {
    inherit merge;
    # If I depend on myself in any way, first flatten me and all my transitive
    # dependent copies of me into one big union derivation.
    me =
      if allDepsIncMyself ? ${key me}
      then merge allDepsIncMyself.${key me}
      else me;
    # Internal only. Invariant: never includes myself.
    _depsMap = depsMap;
    # A flat list of all my dependencies.
    deps = builtins.attrValues depsMap;
  };

  # For a “lisp callable” function (see public API), get an array of all its
  # derivations. E.g. for ‘f: "${pkgs.sbcl}/bin/sbcl --script ${f}"’ this
  # returns [ pkgs.sbcl ].
  lispFuncDerivations = lisp:
    assert isFunction lisp;
    # Extremely hacky but it works. Assume that any derivation we’re interested
    # in lives in the string context. This is painful because we’re doing
    # runtime imports for every single derivation, only really for nix-shell
    # purposes which is a tiny fraction of actual use. But it’s just such a nice
    # feature to have the correct lisp right there in your shell that I’m loath
    # to remove this until it’s absolutely necessary.
    pipe "sentinel" [
      lisp
      builtins.getContext
      builtins.attrNames
      (map (d: import d))
    ];

  # Normalize the external lisp argument (see API of scope) to an easy-to-use
  # attrset.
  makeLisp = lisp:
    if b.isFunction lisp
    then rec {
      call = lisp;
      name = getName deriv;
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
      assert isDerivation lisp;
      rec {
        deriv = lisp;
        name = getName lisp;
        call = {
          sbcl = file: ''"${lisp}/bin/sbcl" --script "${file}"'';
          clisp = file: ''"${lisp}/bin/clisp" -E UTF-8 -norc "${file}"'';
          ecl = file: ''"${lisp}/bin/ecl" --shell "${file}"'';
        }.${name};
      };
}
