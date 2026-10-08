# Hulu: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: Hulu does not support Linux officially, but Firefox on Linux with DRM plays at up to 720p according to reports. Not confirmed by a playback test.
{
  format = 2;
  name = "Hulu";
  summary = "Hulu shows and live TV, in a full-screen browser profile.";
  description = ''
    Hulu's website in its own full-screen Firefox profile, driven by the controller like a
    keyboard. 
  '';
  category = "video";
  homepage = "https://www.hulu.com";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # Vendor's own icon, found in its site/manifest, checked 2026-10-07: apple-touch-icon in the head of https://www.hulu.com, 180x180 PNG.
    iconUrl = "https://www.hulu.com/static/icons/apple-touch-icon.png";
    firefoxProfile = true;
  };
  onIso = true;
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/hulu" ];

  app = _: {
    kiosk.url = "https://www.hulu.com/welcome";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 36;
  };
}
