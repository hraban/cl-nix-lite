(asdf:defsystem "multiderivation/a"
  :description "A lisp project with multiple systems"
  :version "0.1"
  :author "Hraban Luyat"
  :depends-on ("alexandria")
  :components ((:file "a")))

(asdf:defsystem "multiderivation/b"
  :description "A lisp project with multiple systems"
  :version "0.1"
  :author "Hraban Luyat"
  :components ((:file "b")))

(asdf:defsystem "multiderivation"
  :description "A lisp project with multiple systems"
  :version "0.1"
  :author "Hraban Luyat"
  :components ((:file "main")))
