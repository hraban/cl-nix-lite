# `nix develop` support for lispPackagesLite (flakes)

Run:

```
nix develop
```

If you have [direnv](https://direnv.net/) installed, just enter the directory
and it should automatically load it for you.

Now you can run SBCL with alexandria on the path:

```
sbcl --script <<EOF
(require "asdf")
(asdf:load-system "alexandria")
(print (alexandria:iota 3))
EOF
```

You could also for example run `emacs` from this shell to have access to SBCL from within it.

## Flake Trouble Shooting

If you see either of these two errors:

```
error: experimental Nix feature 'nix-command' is disabled; use '--extra-experimental-features nix-command' to override
```

```
error: experimental Nix feature 'flakes' is disabled; use '--extra-experimental-features flakes' to override
```

Try adding this to any ‘nix’ command:

```
nix --extra-experimental-features 'flakes nix-command' ...
```
