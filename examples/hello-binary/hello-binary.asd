;; Copyright © 2022, 2023  Hraban Luyat
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published
;; by the Free Software Foundation, version 3 of the License.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

#-asdf3.3 (error "Needs ASDFv3.3")

(asdf:defsystem :hello-binary
  :class :package-inferred-system
  :description "A hello-world binary using"
  :version "0.1"
  :author "Hraban Luyat"
  :build-operation "program-op"
  :licence "AGPLv3"
  :build-pathname "bin/hello-binary"
  :entry-point "hello-binary:main"
  :depends-on ("hello-binary/main"))
