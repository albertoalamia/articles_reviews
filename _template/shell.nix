# Per-article environment: the shared root shell plus anything this paper needs.
# Usually the root shell is enough; delete this file if nothing is added.
let
  root = import ../shell.nix;
in
root.overrideAttrs (old: {
  # packages = old.packages ++ [ ... ];
})
