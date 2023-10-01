# ... I don’t think we need anything else do we?
{
  inputs = {};

  outputs = { self }: {
    overlays.default = import ./.;
  };
}
