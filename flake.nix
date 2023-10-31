# ... I don’t think we need anything else do we?
{
  inputs = {};

  nixConfig = {
    extra-substituters = [ "https://cl-nix-lite.cachix.org" ];
    extra-trusted-public-keys = [ "cl-nix-lite.cachix.org-1:ab6+b0u2vxymMLcZ5DDqPKnxz0WObbMszmC+BDBHpFc=" ];
  };

  outputs = { self }: {
    overlays.default = import ./.;
  };
}
