# Jellyfin server: free, a box-wide service (admin profile only, Server section, M10). Not in the
# Store: services are not apps. The per-profile client is the separate `jellyfin-desktop` entry.
{
  format = 3;
  kind = "service";
  name = "Jellyfin server";
  summary = "A media server for your movies, series and music.";
  # Runs on this box for everyone at home: the owner points it at movie and show folders and
  # watches from any Jellyfin app on the network, including the `jellyfin-desktop` app on this box. Only
  # the admin profile can turn it on or off.
  description = ''
    Jellyfin Server keeps your movies, series and music in one library. Jellyfin apps on your
    home network play from this library.
  '';
  category = "video";
  homepage = "https://jellyfin.org";
  license = {
    unfree = false;
  };
  # Server plus its bundled web UI and ffmpeg; the library and metadata cache grow in /var/lib.
  sizeMiB = 600;
  icon = {
    # Jellyfin's official branding repo, https://github.com/jellyfin/jellyfin-ux (branding/SVG/icon-transparent.svg). Square SVG. Checked 2026-10-06.
    iconUrl = "https://raw.githubusercontent.com/jellyfin/jellyfin-ux/master/branding/SVG/icon-transparent.svg";
    sha256 = "817c25b47442b192250448fe48cd5f265fe9183bc75aa12030bbe335495255d1";
  };

  service = _: {
    services.jellyfin.enable = true;
  };
  packages = pkgs: [ pkgs.jellyfin ];

  # Web UI and API, and client discovery. Local networks and Tailscale only: Jellyfin is not
  # meant to face the internet without a reverse proxy.
  ports = [
    {
      port = 8096;
      proto = "tcp";
      from = "lan";
    }
    {
      port = 7359;
      proto = "udp";
      from = "lan";
    }
  ];
  setup = "jellyfin-server";
  stateDirs = [ "jellyfin" ];

  notes = ''
    Data lives in /var/lib/jellyfin (the service user's), not in a profile's home, so there are no
    dataPaths. The system repo (server.nix) runs the first-run wizard in a private network
    namespace before the service starts, sets up hardware transcoding, /srv/media and the
    firewall from `ports`. The cache in /var/cache/jellyfin is removed with the data.
  '';
}
