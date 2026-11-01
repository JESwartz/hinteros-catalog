# HBO Max: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: HBO Max lists Firefox, not Linux; it blocked Linux in 2020 and recent reports say Firefox on Linux plays, at about 720p. Not confirmed by a playback test.
{
  format = 3;
  name = "HBO Max";
  summary = "HBO series and movies.";
  # The website runs in its own full-screen Firefox profile; the controller acts as a keyboard.
  description = ''
    HBO Max streams HBO series, Warner Bros. movies and other series and documentaries.
  '';
  category = "video";
  homepage = "https://www.hbomax.com";
  license = {
    unfree = false;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # Vendor's own icon, found in its site/manifest, checked 2026-10-07: apple-touch-icon in the head of https://www.hbomax.com (www.max.com redirects there), 180x180 PNG.
    iconUrl = "https://www.hbomax.com/dotcom/img/hbomax/apple-touch-icon.png";
    sha256 = "def031c4890e1ba75c3f29404e01112304a1e224658cdc06dc30ffed3d0ba498";
    firefoxProfile = true;
  };
  onIso = true;
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
