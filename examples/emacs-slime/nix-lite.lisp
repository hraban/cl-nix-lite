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
  (:export #:load-package
           #:unload-package
           #:*src-cl-nix-lite*
           #:*src-nixpkgs*))

(in-package #:nix-lite)

(defvar packages '())

(defvar *src-cl-nix-lite* "builtins.fetchTarball \"https://github.com/hraban/cl-nix-lite/archive/master.tar.gz\"")
(defvar *src-nixpkgs* "<nixpkgs>")

(require "asdf")
(require "uiop")

(defun run (cmd)
  ;; The only way I know how to get streaming stderr from the spawned process to
  ;; SLIME.
  (let* ((p (uiop:launch-program cmd :output :stream :error-output :stream))
         (outs (uiop:process-info-output p))
         (errs (uiop:process-info-error-output p)))
    (uiop:slurp-input-stream *error-output* errs :linewise t)
    (let ((out (uiop:slurp-input-stream :lines outs))
          (status (uiop:wait-process p)))
      ;; Copied from UIOP.  This is sensible.
      (unless (eql 0 status)
        (cerror "IGNORE-ERROR-STATUS"
                'uiop:subprocess-error :command cmd :code status :process p))
      out)))

(defun nix-build (nix)
  "Build this nix expression.

Returns a list of the built paths, as output to stdout by Nix.
"
  (remove ""
          (run `("nix-build" "--no-out-link" "-E" ,nix))
          :test #'string=))

(defun nix-store-p (p)
  (string= "/nix/store/" (subseq (namestring p) 0 11)))

(defun delete-nix-paths ()
  "Remove all nix store paths from the ASDF central registry"
  (setf asdf:*central-registry* (delete-if #'nix-store-p asdf:*central-registry*)))

;; This builds every package even though that build probably isn’t used, unless
;; the user has ASDF_OUTPUT_TRANSLATIONS=/:/ which is uncommon for SLIME. For
;; almost all packages we could instead of using the build, just map this to use
;; the ‘drv.src’ instead; the reason to build it anyway is some odd packages
;; like asdf which, on load, will try and write to their own source
;; directory. Using the final derivation directory is the only way to reliably
;; load those packages.
(defun refresh-packages (packages)
  (let* ((nix (format NIL "
let
  pkgs = import (~A) { overlays = [ (import (~A)) ]; };
  l = pkgs.lispPackagesLite;
in
(l.lispWithSystems [ ~(~{l.\"~A\"~^ ~}~) ]).ancestry.deps
" *src-nixpkgs* *src-cl-nix-lite* packages))
         (fresh-dirs (nix-build nix)))
    ;; Assume that any nix store path is managed by this package.  Safe
    ;; assumption.
    (delete-nix-paths)
    (setf asdf:*central-registry*
          (nconc asdf:*central-registry*
                 (mapcar (lambda (p) (pathname (concatenate 'string p "/")))
                         fresh-dirs)))))

;; TODO: Normalize package names. Not doing that now because nobody cares.

(defun load-package (&rest add)
  "Add a package (and its dependencies) to the ASDF search path"
  (let ((all (union packages add :test #'equal)))
    (refresh-packages all)
    (setf packages all)
    ;; Best effort--this usually works
    (dolist (failed (mapcan (lambda (package)
                              (if (asdf:find-system package nil)
                                  (progn
                                    (asdf:load-system package)
                                    nil)
                                  (list package)))
                            ;; Reload all new packages even if already loaded
                            add))
      (format *error-output* "Nix package cl-nix-lite.~A successfully loaded, but ASDF system ~:*~A not found.~%" failed))
    all))

(defun unload-package (&rest remove)
  "Remove a package (and any unused dependencies) from the ASDF search path.

N.B.: This does not unload the package from your Lisp image. It merely removes
it from the path.
"
  (let ((new (set-difference packages remove :test #'equal)))
    (refresh-packages new)
    (setf packages new)))
