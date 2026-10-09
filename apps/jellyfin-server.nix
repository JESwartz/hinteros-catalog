# Jellyfin server: free, a box-wide service (admin profile only, Server section, M10). Not in the
# Store: services are not apps. The per-profile client is the separate `jellyfin` entry.
{
  format = 3;
  kind = "service";
  name = "Jellyfin server";
  summary = "Share this box's movies and shows with every screen at home.";
  description = ''
    The Jellyfin media server, running on this box for everyone at home. Point it at your
    movie and show folders and watch from any Jellyfin app on your network, including the
    Jellyfin app on this box. Only the admin profile can turn it on or off.
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
