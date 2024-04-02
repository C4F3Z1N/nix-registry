{
  description = "My custom registry";

  inputs = {
    nixpkgs.url = "flake:nixpkgs";

    home-manager = {
      url = "flake:home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat.url = "github:edolstra/flake-compat";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, treefmt-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ treefmt-nix.flakeModule ];

      flake = { lib, ... }:
        let
          lockFromInputs = flake@{ from, to, ... }:
            flake // lib.optionalAttrs (to ? narHash) {
              to = to // lib.getAttrs [ "lastModified" "narHash" "rev" ]
                inputs."${from.id}".sourceInfo;
            };
        in rec {
          prev = lib.importJSON ./registry.json;
          final = prev // { flakes = map lockFromInputs prev.flakes; };
        };

      perSystem = { pkgs, ... }: {
        packages.default = pkgs.writeText "registry.json" (builtins.toJSON self.final);

        treefmt.config = {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
          programs.prettier.enable = true;
        };
      };

      systems = nixpkgs.lib.systems.flakeExposed;
    };
}
