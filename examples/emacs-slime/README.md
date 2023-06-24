# Using cl-nix-lite with the REPL

Building a package using ASDF works in a stand-alone build, but you’ll want to load packages dynamically in the REPL when developing lisp.

To get started: load [nix-lite.lisp](nix-lite.lisp). See the comment in that file on how to load it automatically.

Now you can use `nix-lite:load-package` as a substitute for `ql:quickload`. N.B.: You must supply the _Nix name_ of the package, not the ASDF system name. See the main `default.nix` file for a list of all those Nix package names.
