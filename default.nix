{
  pkgs ? import <nixpkgs> {},
  lockFile ? ./flake.lock,
}: let
  inherit (pkgs) lib;
  lock = lib.importJSON lockFile;
  nix-registry.original = builtins.parseFlakeRef "github:c4f3z1n/nix-registry";
in
  lib.pipe (lock.nodes // {inherit nix-registry;}) [
    (lib.filterAttrs (id: {flake ? id != "root", ...}: flake))
    (lib.mapAttrs (id: {
      original,
      locked ? original,
      ...
    }: {
      exact = true;
      from = {
        inherit id;
        type = "indirect";
      };
      to =
        if original ? ref
        then original
        else locked;
    }))
    (lib.attrValues)
    (flakes: {
      inherit flakes;
      version = 2;
    })
    (builtins.toJSON)
    (pkgs.writeText "registry.json")
  ]
