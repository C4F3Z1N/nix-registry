{
  config,
  lib,
  options,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.nix-registry;
  opt = options.programs.nix-registry;
in {
  options.programs.nix-registry = with types; {
    enable = mkOption {
      type = bool;
      default = false;
    };

    include = mkOption {
      type = attrsOf attrs;
      default = {};
    };

    package = mkOption {
      type = package;
      default =
        pkgs.callPackage ./package.nix {inherit (cfg) include source;};
    };

    source = mkOption {
      type = either path attrs;
      default = ./flake.lock;
    };
  };

  config = mkIf cfg.enable {
    nix.settings.flake-registry =
      cfg.package
      // lib.optionalAttrs (cfg.package != opt.package.default) {
        override = {inherit (cfg) include source;};
      };
  };
}
