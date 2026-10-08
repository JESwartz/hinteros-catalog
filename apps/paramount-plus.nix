# Paramount+: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: Paramount+ lists Firefox but not Linux; users report playback works, and that Firefox tracking protection can break it (turn it off for the site).
{
  format = 2;
  name = "Paramount+";
  summary = "Paramount+ shows and live TV, in a full-screen browser profile.";
  description = ''
    Paramount+'s website in its own full-screen Firefox profile, driven by the controller like a
    keyboard. 
  '';
  category = "video";
  homepage = "https://www.paramountplus.com";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # Vendor's own icon, found in its site/manifest, checked 2026-10-07: icon in its web app manifest (https://www.paramountplus.com/manifest.json), 192x192 PNG.
    iconUrl = "https://www.paramountplus.com/assets/images/paramount-plus-app-store-logo-192.png";
    firefoxProfile = true;
  };
  onIso = false; # Store only: in format 2, onIso would also list it in the installer
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/paramount-plus" ];

  app = _: {
    kiosk.url = "https://www.paramountplus.com";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 37;
  };
}
