# YouTube: free (a website), Firefox kiosk at youtube.com/tv with a TV User-Agent. On the ISO and
# pre-selected in the installer. Same kiosk settings as the system repo's built-in `youtube` app
# (nixos/modules/apps.nix, backend "firefox").
{
  format = 3;
  name = "YouTube";
  summary = "YouTube's TV interface, in a full-screen browser profile.";
  description = ''
    YouTube's TV interface in its own full-screen Firefox profile, driven by the controller like
    a keyboard. Sign in with your Google account from the TV screen.
  '';
  category = "video";
  homepage = "https://www.youtube.com";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # YouTube's own web app manifest (https://www.youtube.com/manifest.webmanifest), 192x192 PNG on Google's gstatic.com. Checked 2026-10-06.
    iconUrl = "https://www.gstatic.com/youtube/img/branding/favicon/favicon_192x192_v2.png";
    # Use the favicon Firefox stored in the kiosk profile.
    firefoxProfile = true;
  };
  onIso = true;
  starter = "ticked";
  dataPaths = [ ".local/share/hinteros/firefox/youtube" ];

  app = _: {
    kiosk = {
      url = "https://www.youtube.com/tv";
      # TV User-Agent for YouTube's leanback UI (youtube.com/tv refuses desktop browsers): a
      # PlayStation 5 browser UA. Not verifiable offline; if Google stops accepting it, change it
      # here and in the system repo's apps.nix (alternatives: an Xbox Series X or Fire TV UA).
      userAgent = "Mozilla/5.0 (PlayStation; PlayStation 5/2.26) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15";
    };
    # The TV UI is keyboard driven: arrows, Enter, Escape.
    input = "keyboard";
    backKey = "escape";
    order = 20;
  };
}
