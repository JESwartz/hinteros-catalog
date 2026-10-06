# Plex HTPC: unfree and not redistributable, native. Never cached, never in the ISO: nixpkgs'
# derivation downloads the snap from Snapcraft on the box and repackages it there.
{
  format = 2;
  name = "Plex";
  summary = "Watch your Plex libraries with Plex's TV interface.";
  description = ''
    Plex HTPC, Plex's 10-foot client for the big screen. Sign in with your Plex account to watch
    your own or shared Plex servers. The app is downloaded from Plex and prepared on this box
    during install, which takes a few minutes.
  '';
  category = "video";
  homepage = "https://www.plex.tv";
  license = {
    free = false;
    redistributable = false;
    unfreePackages = [ "plex-htpc" ];
  };
  sizeMiB = 300;
  icon = {
    desktopId = "plex-htpc";
    siteUrl = "https://www.plex.tv";
  };
  installer = true;
  # Never cached: Plex HTPC is not redistributable.
  cache = false;

  # Refresh when Plex revises its terms (see README, "Refreshing vendor terms").
  terms = {
    title = "Plex Terms of Service";
    version = "2025-10-30"; # "Revised October 30, 2025"
    url = "https://www.plex.tv/about/privacy-legal/plex-terms-of-service/";
    retrieved = "2026-10-06";
    text = ./terms/plex-htpc-2025-10-30.txt;
  };

  # Settings, login, watch state, caches and the Widevine module the app downloads.
  dataPaths = [
    ".local/share/plex-htpc"
    ".local/share/Plex HTPC"
    ".config/plex-htpc"
    ".config/Plex HTPC"
    ".cache/plex"
    ".cache/plex-htpc"
    ".cache/Plex HTPC"
  ];

  app =
    { pkgs, ... }:
    {
      package = pkgs.plex-htpc;
      input = "gamepad";
      order = 15;
    };

  notes = ''
    Source: api.snapcraft.io (snap revision pinned in nixpkgs). When Plex pulls a revision the
    install fails with a hash mismatch until nixpkgs is bumped; the Store shows "can't be
    installed right now". Widevine is downloaded by the app into ~/.cache/plex.
  '';
}
