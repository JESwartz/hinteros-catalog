# OpenRA Red Alert: free, native (.NET), from the binary cache. The OpenRA package has three
# games (Red Alert, Tiberian Dawn, Dune 2000), each its own entry (openra-ra, openra-cnc,
# openra-d2k) with its own program as the command: one package in the store, but a tile,
# a sandbox home and permissions per game.
# On first start the game downloads its freeware content (needs internet).
# A mouse game: `keyboard` input gives the d-pad as arrows (map scroll), A as Enter, Back as
# Escape, the right stick as the pointer, RT and LT as left and right click. A USB or Bluetooth
# mouse and keyboard also work.
{
  format = 3;
  name = "OpenRA: Red Alert";
  summary = "Real-time strategy: the Allies against the Soviet Union.";
  description = ''
    Red Alert in OpenRA, a free, open-source version of the classic Command & Conquer games.
    Command the Allies or the Soviet Union in missions, battles against the computer and
    online games with other players.
  '';
  category = "games";
  homepage = "https://www.openra.net";
  license = {
    free = true;
    redistributable = true;
  };
  # nix path-info -S of the closure is about 1.1 GiB; most of it (GTK, ffmpeg, python) a box
  # already has. The engine and all three games (51 MiB), the .NET runtime (71 MiB) and the
  # content the game downloads: an estimate, not measured on a box. The other OpenRA games
  # share the package.
  sizeMiB = 250;
  icon = {
    # OpenRA's own repository (packaging/artwork/ra_256x256.png at the packaged release tag,
    # 256x256 PNG, GPL-3.0). Checked 2026-10-16.
    desktopId = "openra-ra";
    iconUrl = "https://raw.githubusercontent.com/OpenRA/OpenRA/release-20250330/packaging/artwork/ra_256x256.png";
    sha256 = "a22d3a38387d30d215b0f4625c3ffaed6091f513f0548bd23a353e72f7d009cf";
  };
  # This game's downloaded content, maps, replays and saves ($XDG_CONFIG_HOME/openra, by game).
  # settings.yaml there is shared by the three games and stays.
  dataPaths = [
    ".config/openra/Content/ra"
    ".config/openra/maps/ra"
    ".config/openra/Replays/ra"
    ".config/openra/Saves/ra"
  ];

  permissions = {
    # LAN games: finding and joining games on the home network (online games work without it).
    lan = "optional";
  };

  app =
    { pkgs, ... }:
    {
      # The same store path with another main program (only meta changes: no rebuild, cached).
      package = pkgs.openra // {
        meta = pkgs.openra.meta // {
          mainProgram = "openra-ra";
        };
      };
      input = "keyboard";
      backKey = "escape";
    };
}
