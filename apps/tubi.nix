# Tubi: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: Tubi is ad-supported and works in any current browser; free content is not Widevine-protected, up to 1080p.
{
  format = 2;
  name = "Tubi";
  summary = "Free movies and TV with ads, in a full-screen browser profile.";
  description = ''
    Tubi's website in its own full-screen Firefox profile, driven by the controller like a
    keyboard. 
  '';
  category = "video";
  homepage = "https://tubitv.com";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # Vendor's own icon, found in its site/manifest, checked 2026-10-07: its web app manifest (https://tubitv.com/manifest.json), 192x192 PNG on Tubi's mcdn.tubitv.com.
    iconUrl = "https://mcdn.tubitv.com/web/repaint/android-chrome-192x192.png";
    firefoxProfile = true;
  };
  onIso = true;
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/tubi" ];

  app = _: {
    kiosk.url = "https://tubitv.com";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 38;
  };
}
