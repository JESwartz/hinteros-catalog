# Jellyfin: free, native, preinstalled (one of the default apps, in the ISO).
{
  format = 1;
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
  preinstalled = true;

  app =
    { pkgs, ... }:
    {
      # Formerly jellyfin-media-player (still an alias).
      package = pkgs.jellyfin-desktop;
      order = 10;
    };
}
