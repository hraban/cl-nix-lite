(defpackage :hello-binary
  (:use :cl)
  (:export main))

(in-package :hello-binary)

(defun main (&rest args)
  (format T "Hello, world~%"))
