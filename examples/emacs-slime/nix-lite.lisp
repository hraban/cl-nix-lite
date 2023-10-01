;; Copyright © 2023  Hraban Luyat
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

;; The cl-nix-lite parallel to ql:quickload.
;;
;; Note this doesn’t actually load the system into lisp, like ql:quickload does:
;; this just downloads it and puts it in your /nix/store, and on your ASDF load
;; path. You still have to load the actual package with asdf:load-system.
;;
;; Load this file from your Lisp’s init file, e.g. ~/.sbclrc, using this snippet
;; I stole from Quicklisp setup:
;;
;;   (let ((nix-lite-init (merge-pathnames "dir/to/nix-lite.lisp"
;;                                         (user-homedir-pathname))))
;;     (when (probe-file nix-lite-init)
;;       (load nix-lite-init)))


;; Extremely hacky, proof-of-concept, alpha, 0.0, use-at-your-own-risk level
;; code. I have committed this to document my work rather than as a sign of
;; sanity.

(defpackage #:nix-lite
  (:use #:cl)
  (:export #:load-package #:unload-package #:src))

(in-package #:nix-lite)

(defvar packages '())

(defvar src "builtins.fetchTarball \"https://github.com/hraban/cl-nix-lite/archive/master.tar.gz\"")

(require "ASDF")
(require "UIOP")

(defun run (cmd)
  (uiop:run-program cmd
                    :output '(:string :stripped t)
                    :error-output :interactive))

(defun nix-build (nix)
  "Build this nix expression.

Returns a list of the built paths, as output to stdout by Nix.
"
  (let ((out (run `("nix-build" "--no-out-link" "-E" ,nix))))
    (remove ""
            (uiop:split-string out :separator '(#\Newline))
            :test #'string=)))

(defun nix-store-p (p)
  (string= "/nix/store/" (subseq (namestring p) 0 11)))

(defun delete-nix-paths ()
  "Remove all nix store paths from the ASDF central registry"
  (setf asdf:*central-registry* (delete-if #'nix-store-p asdf:*central-registry*)))

(defun refresh-packages ()
  (let ((nix (format NIL "
let
  pkgs = (import <nixpkgs> {}).extend(import (~A));
in
with pkgs.lispPackagesLite;
map
(x: x.src)
(lispWithSystems [ ~(~{~A~^ ~}~) ]).ancestry.deps
" src packages)))
    ;; Assume that any nix store path is managed by this package. Safe
    ;; assumption.
    (delete-nix-paths)
    (setf asdf:*central-registry*
          (nconc asdf:*central-registry*
                 (mapcar (lambda (p) (pathname (concatenate 'string p "/")))
                         (nix-build nix))))))

;; TODO: Normalize package names. Not doing that now because nobody cares.

(defun load-package (package)
  "Add a package (and its dependencies) to the ASDF search path"
  (pushnew package packages :test #'equal)
  (refresh-packages))

(defun unload-package (package)
  "Remove a package (and any unused dependencies) from the ASDF search path.

N.B.: This does not unload the package from your Lisp image. It merely removes
it from the path.
"
  (setf packages (delete package packages :test #'equal))
  (refresh-packages))
