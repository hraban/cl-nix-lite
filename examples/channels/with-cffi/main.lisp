(defpackage :with-cffi
  (:use :cl)
  (:export main))

(in-package :with-cffi)

(defun main (&rest args)
  (format T "Have some variance: ~A~%" (alexandria:variance '(1 2 1 2 2 2 1 1 2 1)))
  (format T "Sigkill is signal number ~A~%" as:+sigkill+))
