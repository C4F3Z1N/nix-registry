{
  pkgs ? import <nixpkgs> {},
  lockFile ? ./flake.lock,
  lib ? pkgs.lib,
}: let
  inherit (lib.importJSON lockFile) nodes;
  nix-registry = rec {
    original = builtins.parseFlakeRef "github:c4f3z1n/nix-registry";
    locked = original;
  };
in
  lib.pipe (nodes // {inherit nix-registry;}) [
    (lib.filterAttrs (id: {flake ? id != "root", ...}: flake))
    (lib.mapAttrs (id: {
      original,
      locked,
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
        else if locked ? ref
        then
          builtins.removeAttrs locked [
            "lastModified"
            "narHash"
            "rev"
            "revCount"
            "shortRev"
          ]
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
