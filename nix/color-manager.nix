{
  lib,
  fetchPypi,
  python3Packages,
  colorManagerSrc,
}: let
  basicColormath = python3Packages.buildPythonPackage rec {
    pname = "basic-colormath";
    version = "0.5.0";
    pyproject = true;

    src = fetchPypi {
      pname = "basic_colormath";
      inherit version;
      hash = "sha256-p/uNuNg5kqKIkeMmX5sWY8umGAg0E4/otgQxhzIuo0E=";
    };

    build-system = with python3Packages; [
      setuptools
      setuptools-scm
    ];

    pythonImportsCheck = ["basic_colormath"];

    meta = {
      description = "Simple color conversion and perceptual difference functions";
      homepage = "https://pypi.org/project/basic-colormath/";
      license = lib.licenses.mit;
    };
  };
in
  python3Packages.buildPythonPackage {
    pname = "color-manager";
    version = "1.0.0-unstable-2024-11-15";
    pyproject = true;

    src = colorManagerSrc;

    postPatch = ''
      substituteInPlace setup.py \
        --replace-fail \
          '"color_manager": ["palettes/*.json"],' \
          '"color_manager": ["palettes/*.json", "named_colors.json"],'
    '';

    build-system = with python3Packages; [
      setuptools
      wheel
    ];

    dependencies = with python3Packages; [
      basicColormath
      pillow
      tqdm
    ];

    pythonImportsCheck = ["color_manager.utils"];

    meta = {
      description = "Recolor icon packs, themes, wallpapers, and assets";
      homepage = "https://github.com/NicklasVraa/Color-manager";
      license = lib.licenses.agpl3Plus;
      platforms = lib.platforms.all;
    };
  }
