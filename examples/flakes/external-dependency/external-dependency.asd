(asdf:defsystem #:external-dependency
  :description "A hello-world example using an external dependency"
  :version "0.1"
  :author "Hraban Luyat"
  :build-operation "program-op"
  :build-pathname "bin/external-dependency"
  :entry-point "external-dependency:main"
  :serial t
  :depends-on ("hello-world")
  :components ((:file "main")))
