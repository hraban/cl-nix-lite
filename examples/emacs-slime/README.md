# Using cl-nix-lite with the REPL

Building a package using ASDF works in a stand-alone build, but you’ll want to load packages dynamically in the REPL when developing lisp.

To get started: load [nix-lite.lisp](nix-lite.lisp). See the comment in that file on how to load it automatically.

Now you can use `nix-lite:load-package` to download packages automatically. This is similar to Quicklisp’s `ql:quickload`.

N.B.: You must supply the _Nix name_ of the package, not the ASDF system name. This is often the same, but not always. See the file `lisp-packages-lite.nix` file for a list of all those Nix package names.

Usage:

```
CL-USER> (load #p"/path/to/my/cl-nix-lite/examples/slime/nix-lite.lisp") ; or put this in ~/.sbclrc
CL-USER> (nix-lite:load-package "alexandria")

; ... compilation output ...

("alexandria")
CL-USER> (alexandria:iota 6)
(0 1 2 3 4 5)
CL-USER> 
```

Loading a dependencies from a custom directory is supported in the normal ASDFv3 way without anything special:

```
CL-USER> (pushnew #p"/path/to/my/alexandria/" asdf:*central-registry* :test #'equal)
(#P"/path/to/my/alexandria/")
CL-USER> 
```

Nix-lite always keeps its dependencies last in the load order, so your custom dependencies will take priority.
