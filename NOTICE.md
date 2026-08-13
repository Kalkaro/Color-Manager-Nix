# Third-party notices

## Color Manager

This project packages and invokes **Color Manager**, created by Nicklas Vraa
and its contributors:

- Project: <https://github.com/NicklasVraa/Color-manager>
- Pinned source commit: `9e55e0971ecd0e3141ed5d7d9a8377f7052cef96`
- License: GNU Affero General Public License, version 3 or later
- Copyright and authorship remain with the upstream authors and contributors.

Color Manager's source is not copied into this repository. Nix downloads the
pinned source during evaluation/build, and the full corresponding source remains
available from the upstream project and its pinned commit.

### Build-time modification notice

On 2026-08-13, Kalkaro added a Nix build adjustment which includes
`color_manager/named_colors.json` in the Python wheel. The file is required by
Color Manager at import time but is omitted by the pinned upstream packaging
configuration. The upstream application logic is otherwise used unchanged.

The upstream README also publishes an additional legal notice concerning use
of the repository and derivatives for machine-learning model development or
training. That notice is not reproduced as a new license term here; consult the
[upstream README](https://github.com/NicklasVraa/Color-manager#readme) and the
upstream author for its intended scope.

## Other components

- `basic-colormath` is fetched from PyPI and is licensed under the MIT License.
- Stylix is a flake input used for integration checks and is licensed under the
  MIT License.
- Papirus is not bundled by this repository. The default NixOS module consumes
  `pkgs.papirus-icon-theme`, which is licensed under GPL-3.0-only. Generated
  Papirus variants remain subject to the applicable Papirus license and notices.

The exact revisions and content hashes of flake inputs are recorded in
`flake.lock`.
