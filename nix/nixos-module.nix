{recolorIconTheme}: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.colorManager.papirus;
in {
  options.colorManager.papirus = {
    enable = mkEnableOption "a Papirus icon theme recolored from the Stylix base02 color";

    color = mkOption {
      type = types.strMatching "#?[0-9a-fA-F]{6}";
      default = config.lib.stylix.colors.base02;
      defaultText = lib.literalExpression "config.lib.stylix.colors.base02";
      description = ''
        Six-digit RGB color used for the monochrome recoloring. By default this
        follows the active Stylix base02 color. A leading hash is optional.
      '';
    };

    sourcePackage = mkOption {
      type = types.package;
      default = pkgs.papirus-icon-theme;
      defaultText = lib.literalExpression "pkgs.papirus-icon-theme";
      description = "Package containing the source icon theme.";
    };

    sourceTheme = mkOption {
      type = types.strMatching "[A-Za-z0-9._+-]+";
      default = "Papirus";
      description = "Icon theme directory to recolor inside sourcePackage/share/icons.";
    };

    name = mkOption {
      type = types.strMatching "[A-Za-z0-9._+-]+";
      default = "Papirus-Stylix";
      description = "Name of the generated icon theme.";
    };

    package = mkOption {
      type = types.package;
      readOnly = true;
      default = recolorIconTheme {
        inherit (cfg) color name sourceTheme;
        package = cfg.sourcePackage;
      };
      defaultText = lib.literalExpression "recolored Papirus package";
      description = "The generated icon theme package.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.stylix.enable;
        message = "colorManager.papirus requires Stylix to be enabled";
      }
    ];

    stylix.icons = {
      enable = true;
      package = cfg.package;
      dark = cfg.name;
      light = cfg.name;
    };

    environment.systemPackages = [cfg.package];
  };
}
