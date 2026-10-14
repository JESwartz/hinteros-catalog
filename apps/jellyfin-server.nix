# Jellyfin server: free, a box-wide service (admin profile only, Server section, M10). Not in the
# Store: services are not apps. The per-profile client is the separate `jellyfin` entry.
{
  format = 3;
  kind = "service";
  name = "Jellyfin server";
  summary = "A media server for your movies, series and music.";
  # Runs on this box for everyone at home: the owner points it at movie and show folders and
  # watches from any Jellyfin app on the network, including the `jellyfin` app on this box. Only
  # the admin profile can turn it on or off.
  description = ''
    Jellyfin Server keeps your movies, series and music in one library. Jellyfin apps on your
    home network play from this library.
  '';
  category = "video";
  homepage = "https://jellyfin.org";
  license = {
    free = true;
    redistributable = true;
  };
  # Server plus its bundled web UI and ffmpeg; the library and metadata cache grow in /var/lib.
  sizeMiB = 600;
  icon = {
    # Jellyfin's official branding repo, https://github.com/jellyfin/jellyfin-ux (branding/SVG/icon-transparent.svg). Square SVG. Checked 2026-10-06.
    iconUrl = "https://raw.githubusercontent.com/jellyfin/jellyfin-ux/master/branding/SVG/icon-transparent.svg";
  };

  service =
    { lib, ... }:
    {
      services.jellyfin.enable = true;
      # M10: the system repo adds a LAN-only firewall rule instead.
      services.jellyfin.openFirewall = lib.mkDefault false;
    };
  packages = pkgs: [ pkgs.jellyfin ];

  notes = ''
    Data lives in /var/lib/jellyfin (the service user's), not in a profile's home, so there are no
    dataPaths. Library folders and the firewall rule are M10 work in the system repo.
  '';
}
