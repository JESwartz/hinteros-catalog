# Plex HTPC: unfree and not redistributable, native. Never cached, never in the ISO: nixpkgs'
# derivation downloads the snap from Snapcraft on the box and repackages it there.
{
  format = 1;
  name = "Plex";
  summary = "Watch your Plex libraries with Plex's TV interface.";
  description = ''
    Plex HTPC, Plex's 10-foot client for the big screen. Sign in with your Plex account to watch
    your own or shared Plex servers. The app is downloaded from Plex and prepared on this box
    during install, which takes a few minutes.
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
  };
  featured = true;

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
