# Test all lispPackagesLite packages

To test all packages (this should succeed):

    $ nix-build

To test only one package, e.g. alexandria:

    $ nix-build -A alexandria

To test all packages, even ones marked as explicitly failing (this will fail):

    $ nix-build -E 'import ./. { skip = []; }'
