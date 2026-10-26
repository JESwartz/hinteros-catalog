# Neverball: free, native, from the binary cache. The neverball package has two games
# (Neverball and Neverputt), each its own entry (neverball, neverputt) with its own program as the
# command: one package in the store, but a tile, a sandbox home and permissions per game, as for
# OpenRA. The games read the controller themselves (SDL joysticks, menus included).
{
  format = 3;
  name = "Neverball";
  summary = "Tilt the floor to roll a ball to the goal.";
  description = ''
    Neverball is a game of skill. Tilt the floor to roll a ball through an obstacle course before
    the time runs out. Collect coins to open the exit and to get more balls.
  '';
  category = "games";
  homepage = "https://neverball.org";
  # The upstream README, unmodified (see README, "Upstream READMEs").
  readme = {
    url = "https://github.com/Neverball/neverball/blob/86bcdf5f8933de48adc997eb5c5ff860e71e4492/README.md";
    retrieved = "2026-10-25";
    text = ./readme/neverball.md;
  };
  license = {
    free = true;
    redistributable = true;
  };
  # Both games and their levels (about 250 MiB more than the libraries a box already has): an
  # estimate, not measured on a box. Neverputt shares the package.
  sizeMiB = 250;
  icon = {
    # The package installs no desktop file: the icon comes from iconUrl.
    desktopId = "neverball";
    # The project's own repository (dist/modern-icons/png/neverball-modern-512.png at 86bcdf5,
    # 512x512 PNG). Checked 2026-10-25.
    iconUrl = "https://raw.githubusercontent.com/Neverball/neverball/86bcdf5f8933de48adc997eb5c5ff860e71e4492/dist/modern-icons/png/neverball-modern-512.png";
    sha256 = "2e7697a79acdb5bb000326b979d3083629a7ba27315387152a3c9c0a97082995";
  };

  permissions = {
    # The sandbox hides /dev/input; the game reads the controller itself.
    gamepad = "required";
  };

  app =
    { pkgs, ... }:
    {
      # The same store path with another main program (only meta changes: no rebuild, cached).
      package = pkgs.neverball // {
        meta = pkgs.neverball.meta // {
          mainProgram = "neverball";
        };
      };
      input = "gamepad";
    };
}
