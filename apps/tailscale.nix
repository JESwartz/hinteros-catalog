# Tailscale: free (the client), a box-wide service (admin profile only, Server section, M10).
# Remote access to this box's servers over the owner's tailnet. Sign-in is a QR code on the box.
{
  format = 3;
  kind = "service";
  name = "Tailscale";
  summary = "Reach this box's servers from your own devices, from anywhere.";
  # The owner signs the box in to their tailnet; their phones and laptops on the same tailnet
  # reach the Jellyfin and Plex servers (and SSH, when on) as if they were at home.
  description = ''
    Tailscale puts this box on your private Tailscale network. Your devices on that network can
    use this box's servers from anywhere.
  '';
  category = "utilities";
  homepage = "https://tailscale.com";
  license = {
    unfree = false;
  };
  sizeMiB = 80;
  # No iconUrl yet: no official logo URL has been checked (2026-10-20). The siteUrl discovery
  # (homepage) covers it.
  icon = { };

  service = _: {
    services.tailscale = {
      enable = true;
      # No exit node, no subnet routes: the box is a plain tailnet node.
      useRoutingFeatures = "none";
    };
  };
  packages = pkgs: [ pkgs.tailscale ];

  # WireGuard: direct connections instead of DERP relays.
  ports = [
    {
      port = 41641;
      proto = "udp";
      from = "any";
    }
  ];
  setup = "tailscale";
  stateDirs = [ "tailscale" ];

  notes = ''
    Sign-in is not configuration: the daemon starts `tailscale login` and shows the auth URL as a
    QR code, so no rebuild. Signing out keeps the service on. The system repo opens the `lan`
    ports of the other services (and SSH while on) on tailscale0. No Tailscale SSH, no
    --accept-routes.
  '';
}
