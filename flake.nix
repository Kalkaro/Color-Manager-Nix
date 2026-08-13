{
  description = "Color Manager packaged for Nix, with Stylix-aware Papirus recoloring";

  inputs = {
    colorManagerSrc = {
      url = "github:NicklasVraa/Color-manager/9e55e0971ecd0e3141ed5d7d9a8377f7052cef96";
      flake = false;
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    colorManagerSrc,
    nixpkgs,
    stylix,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = forAllSystems (
      system: let
        pkgs = import nixpkgs {inherit system;};
        colorManager = pkgs.callPackage ./nix/color-manager.nix {
          inherit colorManagerSrc;
        };
      in {
        color-manager = colorManager;
        default = colorManager;

        # A concrete package useful for trying the builder without evaluating a
        # NixOS configuration. The NixOS module uses the active Stylix base02.
        papirus-base02-example = self.lib.recolorIconTheme {
          color = "2b303b";
          inherit pkgs colorManager;
          name = "Papirus-Stylix";
          package = pkgs.papirus-icon-theme;
        };
      }
    );

    lib = {
      mkRecolorIconTheme = {
        pkgs,
        colorManager ? self.packages.${pkgs.stdenv.hostPlatform.system}.color-manager,
      }:
        pkgs.callPackage ./nix/recolor-icon-theme.nix {
          inherit colorManager;
        };

      recolorIconTheme = {
        pkgs,
        package,
        color,
        sourceTheme ? "Papirus",
        name ? sourceTheme,
        colorManager ? self.packages.${pkgs.stdenv.hostPlatform.system}.color-manager,
      }:
        (self.lib.mkRecolorIconTheme {
          inherit pkgs colorManager;
        }) {
          inherit color name sourceTheme;
          sourcePackage = package;
        };
    };

    overlays.default = final: _prev: {
      color-manager = final.callPackage ./nix/color-manager.nix {
        inherit colorManagerSrc;
      };
      recolorIconTheme = args:
        self.lib.recolorIconTheme (args
          // {
            pkgs = final;
            colorManager = final.color-manager;
          });
    };

    nixosModules = {
      color-manager = {pkgs, ...}: {
        imports = [
          (import ./nix/nixos-module.nix {
            recolorIconTheme = args:
              self.lib.recolorIconTheme (args
                // {
                  inherit pkgs;
                });
          })
        ];
      };
      default = self.nixosModules.color-manager;
    };

    checks = forAllSystems (
      system: let
        pkgs = import nixpkgs {inherit system;};
        colorManager = self.packages.${system}.color-manager;
        recolorIconTheme = args:
          self.lib.recolorIconTheme (args
            // {
              inherit pkgs colorManager;
            });
        testSvg = pkgs.writeText "application.svg" ''
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16">
            <rect width="16" height="16" fill="#009688"/>
            <circle cx="8" cy="8" r="4" fill="#ffffff"/>
          </svg>
        '';
        testIndex = pkgs.writeText "index.theme" ''
          [Icon Theme]
          Name=Papirus-Dark
          Comment=Independent recoloring test fixture
          Directories=scalable/apps

          [scalable/apps]
          Size=16
          Type=Scalable
          Context=Applications
        '';
        testIconTheme = pkgs.runCommand "papirus-test-source" {} ''
          mkdir -p $out/share/icons/Papirus-Dark/scalable/apps
          cp ${testSvg} \
            $out/share/icons/Papirus-Dark/scalable/apps/application.svg
          cp ${testIndex} \
            $out/share/icons/Papirus-Dark/index.theme
        '';
        recoloredTestIconTheme = recolorIconTheme {
          color = "2b303b";
          package = testIconTheme;
          sourceTheme = "Papirus-Dark";
        };
        moduleEvaluation = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            stylix.nixosModules.stylix
            self.nixosModules.default
            {
              boot.loader.grub.devices = ["nodev"];
              fileSystems."/" = {
                device = "none";
                fsType = "tmpfs";
              };
              system.stateVersion = "26.05";

              stylix = {
                enable = true;
                base16Scheme = {
                  base00 = "101010";
                  base01 = "181818";
                  base02 = "2b303b";
                  base03 = "585858";
                  base04 = "b8b8b8";
                  base05 = "d8d8d8";
                  base06 = "e8e8e8";
                  base07 = "f8f8f8";
                  base08 = "ab4642";
                  base09 = "dc9656";
                  base0A = "f7ca88";
                  base0B = "a1b56c";
                  base0C = "86c1b9";
                  base0D = "7cafc2";
                  base0E = "ba8baf";
                  base0F = "a16946";
                  scheme = "flake check";
                  slug = "flake-check";
                  author = "Color Manager";
                };
              };

              colorManager.papirus.enable = true;
            }
          ];
        };
      in {
        module = assert moduleEvaluation.config.stylix.icons.package == moduleEvaluation.config.colorManager.papirus.package;
        assert moduleEvaluation.config.stylix.icons.dark == "Papirus-Stylix";
        assert moduleEvaluation.config.stylix.icons.light == "Papirus-Stylix";
          pkgs.runCommand "color-manager-module-check" {} ''
            touch $out
          '';

        recolor = pkgs.runCommand "color-manager-recolor-check" {} ''
          theme=${recoloredTestIconTheme}/share/icons/Papirus-Dark
          test -f "$theme/index.theme"
          test -f "$theme/scalable/apps/application.svg"
          grep -q '^Name=Papirus-Dark$' "$theme/index.theme"
          grep -q '^Comment=A variant of Papirus-Dark created by nicklasvraa/color-manager$' "$theme/index.theme"
          if grep -qi '#009688' "$theme/scalable/apps/application.svg"; then
            echo "The source color survived recoloring" >&2
            exit 1
          fi
          touch $out
        '';
      }
    );
  };
}
