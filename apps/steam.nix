# Steam: unfree (unfreeRedistributable), native. The one unfree app that is cached: with
# `cache = true` CI builds it and the binary cache serves it, so installing is a download like
# a free app. Never on the ISO.
{
  format = 3;
  name = "Steam";
  summary = "Play your Steam library on the TV.";
  description = ''
    Valve's game store and launcher. Your installed games appear in Games, and Steam's own
    Big Picture mode handles the store, downloads and settings. Each profile has its own
    Steam login and library.
  '';
  category = "games";
  homepage = "https://store.steampowered.com";
  license = {
    free = false;
    redistributable = true;
    unfreePackages = [
      "steam"
      "steam-unwrapped"
    ];
  };
  # Bootstrap and 32-bit runtime (~500 MiB), plus Steam's own client update on first start.
  sizeMiB = 1000;
  icon = {
    desktopId = "steam";
    siteUrl = "https://store.steampowered.com";
    # Valve's own store site (share_steam_logo.png, 512x512 PNG; the Steam brand page https://partner.steamgames.com/doc/marketing/branding links no stable icon file). Checked 2026-10-06.
    iconUrl = "https://store.steampowered.com/public/shared/images/responsive/share_steam_logo.png";
  };
  box = [
    "graphics32"
    "steam-devices"
  ];
  starter = "offered";
  cache = true; # unfreeRedistributable (checked against nixpkgs by tests/packages.nix)

  # Refresh when Valve revises the agreement (see README, "Refreshing vendor terms").
  terms = {
    title = "Steam Subscriber Agreement";
    version = "2026-09-10"; # "last updated on September 10, 2026"
    url = "https://store.steampowered.com/subscriber_agreement/";
    retrieved = "2026-10-06";
    text = ./terms/steam-2026-09-10.txt;
  };

  # WARNING: ~/.local/share/Steam holds the installed games and their saves along with the
  # client, so deleting it removes every installed game in that profile. The remove dialog's
  # "delete data" confirmation must say so. ~/.steam holds symlinks into it and the login state.
  dataPaths = [
    ".local/share/Steam"
    ".steam"
  ];

  # The tile is the daemon's built-in `steam` entry (Big Picture, games.list), so the app is
  # not listed as a tile of its own. `box.steam` is pkgs.steam with this box's graphics packages;
  # the `box` features above turn on 32-bit graphics and the controller udev rules box-wide.
  app = { box, ... }: {
    package = box.steam;
    listed = false;
  };

  notes = ''
    Valve occasionally replaces the bootstrap tarball; a nixpkgs bump fixes the hash. The Games
    section prompts to install this entry when Steam is missing (M8).
  '';
}
