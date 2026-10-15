# Plex HTPC: unfree and not redistributable, native. Never cached, never in the ISO: nixpkgs'
# derivation downloads the snap from Snapcraft on the box and repackages it there. Offered in the
# installer (not pre-selected); as it is not on the ISO, picking it needs a network connection.
{
  format = 3;
  name = "Plex";
  summary = "An app for your Plex media server.";
  # Plex's 10-foot client for the big screen. Users sign in with a Plex account to watch their own
  # or shared Plex servers. The app is downloaded from Plex and prepared on the box during
  # install, which takes a few minutes.
  description = ''
    Plex HTPC is the Plex app for TV screens. It plays movies, series and music from your Plex
    Media Server and from servers that others share with you.
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
    # Plex's own site: web app manifest of watch.plex.tv (where www.plex.tv redirects), icon-512x512.png, 512x512 PNG. plex.tv has no public press-kit page. Checked 2026-10-06.
    iconUrl = "https://watch.plex.tv/icons/icon-512x512.png";
  };
  # Never cached: Plex HTPC is not redistributable.
  cache = false;
  starter = "offered";

  # Refresh when Plex revises its terms (see README, "Refreshing vendor terms").
  terms = {
    title = "Plex Terms of Service";
    version = "2025-10-30"; # "Revised October 30, 2025"
    url = "https://www.plex.tv/about/privacy-legal/plex-terms-of-service/";
    retrieved = "2026-10-06";
    text = ./terms/plex-htpc-2025-10-30.txt;
  };

  # Settings, login, watch state, caches and the Widevine module the app downloads. Plex HTPC
  # 1.71 writes .local/share/plex, .cache/plex and .cache/Plex HTPC (seen in the sandbox-apps VM
  # test, 2026-10-15).
  dataPaths = [
    ".local/share/plex"
    ".local/share/plex-htpc"
    ".local/share/Plex HTPC"
    ".config/plex-htpc"
    ".config/Plex HTPC"
    ".cache/plex"
    ".cache/plex-htpc"
    ".cache/Plex HTPC"
  ];

  permissions = {
    # The sandbox hides /dev/input; the app reads the controller itself.
    gamepad = "required";
    # A Plex Media Server on the home network or on this box (Plex also works over the internet).
    lan = "optional";
  };

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
