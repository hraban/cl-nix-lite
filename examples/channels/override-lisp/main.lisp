#-clisp (error "Not in CLISP")

(defpackage :override-lisp
  (:use :cl)
  (:export main))

(in-package :override-lisp)

(defun main (&rest args)
  (format T "Hello from CLISP~%"))
