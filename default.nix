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

# nixpkgs overlay
final: prev:

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
  inherit (final) lib;
in
{
  lispPackagesLiteFor =
    lisp:
    let
      scope = final.callPackage final._lispPackagesLiteMkScope { inherit lisp; };
      sources = final._lispPackagesLiteSources { inherit (final) callPackage; };
      sourcesExt = _: _: { _sources = sources; };
      scope' = scope.overrideScope (lib.composeExtensions final._lispPackagesLitePackages sourcesExt);
    in
    lib.recurseIntoAttrs scope';
  lispPackagesLite = final.lispPackagesLiteFor final.sbcl;

  # EXPERIMENTAL OPTIONS.  Exploring a more modular API.  Subject to change.
  _lispPackagesLiteMkScope = mkLispScope;
  # There’s a difference between import and pkgs.callPackage, and I’m not 100%
  # on what exactly it is.  Something about bootstrap packages?  TBD.
  _lispPackagesLitePackages = import ./packages.nix {
    inherit lib;
    pkgs = final;
  };
  _lispPackagesLiteSources = import ./sources;
}
