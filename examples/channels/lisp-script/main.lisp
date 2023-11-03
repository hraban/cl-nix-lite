#!/usr/bin/env sbcl --script

(require "asdf")

(asdf:load-system "yason")

(yason:with-output (t :indent t)
  (yason:encode (yason:parse *standard-input*)))
