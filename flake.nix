{
  description = "Convert flake.lock to a registry file";

  inputs = {
    # safely pinned to a ref (branch/tag);
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    nix.url = "github:nixos/nix/2.23.0";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # tracking main, master, latest, etc.;
    disko.url = "github:nix-community/disko";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    sops-nix.url = "github:mic92/sops-nix";
    systems.url = "github:nix-systems/default-linux";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # deduplication;
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix.inputs.flake-compat.follows = "flake-compat";
    nix.inputs.flake-parts.follows = "flake-parts";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, systems, treefmt-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ treefmt-nix.flakeModule ];

      flake.nixosModules = rec {
        default = nix-registry;
        nix-registry = import ./module.nix;
      };

      perSystem = { self', pkgs, ... }: {
        apps = rec {
          default = nix-registry;
          nix-registry = {
            type = "app";
            program = pkgs.writeShellApplication {
              name = "jq-${self'.packages.nix-registry.name}";
              runtimeInputs = [ pkgs.jq ];
              text = "exec jq '.' ${self'.packages.nix-registry}";
            };
          };
        };

        packages = rec {
          default = nix-registry;
          nix-registry = pkgs.callPackage ./package.nix { };
        };

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
