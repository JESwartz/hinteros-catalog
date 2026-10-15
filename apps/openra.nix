# OpenRA: free, native (.NET), from the binary cache. One package with three games (Red Alert,
# Tiberian Dawn, Dune 2000); the tile starts Red Alert (the package's mainProgram), and the game's
# own "Mods" menu switches to the others. On first start each game downloads its freeware
# content from inside the game (needs internet); Dune 2000 needs the original game files.
# A mouse game: `keyboard` input gives the d-pad as arrows (map scroll), A as Enter, Back as
# Escape, the right stick as the pointer, RT and LT as left and right click. A USB or Bluetooth
# mouse and keyboard also work.
{
  format = 3;
  name = "OpenRA";
  summary = "Real-time strategy games: Red Alert, Tiberian Dawn and Dune 2000.";
  description = ''
    OpenRA is a free, open-source version of the classic Command & Conquer strategy games: Red
    Alert, Tiberian Dawn and Dune 2000. It has missions, battles against the computer and online
    games with other players.
  '';
  category = "games";
  homepage = "https://www.openra.net";
  license = {
    free = true;
    redistributable = true;
  };
  # nix path-info -S of the closure is about 1.1 GiB; most of it (GTK, ffmpeg, python) a box
  # already has. The game (51 MiB), the .NET runtime (71 MiB) and the freeware content it
  # downloads on first start: an estimate, not measured on a box.
  sizeMiB = 250;
  icon = {
    # OpenRA's own repository (packaging/artwork/ra_256x256.png at the packaged release tag,
    # 256x256 PNG, GPL-3.0). Checked 2026-10-15.
    desktopId = "openra-ra";
    iconUrl = "https://raw.githubusercontent.com/OpenRA/OpenRA/release-20250330/packaging/artwork/ra_256x256.png";
  };
  # Settings, downloaded game content, maps, replays and saves ($XDG_CONFIG_HOME/openra; the
  # engine still uses ~/.openra if that exists).
  dataPaths = [
    ".config/openra"
    ".openra"
  ];

  app =
    { pkgs, ... }:
    {
      package = pkgs.openra;
      input = "keyboard";
      backKey = "escape";
    };
}
