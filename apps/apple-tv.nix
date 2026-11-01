# Apple TV: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: Apple documents Apple TV in any web browser such as Chrome or Firefox, with no Linux block; resolution on Linux is limited by Widevine L3 (about 720p, not published by Apple).
{
  format = 3;
  name = "Apple TV";
  summary = "Apple Original series and movies.";
  # The website runs in its own full-screen Firefox profile; the controller acts as a keyboard.
  description = ''
    Apple TV streams series, movies and documentaries that Apple makes.
  '';
  category = "video";
  homepage = "https://tv.apple.com";
  license = {
    unfree = false;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # Vendor's own icon, found in its site/manifest, checked 2026-10-07: its own web app manifest (https://tv.apple.com/manifest.json), 192x192 PNG on tv.apple.com.
    iconUrl = "https://tv.apple.com/assets/app-icons/pwa-manifest/tv-icon_192.png";
    sha256 = "295a2ca32f519919dd6e3a90d60fbf4e47420769b9255f5c478753bcf7b6f49e";
    firefoxProfile = true;
  };
  onIso = true;
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/apple-tv" ];

  app = _: {
    kiosk.url = "https://tv.apple.com";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 33;
  };
}
