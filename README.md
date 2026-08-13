# Color Manager for Nix and Stylix

An independent Nix flake that packages
[Color Manager](https://github.com/NicklasVraa/Color-manager) and exposes a
reusable icon-theme recoloring function for NixOS and Stylix.

This repository does not vendor Color Manager's source. Nix fetches the
upstream source at commit
[`9e55e0971ecd0e3141ed5d7d9a8377f7052cef96`](https://github.com/NicklasVraa/Color-manager/commit/9e55e0971ecd0e3141ed5d7d9a8377f7052cef96),
and `flake.lock` records its content hash.

## Usage

Add this flake alongside Stylix:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stylix.url = "github:nix-community/stylix";

    color-manager-nix = {
      url = "github:Kalkaro/Color-Manager-Nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.stylix.follows = "stylix";
    };
  };
}
```

Use the recoloring function directly in `stylix.icons.package`:

```nix
{config, pkgs, inputs, ...}: {
  stylix.icons = {
    enable = true;

    package = inputs.color-manager-nix.lib.recolorIconTheme {
      inherit pkgs;
      package = pkgs.papirus-icon-theme;
      color = config.lib.stylix.colors.base02;
      sourceTheme = "Papirus-Dark";
    };

    dark = "Papirus-Dark";
    light = "Papirus-Dark";
  };
}
```

The function accepts any package containing
`share/icons/<sourceTheme>/index.theme`. Its arguments are:

- `pkgs`: the package set used by the NixOS configuration;
- `package`: the package containing the source icon theme;
- `color`: a six-digit RGB value, with an optional leading `#`;
- `sourceTheme`: the source directory under `share/icons`, defaulting to
  `"Papirus"`;
- `name`: the generated theme name, defaulting to `sourceTheme`.

The flake also provides an overlay. With the overlay imported, the equivalent
package expression is:

```nix
pkgs.recolorIconTheme {
  package = pkgs.papirus-icon-theme;
  color = config.lib.stylix.colors.base02;
  sourceTheme = "Papirus-Dark";
}
```

For Papirus specifically, the optional NixOS module provides a shorter form:

```nix
{
  imports = [inputs.color-manager-nix.nixosModules.default];

  colorManager.papirus = {
    enable = true;
    sourceTheme = "Papirus-Dark";
  };
}
```

Its color defaults to `config.lib.stylix.colors.base02`, and it configures both
Stylix icon variants to use the generated package.

## Recoloring behavior

Color Manager's monochrome operation applies the hue, saturation, and lightness
offset of the requested color while preserving relative lightness within each
icon. The result therefore contains shades around `base02`, rather than making
every visible pixel exactly the same flat value.

A full Papirus build processes roughly 220 MiB of icons. The first build can
take a little while; Nix reuses the result until the source package or color
changes.

## Verification

```bash
nix flake check
nix build .#papirus-base02-example
```

The checks cover package imports, the public recoloring function, generated
theme metadata, source-color replacement, and Stylix module evaluation.

## Upstream, licensing, and attribution

This is an independent integration project and is not affiliated with or
endorsed by the Color Manager author, Stylix, or the Papirus project.

Color Manager was created by Nicklas Vraa and contributors. It is fetched and
built under the GNU Affero General Public License. See [NOTICE.md](NOTICE.md),
the root [LICENSE](LICENSE), and the
[upstream project](https://github.com/NicklasVraa/Color-manager) for details.

The wrapper code in this repository is also distributed under the GNU Affero
General Public License, version 3 or later. Icon themes passed to the recoloring
function keep their own licenses; users who redistribute generated themes are
responsible for complying with those licenses and retaining their attribution.
