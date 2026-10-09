# Netflix: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: Netflix's help centre lists Firefox 129+ on Linux with up to 1080p; it adds that Linux is not guaranteed to work.
{
  format = 3;
  name = "Netflix";
  summary = "Movies and series, in a full-screen browser profile.";
  description = ''
    Netflix's website in its own full-screen Firefox profile, driven by the controller like a
    keyboard. Needs a Netflix subscription; plays up to 1080p in Firefox on Linux (Netflix does not guarantee Linux). Firefox downloads the video DRM module itself on first play.
  '';
  category = "video";
  homepage = "https://www.netflix.com";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # No iconUrl, checked 2026-10-07: its icons are 64 px (apple-touch-icon nficon2016.png), below the 192 px minimum; the site serves no larger one.
    firefoxProfile = true;
  };
  onIso = true;
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/netflix" ];

  app = _: {
    kiosk.url = "https://www.netflix.com/login";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 31;
  };
}
