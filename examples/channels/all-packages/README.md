# All lisp packages

Build every single package as a separate derivation. Useful as a sanity check.

Build:

```
nix-build --no-out-link check-disabled.nix
```

Or to run all derivations with tests:

```
nix-build --no-out-link check-enabled.nix
```

To build a single derivation from either of the above sets:

```
nix-build -A alexandria check-disabled.nix
```

To build everything: all packages without tests, and those that have tests:

```
nix-build --no-out-link
```
