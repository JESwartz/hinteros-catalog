# HBO Max: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: HBO Max lists Firefox, not Linux; it blocked Linux in 2020 and recent reports say Firefox on Linux plays, at about 720p. Not confirmed by a playback test.
{
  format = 2;
  name = "HBO Max";
  summary = "HBO series and movies, in a full-screen browser profile.";
  description = ''
    HBO Max's website in its own full-screen Firefox profile, driven by the controller like a
    keyboard. 
  '';
  category = "video";
  homepage = "https://www.hbomax.com";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # Vendor's own icon, found in its site/manifest, checked 2026-10-07: apple-touch-icon in the head of https://www.hbomax.com (www.max.com redirects there), 180x180 PNG.
    iconUrl = "https://www.hbomax.com/dotcom/img/hbomax/apple-touch-icon.png";
    firefoxProfile = true;
  };
  onIso = false; # Store only: in format 2, onIso would also list it in the installer
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/hbo-max" ];

  app = _: {
    kiosk.url = "https://www.hbomax.com";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 35;
  };
}
