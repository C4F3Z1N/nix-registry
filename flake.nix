{
  description = "Convert flake.lock to a registry file";

  inputs = {
    # safely pinned to a ref (branch/tag);
    home-manager.url = "github:nix-community/home-manager/6ebe7be";
    nix.url = "github:nixos/nix/2.22.0";

    # handle nixpkgs variations as (sub)inputs;
    not-nixpkgs.url = "github:c4f3z1n/not-nixpkgs";

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
    flake-parts.follows = "nix/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix.inputs.flake-compat.follows = "flake-compat";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-unstable.follows = "not-nixpkgs/unstable";
    nixpkgs.follows = "not-nixpkgs/stable";
    not-nixpkgs.inputs.lib.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "not-nixpkgs/stable";
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
            text = "exec jq '.' ${self'.packages.default}";
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
