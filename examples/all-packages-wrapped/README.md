# SBCL binary with all packages available

Create a “wrapped” SBCL derivation which is a drop-in replacement for regular SBCL, but which has every single possible package available for ASDF to load.

```
$ nix-build
$ ./result/bin/sbcl --no-userinit
> (require :asdf)
> (asdf:load-system "alexandria")
```

You can also use this with Emacs:

```
$ nix-build && emacs --eval  "(setq inferior-lisp-program \"${PWD}/result/bin/sbcl --no-userinit\")"
```

In Emacs you can use `M-x slime`, and (e.g.) `(asdf:load-system "arrow-macros")`. Adding the `--no-userinit` avoids loading Quicklisp, ensuring any system you load comes from Nix.
