(asdf:defsystem #:override-lisp
  :description "A binary that only works when compiled with CLISP"
  :version "0.1"
  :author "Hraban Luyat"
  :build-operation "program-op"
  :build-pathname "bin/override-lisp"
  :entry-point "override-lisp:main"
  :serial t
  :components ((:file "main")))
