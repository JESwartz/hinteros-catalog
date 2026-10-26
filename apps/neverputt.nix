# Neverputt: the minigolf game of the neverball package (see neverball.nix): the same store path,
# with neverputt as the command.
{
  format = 3;
  name = "Neverputt";
  summary = "Minigolf on courses from Neverball.";
  description = ''
    Neverputt is a minigolf game. Aim and hit the ball into the hole in as few strokes as you
    can. Up to four players take turns on one screen.
  '';
  category = "games";
  homepage = "https://neverball.org";
  # The upstream README, unmodified (see README, "Upstream READMEs"). Neverball and Neverputt
  # share one repository and one README.
  readme = {
    url = "https://github.com/Neverball/neverball/blob/86bcdf5f8933de48adc997eb5c5ff860e71e4492/README.md";
    retrieved = "2026-10-25";
    text = ./readme/neverputt.md;
  };
  license = {
    free = true;
    redistributable = true;
  };
  # Shares the neverball package (see neverball.nix).
  sizeMiB = 250;
  icon = {
    # The package installs no desktop file: the icon comes from iconUrl.
    desktopId = "neverputt";
    # The project's own repository (dist/modern-icons/png/neverputt-modern-512.png at 86bcdf5,
    # 512x512 PNG). Checked 2026-10-25.
    iconUrl = "https://raw.githubusercontent.com/Neverball/neverball/86bcdf5f8933de48adc997eb5c5ff860e71e4492/dist/modern-icons/png/neverputt-modern-512.png";
    sha256 = "1d8a2a9a056316315b9de4daf4ad3b7921394ce9d8f077d82d1c3a37debb1257";
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
          mainProgram = "neverputt";
        };
      };
      input = "gamepad";
    };
}
