# Crunchyroll: free (a website), Firefox kiosk. On the ISO, so an offline install can pick it.
{
  format = 2;
  name = "Crunchyroll";
  summary = "Anime streaming, in a full-screen browser profile.";
  description = ''
    Crunchyroll's website in its own full-screen Firefox profile, driven by the controller like
    a keyboard. Needs a Crunchyroll account; Firefox downloads the video DRM module itself on
    first play.
  '';
  category = "video";
  homepage = "https://www.crunchyroll.com";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # crunchyroll.com refuses non-browser icon fetches (403): use the favicon Firefox stored.
    firefoxProfile = true;
  };
  onIso = true;
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/crunchyroll" ];

  app = _: {
    kiosk.url = "https://www.crunchyroll.com";
    input = "keyboard";
    backKey = "escape";
    order = 30;
  };
}
