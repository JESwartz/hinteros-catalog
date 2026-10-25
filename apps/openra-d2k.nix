# OpenRA Dune 2000: free, native (.NET), from the binary cache. The OpenRA package has three
# games (Red Alert, Tiberian Dawn, Dune 2000), each its own entry (openra-ra, openra-cnc,
# openra-d2k) with its own program as the command: one package in the store, but a tile,
# a sandbox home and permissions per game.
# On first start the game downloads its content (needs internet); if the download is not
# offered, it needs files from an original Dune 2000 disc.
# A mouse game: `keyboard` input gives the d-pad as arrows (map scroll), A as Enter, Back as
# Escape, the right stick as the pointer, RT and LT as left and right click. A USB or Bluetooth
# mouse and keyboard also work.
{
  format = 3;
  name = "OpenRA: Dune 2000";
  summary = "Real-time strategy: three houses fight for the spice of Arrakis.";
  description = ''
    Dune 2000 in OpenRA, a free, open-source version of the classic game. Lead House
    Atreides, Harkonnen or Ordos in missions, battles against the computer and online games
    with other players.
  '';
  category = "games";
  homepage = "https://www.openra.net";
  # The upstream README, unmodified (see README, "Upstream READMEs").
  readme = {
    url = "https://github.com/OpenRA/OpenRA/blob/dbe674733305cd1ebe7bd03feed347b5c0da3c08/README.md";
    retrieved = "2026-10-25";
    text = ./readme/openra-d2k.md;
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
    # OpenRA's own repository (packaging/artwork/d2k_256x256.png at the packaged release tag,
    # 256x256 PNG, GPL-3.0). Checked 2026-10-16.
    desktopId = "openra-d2k";
    iconUrl = "https://raw.githubusercontent.com/OpenRA/OpenRA/release-20250330/packaging/artwork/d2k_256x256.png";
    sha256 = "f60cba7ff9ba35939beca75f78ba5c4fd80bcf5aed9849d5e90aa8e26a3b44df";
  };
  # This game's downloaded content, maps, replays and saves ($XDG_CONFIG_HOME/openra, by game).
  # settings.yaml there is shared by the three games and stays.
  dataPaths = [
    ".config/openra/Content/d2k"
    ".config/openra/maps/d2k"
    ".config/openra/Replays/d2k"
    ".config/openra/Saves/d2k"
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
          mainProgram = "openra-d2k";
        };
      };
      input = "keyboard";
      backKey = "escape";
    };
}
