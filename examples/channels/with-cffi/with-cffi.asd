(asdf:defsystem :with-cffi
  :description "Demo app using CFFI"
  :version "0.1"
  :author "Hraban Luyat"
  :build-operation "program-op"
  :build-pathname "bin/with-cffi"
  :entry-point "with-cffi:main"
  :depends-on (:alexandria :cl-async)
  :serial t
  :components ((:file "main")))
