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

{ inputs, pkgs }:

let
  inherit (pkgs) lib;
  utils = pkgs.callPackage ./utils.nix { };
  # The lisp is a function which takes a file and returns a shell invocation
  # calling that file, then exiting. Or just a derivation of a known Lisp,
  # e.g. lisp = pkgs.sbcl.
  lispPackagesLiteFor =
    lisp':
    let
      lisp = utils.makeLisp lisp';
      lpl = pkgs.callPackage ./lisp-derivation.nix { inherit lisp; };
      packages = pkgs.callPackage ./packages.nix { inherit inputs lisp; };
      scopeInit = self: {
        inherit (lpl)
          lispDerivation
          lispMultiDerivation
          lispScript
          lispWithSystems
          ;
      };
      scope = lib.makeScope pkgs.newScope (lib.extends packages scopeInit);
    in
    lib.recurseIntoAttrs scope;
in
{
  inherit lispPackagesLiteFor;
  lispPackagesLite = lispPackagesLiteFor pkgs.sbcl;
}
