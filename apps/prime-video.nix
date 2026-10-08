# Prime Video: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: Amazon lists Firefox as supported but says other systems than Windows or macOS are limited to standard definition.
{
  format = 3;
  name = "Prime Video";
  summary = "Prime Video movies and series, in a full-screen browser profile.";
  description = ''
    Prime Video's website in its own full-screen Firefox profile, driven by the controller like a
    keyboard. Needs an Amazon Prime or Prime Video subscription; on Linux Amazon limits playback to standard definition (about 480p). Firefox downloads the video DRM module itself on first play. Prices and catalogue depend on your country.
  '';
  category = "video";
  homepage = "https://www.primevideo.com";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # No iconUrl, checked 2026-10-07: its largest icon is a 152 px apple-touch-icon, below the 192 px minimum.
    firefoxProfile = true;
  };
  onIso = true;
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/prime-video" ];

  app = _: {
    kiosk.url = "https://www.primevideo.com";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 34;
  };
}
