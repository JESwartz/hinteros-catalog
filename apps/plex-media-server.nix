# Plex Media Server: unfree and not redistributable, a box-wide service (admin profile only,
# Server section, M10). Never cached, never on the ISO: nixpkgs' derivation downloads Plex's .deb
# from downloads.plex.tv on the box. The per-profile client is the separate `plex-htpc` entry.
{
  format = 3;
  kind = "service";
  name = "Plex Media Server";
  summary = "A Plex server for your movies, series and music.";
  # Runs on this box for everyone at home. The owner links it to a Plex account with a claim code,
  # then adds libraries in Plex's own web app. Plex does its own remote access.
  description = ''
    Plex Media Server keeps your movies, series and music in one library. Plex apps at home and,
    with Plex's remote access, outside your home play from this library.
  '';
  category = "video";
  homepage = "https://www.plex.tv";
  license = {
    unfree = true;
    unfreePackages = [ "plexmediaserver" ];
  };
  # The server; metadata and thumbnails grow in /var/lib/plex.
  sizeMiB = 500;
  icon = {
    # Plex's own site: web app manifest of watch.plex.tv (where www.plex.tv redirects), icon-512x512.png, 512x512 PNG. Checked 2026-10-06 (as plex-htpc).
    iconUrl = "https://watch.plex.tv/icons/icon-512x512.png";
    sha256 = "78072fd57aacff1f73dee6432fb8d7f0360f300b4545422fb767cce638c4e7d3";
  };
  # Never cached: Plex Media Server is not redistributable.
  delivery = "build";

  # The same Plex Terms of Service as plex-htpc (one document covers Plex's software).
  terms = {
    title = "Plex Terms of Service";
    version = "2025-10-30"; # "Revised October 30, 2025"
    url = "https://www.plex.tv/about/privacy-legal/plex-terms-of-service/";
    retrieved = "2026-10-06";
    text = ./terms/plex-2025-10-30.txt; # shared with plex-htpc
  };

  service = _: {
    services.plex.enable = true;
  };
  packages = pkgs: [ pkgs.plex ];

  # 32400: web app and API, open to all sources because Plex does its own remote access (relay,
  # or a port forward on the router) and its own sign-in. GDM discovery: local networks only.
  ports = [
    {
      port = 32400;
      proto = "tcp";
      from = "any";
    }
    {
      port = 32410;
      proto = "udp";
      from = "lan";
    }
    {
      port = 32412;
      proto = "udp";
      from = "lan";
    }
    {
      port = 32413;
      proto = "udp";
      from = "lan";
    }
    {
      port = 32414;
      proto = "udp";
      from = "lan";
    }
  ];
  setup = "plex-media-server";
  stateDirs = [ "plex" ];

  notes = ''
    Source: downloads.plex.tv (version pinned in nixpkgs). When Plex pulls a version the enable
    fails with a hash mismatch until nixpkgs is bumped. Unclaimed, the server accepts setup only
    from localhost; the box claims it with a plex.tv/claim code (POST /myplex/claim on
    127.0.0.1:32400). Hardware transcoding needs Plex Pass; the system repo gives the service
    the render device either way. No DLNA (1900/udp) and no Plex Companion (3005/tcp).
  '';
}
