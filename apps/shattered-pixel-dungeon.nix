# Shattered Pixel Dungeon: free (GPL-3.0), native (Java, libGDX), from the binary cache. The game
# reads the controller itself (libGDX controllers, menus included).
{
  format = 3;
  name = "Shattered Pixel Dungeon";
  summary = "A roguelike dungeon crawler with pixel art.";
  description = ''
    Shattered Pixel Dungeon is a roguelike dungeon crawler. Go down through levels that change
    each game, fight monsters, find items and choose one of several heroes.
  '';
  category = "games";
  homepage = "https://shatteredpixel.com/shatteredpd/";
  # The upstream README, unmodified (see README, "Upstream READMEs").
  readme = {
    url = "https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/README.md";
    retrieved = "2026-10-25";
    text = ./readme/shattered-pixel-dungeon.md;
  };
  license = {
    free = true;
    redistributable = true;
  };
  # The game and its Java runtime (about 630 MiB more than the libraries a box already has): an
  # estimate, not measured on a box.
  sizeMiB = 630;
  icon = {
    desktopId = "shattered-pixel-dungeon";
    # The project's own repository (desktop/src/main/assets/icons/icon_256.png at 57a4e06,
    # 256x256 PNG). Checked 2026-10-25.
    iconUrl = "https://raw.githubusercontent.com/00-Evan/shattered-pixel-dungeon/57a4e06a4caf162446d1c28caa7983f0493fecf0/desktop/src/main/assets/icons/icon_256.png";
    sha256 = "00962b4d99401827b24bce91bc76672ee69380d075085f6d5148a085d7badcb5";
  };

  permissions = {
    # The sandbox hides /dev/input; the game reads the controller itself.
    gamepad = "required";
  };

  app =
    { pkgs, ... }:
    {
      package = pkgs.shattered-pixel-dungeon;
      input = "gamepad";
    };
}
