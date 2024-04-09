{
  description = "My custom registry";

  inputs = {
    # safely pinned to a ref (branch/tag);
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # tracking main, master, latest, etc.;
    devshell.url = "github:numtide/devshell";
    disko.url = "github:nix-community/disko";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    sops-nix.url = "github:mic92/sops-nix";
    systems.url = "github:nix-systems/default-linux";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # recursive inputs deduplication;
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, treefmt-nix, systems, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ treefmt-nix.flakeModule ];

      perSystem = { lib, pkgs, self', ... }: {
        apps.default = {
          type = "app";
          program = pkgs.writeShellApplication {
            name = "jq-${self'.packages.default.name}";
            runtimeInputs = [ pkgs.jq ];
            text = "jq '.' ${self'.packages.default}";
          };
        };

        packages.default = with lib.importJSON ./flake.lock;
          lib.pipe nodes [
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
          ];

        treefmt.config = {
          programs.nixfmt.enable = true;
          programs.prettier.enable = true;
          projectRootFile = "flake.nix";
          settings.formatter.prettier.includes = [ "*.lock" ];
        };
      };

      systems = import systems;
    };
}
