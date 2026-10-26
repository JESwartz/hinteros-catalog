# Steam: unfree (unfreeRedistributable), native. An unfree app that is cached (as Modrinth): with
# `cache = true` CI builds it and the binary cache serves it, so installing is a download like
# a free app. Never on the ISO.
{
  format = 3;
  name = "Steam";
  summary = "A game store and launcher.";
  # Installed games appear in the Games section; Steam's Big Picture mode handles the store,
  # downloads and settings. Each profile has its own Steam login and library.
  description = ''
    Steam is Valve's store and launcher for PC games. Big Picture mode shows the store, your
    games and settings on the TV.
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
    sha256 = "57df95cc7a45db8c9e62306aaa1be8983a62c5b2260cee830a1329fe803172f1";
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

  # Not sandboxed: Steam runs its own bwrap (pressure-vessel) and needs the full home and devices.
  sandbox = false;

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
