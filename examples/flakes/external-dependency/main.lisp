(defpackage :external-dependency
  (:use :cl)
  (:export main))

(in-package :external-dependency)

(defun main (&rest args)
  (format T "~A~%" (hello-world:hello "external dependency")))
