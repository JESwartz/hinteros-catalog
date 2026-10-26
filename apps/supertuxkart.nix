# SuperTuxKart: free, native, from the binary cache. The game reads the controller itself
# (SDL game controllers, menus included) and has split screen for up to four players.
{
  format = 3;
  name = "SuperTuxKart";
  summary = "Kart racing with Tux and friends.";
  description = ''
    SuperTuxKart is a kart racing game. Race on many tracks, play battles and soccer, and play
    with up to four players on one screen or with other players online.
  '';
  category = "games";
  homepage = "https://supertuxkart.net";
  # The upstream README, unmodified (see README, "Upstream READMEs").
  readme = {
    url = "https://github.com/supertuxkart/stk-code/blob/e05fef37e9d5045b7d272f56216dcc981bd6e616/README.md";
    retrieved = "2026-10-25";
    text = ./readme/supertuxkart.md;
  };
  license = {
    free = true;
    redistributable = true;
  };
  # The game and its tracks and karts (about 830 MiB more than the libraries a box already has):
  # an estimate, not measured on a box.
  sizeMiB = 830;
  icon = {
    desktopId = "supertuxkart";
    # The project's own repository (data/supertuxkart_512.png at e05fef3, 512x512 PNG). Checked
    # 2026-10-25.
    iconUrl = "https://raw.githubusercontent.com/supertuxkart/stk-code/e05fef37e9d5045b7d272f56216dcc981bd6e616/data/supertuxkart_512.png";
    sha256 = "fcd2bdee6df6ca0366681f2091b11920a9ecc6ea553a3935750568c471bd95b9";
  };

  permissions = {
    # The sandbox hides /dev/input; the game reads the controller itself.
    gamepad = "required";
    # LAN games: finding and joining servers on the home network (online games work without it).
    lan = "optional";
  };

  app =
    { pkgs, ... }:
    {
      package = pkgs.supertuxkart;
      input = "gamepad";
    };
}
