# SBCL binary with all packages available

Create a “wrapped” SBCL derivation which is a drop-in replacement for regular SBCL, but which has every single possible package available for ASDF to load.

```
$ nix-build
$ ./result/bin/sbcl --no-userinit
> (require :asdf)
> (asdf:load-system "alexandria")
```
