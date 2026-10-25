# OpenRA Tiberian Dawn: free, native (.NET), from the binary cache. The OpenRA package has three
# games (Red Alert, Tiberian Dawn, Dune 2000), each its own entry (openra-ra, openra-cnc,
# openra-d2k) with its own program as the command: one package in the store, but a tile,
# a sandbox home and permissions per game.
# On first start the game downloads its freeware content (needs internet).
# A mouse game: `keyboard` input gives the d-pad as arrows (map scroll), A as Enter, Back as
# Escape, the right stick as the pointer, RT and LT as left and right click. A USB or Bluetooth
# mouse and keyboard also work.
{
  format = 3;
  name = "OpenRA: Tiberian Dawn";
  summary = "Real-time strategy: GDI against the Brotherhood of Nod.";
  description = ''
    Tiberian Dawn, the first Command & Conquer, in OpenRA, a free, open-source version of the
    classic games. Fight for GDI or the Brotherhood of Nod in missions, battles against the
    computer and online games with other players.
  '';
  category = "games";
  homepage = "https://www.openra.net";
  # The upstream README, unmodified (see README, "Upstream READMEs").
  readme = {
    url = "https://github.com/OpenRA/OpenRA/blob/dbe674733305cd1ebe7bd03feed347b5c0da3c08/README.md";
    retrieved = "2026-10-25";
    text = ./readme/openra-cnc.md;
  };
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
    # OpenRA's own repository (packaging/artwork/cnc_256x256.png at the packaged release tag,
    # 256x256 PNG, GPL-3.0). Checked 2026-10-16.
    desktopId = "openra-cnc";
    iconUrl = "https://raw.githubusercontent.com/OpenRA/OpenRA/release-20250330/packaging/artwork/cnc_256x256.png";
    sha256 = "7892aa7ec7bafcd696c5eae0d1e4caab8e146f2d8923d5fead6608a0ca7a29f1";
  };
  # This game's downloaded content, maps, replays and saves ($XDG_CONFIG_HOME/openra, by game).
  # settings.yaml there is shared by the three games and stays.
  dataPaths = [
    ".config/openra/Content/cnc"
    ".config/openra/maps/cnc"
    ".config/openra/Replays/cnc"
    ".config/openra/Saves/cnc"
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
          mainProgram = "openra-cnc";
        };
      };
      input = "keyboard";
      backKey = "escape";
    };
}
