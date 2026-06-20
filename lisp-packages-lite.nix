# Copyright © 2022–2024  Hraban Luyat
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

let
  # The lisp is a function which takes a file and returns a shell invocation
  # calling that file, then exiting. Or just a derivation of a known Lisp,
  # e.g. lisp = pkgs.sbcl.
  mkLispScope =
    {
      callPackage,
      lisp,
      newScope,
      lib,
    }:
    let
      utils = callPackage ./utils.nix { };
      scopeInit =
        self:
        let
          lpl = callPackage ./lisp-derivation.nix { lisp = self._lisp; };
        in
        {
          # Experimental.  (Is it a good idea to expose the lisp on the scope?
          # uv2nix doesn’t do this but it’s kind of useful...?  Should it be pre-
          # or post-utils.makeLisp?  Is utils.makeLisp even a good idea?)
          _lisp = utils.makeLisp lisp;

          inherit (lpl)
            lispDerivation
            lispMultiDerivation
            lispScript
            lispWithSystems
            ;
        };
    in
    lib.makeScope newScope scopeInit;
in

{ sources, pkgs }:
let
  inherit (pkgs) lib;
in
rec {
  lispPackagesLiteFor =
    lisp:
    let
      scope = pkgs.callPackage _mkLispScope { inherit lisp; };
      # There’s a difference between import and pkgs.callPackage, and I’m not
      # 100% on what exactly it is.  Something about bootstrap packages?  TBD.
      packages = _lispRegistry { inherit pkgs sources lib; };
      scope' = scope.overrideScope packages;
    in
    lib.recurseIntoAttrs scope';
  lispPackagesLite = lispPackagesLiteFor pkgs.sbcl;

  # EXPERIMENTAL OPTIONS.  Exploring a more modular API.  Subject to change.
  _mkLispScope = mkLispScope;
  _lispRegistry = import ./packages.nix;
}
