(asdf:defsystem :flake-override-input
  :class :package-inferred-system
  :description "Flake demo app for overriding input"
  :version "0.1"
  :author "Hraban Luyat"
  :build-operation "program-op"
  :build-pathname "bin/flake-override-input"
  :entry-point "flake-override-input:main"
  :depends-on ("flake-override-input/main"))
