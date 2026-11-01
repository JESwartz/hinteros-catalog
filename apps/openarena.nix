# OpenArena: free (GPL-2.0 engine and game code, free assets), native, from the binary cache. A
# Quake III Arena-style shooter on the ioquake3 engine with its own free graphics and sounds.
# A keyboard and mouse game: `keyboard` input gives the d-pad as arrows (move and turn, the
# game's default keys), the right stick as the mouse (look), RT and LT as left and right click
# (fire, zoom), A as Enter, Back as Escape. A USB or Bluetooth mouse and keyboard also work.
# No `readme`: the game's repositories have no README for players.
# No `iconUrl`: the engine repository's icon is the Quake III logo, not OpenArena's; the installed
# desktop file's icon and discovery on the homepage cover it.
{
  format = 3;
  name = "OpenArena";
  summary = "A fast arena shooter, free and open source.";
  description = ''
    OpenArena is a first-person shooter in the style of Quake III Arena. Fight against bots or
    other players in deathmatch, team and capture-the-flag games.
  '';
  category = "games";
  homepage = "https://openarena.ws";
  license = {
    unfree = false;
  };
  # The engine and the game data (about 430 MiB more than the libraries a box already has): an
  # estimate, not measured on a box.
  sizeMiB = 430;
  icon = {
    desktopId = "OpenArena";
  };

  permissions = {
    # LAN games: finding and joining servers on the home network (online games work without it).
    lan = "optional";
  };

  app =
    { pkgs, ... }:
    {
      package = pkgs.openarena;
      input = "keyboard";
      backKey = "escape";
    };
}
