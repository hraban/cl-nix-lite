(asdf:defsystem #:hello-binary
  :description "A hello-world binary"
  :version "0.1"
  :author "Hraban Luyat"
  :build-operation "program-op"
  :build-pathname "bin/hello-binary"
  :entry-point "hello-binary:main"
  :serial t
  :components ((:file "main")))
