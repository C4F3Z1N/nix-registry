{
  description = "Convert flake.lock to a registry file";

  inputs = {
    # safely pinned to a ref (branch/tag);
    home-manager.url = "github:nix-community/home-manager/6ebe7be2e67be7b9b54d61ce5704f6fb466c536f";
    nix.url = "github:nixos/nix/2.21.0";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # tracking main, master, latest, etc.;
    devshell.url = "github:numtide/devshell";
    disko.url = "github:nix-community/disko";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    sops-nix.url = "github:mic92/sops-nix";
    systems.url = "github:nix-systems/default-linux";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # deduplication;
    devshell.inputs.flake-utils.follows = "flake-utils";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flake-utils.inputs.systems.follows = "systems";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix.inputs.flake-compat.follows = "flake-compat";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    flake-parts,
    treefmt-nix,
    systems,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [treefmt-nix.flakeModule];

      perSystem = {
        pkgs,
        self',
        ...
      }: {
        apps.default = {
          type = "app";
          program = pkgs.writeShellApplication {
            name = "jq-${self'.packages.default.name}";
            runtimeInputs = [pkgs.jq];
            text = "jq '.' ${self'.packages.default}";
          };
        };

        packages.default = import ./default.nix {inherit pkgs;};

        treefmt.config = {
          programs.alejandra.enable = true;
          programs.prettier.enable = true;
          projectRootFile = "flake.nix";
          settings.formatter.prettier.includes = ["*.lock"];
        };
      };

      systems = import systems;
    };
}
