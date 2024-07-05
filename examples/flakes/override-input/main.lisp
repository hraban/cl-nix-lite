;; Copyright © 2022–2024  Hraban Luyat
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

(uiop:define-package #:flake-override-input
  (:nicknames #:flake-override-input/main)
  (:use #:cl #:arrow-macros)
  (:local-nicknames (#:alex #:alexandria))
  (:import-from #:alexandria)
  (:export #:main))

(in-package #:flake-override-input/main)

(defun main (&rest args)
  (->> 5
       alex:fauxiota
       (format T "This should count to 9: ~A~%")))
