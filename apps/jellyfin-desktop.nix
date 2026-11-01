# Jellyfin: free, native. On the ISO and offered in the installer (not pre-selected).
{
  format = 3;
  name = "Jellyfin";
  summary = "An app for your Jellyfin media server.";
  # The Jellyfin desktop client in its TV mode. It connects to a Jellyfin server on the network,
  # or to this box's own (`jellyfin-server`, from the Server section).
  description = ''
    Jellyfin plays the movies, series and music on a Jellyfin media server. The server can be on
    your home network or on this box.
  '';
  category = "video";
  homepage = "https://jellyfin.org";
  # The upstream README, unmodified (see README, "Upstream READMEs").
  readme = {
    url = "https://github.com/jellyfin/jellyfin-desktop/blob/2cb4a4456fd29b5b62d825ef0e5df93ed6913328/README.md";
    retrieved = "2026-10-25";
    text = ./readme/jellyfin-desktop.md;
  };
  license = {
    unfree = false;
  };
  sizeMiB = 250;
  icon = {
    desktopId = "org.jellyfin.JellyfinDesktop";
    # Jellyfin's official branding repo, https://github.com/jellyfin/jellyfin-ux (branding/SVG/icon-transparent.svg). Square SVG. Checked 2026-10-06.
    iconUrl = "https://raw.githubusercontent.com/jellyfin/jellyfin-ux/master/branding/SVG/icon-transparent.svg";
    sha256 = "817c25b47442b192250448fe48cd5f265fe9183bc75aa12030bbe335495255d1";
  };
  onIso = true;
  starter = "offered";
  permissions = {
    # No input set: the daemon passes the controller through (gamepad).
    gamepad = "required";
    # A Jellyfin server on the home network or on this box (`jellyfin-server`); a server on the
    # internet works without it.
    lan = "optional";
  };
  # Qt app: settings, saved servers and logins, web cache. Names differ between jellyfin-desktop
  # and its predecessor jellyfin-media-player: listing a path that does not exist is harmless.
  dataPaths = [
    ".local/share/jellyfin-desktop"
    ".config/jellyfin-desktop"
    ".cache/jellyfin-desktop"
    ".local/share/Jellyfin Media Player"
    ".config/Jellyfin Media Player"
    ".cache/Jellyfin Media Player"
  ];

  app =
    { pkgs, ... }:
    {
      # Formerly jellyfin-media-player (still an alias).
      package = pkgs.jellyfin-desktop;
      order = 10;
    };
}
