{ pkgs ? import <nixpkgs> { } }:
let
  inherit (pkgs) lib;
  lock = lib.importJSON ./flake.lock;
in lib.pipe lock.nodes [
  (lib.filterAttrs (id: { flake ? id != "root", ... }: flake))
  (lib.mapAttrs (id:
    { original, locked, ... }: {
      exact = true;
      from = {
        inherit id;
        type = "indirect";
      };
      to = if original ? ref then original else locked;
    }))
  (lib.attrValues)
  (flakes: {
    inherit flakes;
    version = 2;
  })
  (builtins.toJSON)
  (pkgs.writeText "registry.json")
]
