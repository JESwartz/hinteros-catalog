# Jellyfin: free, native. On the ISO, so an offline install can pick it.
{
  format = 2;
  name = "Jellyfin";
  summary = "Watch your Jellyfin server's movies and shows.";
  description = ''
    The Jellyfin desktop client in its TV mode. Connect to a Jellyfin server on your network
    (or this box's own, from the Server section).
  '';
  category = "video";
  homepage = "https://jellyfin.org";
  license = {
    free = true;
    redistributable = true;
  };
  sizeMiB = 250;
  icon.desktopId = "org.jellyfin.JellyfinDesktop";
  onIso = true;
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
