# Cloudflare Tunnel: free (cloudflared), a box-wide service (admin profile only, Server section,
# M10). A remotely managed tunnel for Cloudflare Zero Trust private networks: devices with the
# WARP client in the owner's Zero Trust organisation reach this box's servers. No public
# hostnames.
{
  format = 3;
  kind = "service";
  name = "Cloudflare Tunnel";
  summary = "Reach this box's servers through your Cloudflare Zero Trust network.";
  # The owner makes a tunnel and a private-network route to this box in the Zero Trust
  # dashboard, then types the tunnel's token here. Devices with WARP signed in to the same
  # organisation reach the box's servers.
  description = ''
    Cloudflare Tunnel connects this box to your Cloudflare Zero Trust network. Devices with the
    Cloudflare WARP app in your organisation can use this box's servers from anywhere.
  '';
  category = "utilities";
  homepage = "https://www.cloudflare.com/products/tunnel/";
  license = {
    unfree = false;
  };
  sizeMiB = 40;
  # No iconUrl yet: no official logo URL has been checked (2026-10-20). The siteUrl discovery
  # (homepage) covers it.
  icon = { };

  # No module: the system repo runs `hinteros-cloudflared.service` while this service is on and
  # a token is stored (it needs the token at run time, not in the Nix store).
  service = { };
  packages = pkgs: [ pkgs.cloudflared ];

  # Outbound only.
  ports = [ ];
  setup = "cloudflare-tunnel";
  stateDirs = [ "hinteros/services/cloudflare-tunnel" ];

  notes = ''
    Remotely managed tunnel: routes and WARP routing are set in the Zero Trust dashboard. The
    token is stored 0600 root by hinteros-system and passed with LoadCredential. An nftables
    rule on the unit's cgroup lets cloudflared reach this box's own addresses only on the other
    enabled services' ports. Cloudflare's terms limit video through its CDN; private networks
    are not the CDN, but the owner should know their plan's terms.
  '';
}
