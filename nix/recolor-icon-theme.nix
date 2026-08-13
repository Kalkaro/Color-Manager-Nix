{
  lib,
  stdenvNoCC,
  python3,
  gtk3,
  colorManager,
}: {
  color,
  sourcePackage,
  sourceTheme ? "Papirus",
  name ? "Papirus-Stylix",
}: let
  normalizedColor = lib.removePrefix "#" color;
  recolorScript = ''
    from color_manager import utils

    utils.recolor(
        "source",
        "build",
        "${name}",
        utils.hex_to_hsl("#${normalizedColor}"),
    )
  '';
in
  assert lib.assertMsg (builtins.match "[0-9a-fA-F]{6}" normalizedColor != null)
  "recolorIconTheme: color must be a six-digit hexadecimal RGB value";
  assert lib.assertMsg (builtins.match "[A-Za-z0-9._+-]+" name != null)
  "recolorIconTheme: name contains characters which are unsafe in an icon theme path";
  assert lib.assertMsg (builtins.match "[A-Za-z0-9._+-]+" sourceTheme != null)
  "recolorIconTheme: sourceTheme contains characters which are unsafe in an icon theme path";
    stdenvNoCC.mkDerivation {
      pname = lib.toLower name;
      version = sourcePackage.version or "unstable";

      dontUnpack = true;
      # The output contains only static icon assets. Generic fixup would scan
      # every Papirus SVG for executable shebangs and can take several minutes.
      dontFixup = true;
      dontDropIconThemeCache = true;

      nativeBuildInputs = [
        python3
        colorManager
        gtk3.out
      ];

      buildPhase = ''
        runHook preBuild

        test -f ${sourcePackage}/share/icons/${sourceTheme}/index.theme
        mkdir source build
        cp -a ${sourcePackage}/share/icons/${sourceTheme}/. source/
        chmod -R u+w source

        python3 -c ${lib.escapeShellArg recolorScript}
        sed -i \
          's|^Comment=.*|Comment=A variant of ${sourceTheme} created by nicklasvraa/color-manager|' \
          build/${name}/index.theme

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/icons
        cp -a build/${name} $out/share/icons/
        gtk-update-icon-cache --force $out/share/icons/${name}

        runHook postInstall
      '';

      passthru = {
        inherit name sourcePackage sourceTheme;
        color = normalizedColor;
      };

      meta = {
        description = "${sourceTheme} icon theme recolored around #${normalizedColor}";
        license = sourcePackage.meta.license or lib.licenses.gpl3Plus;
        platforms = sourcePackage.meta.platforms or lib.platforms.linux;
      };
    }
