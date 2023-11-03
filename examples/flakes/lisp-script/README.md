# Flake demonstration of lispScript

Usage:

```
echo '{"foo":123,"bar":456}' | nix run
```

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
