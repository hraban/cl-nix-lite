# All lisp packages

Build every single package as a separate derivation. Useful as a sanity check.

Build:

```
nix-build
```

Or to build a single derivation:

```
nix-build -A alexandria
```
