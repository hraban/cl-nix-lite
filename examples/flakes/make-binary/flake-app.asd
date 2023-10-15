(asdf:defsystem :flake-app
  :class :package-inferred-system
  :description "Flake demo app"
  :version "0.1"
  :author "Hraban Luyat"
  :build-operation "program-op"
  :build-pathname "bin/flake-app"
  :entry-point "flake-app:main"
  :depends-on ("flake-app/main"))
