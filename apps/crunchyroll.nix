# Crunchyroll: free (a website), Firefox kiosk. Store only (not on the ISO, not in the installer).
{
  format = 3;
  name = "Crunchyroll";
  summary = "Anime series and movies.";
  # The website runs in its own full-screen Firefox profile; the controller acts as a keyboard.
  # Needs a Crunchyroll account; Firefox downloads the video DRM module itself on first play.
  description = ''
    Crunchyroll streams anime series and movies from Japan. Many new episodes come out soon
    after they show in Japan.
  '';
  category = "video";
  homepage = "https://www.crunchyroll.com";
  license = {
    unfree = false;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # No iconUrl, re-checked 2026-10-07: with a browser User-Agent www.crunchyroll.com serves its page but
    # declares no favicon, apple-touch-icon or web app manifest; /favicon.ico, /apple-touch-icon.png and
    # /manifest.json answer 403 (Cloudflare) to plain requests; static.crunchyroll.com/cxweb/assets/img/favicon.ico
    # is an empty (0 byte) file. The only public image is og-image.png, a 1958x1672 social card, not an icon.
    # So the favicon Firefox stores in the kiosk profile (below) and the letter tile cover it.
    firefoxProfile = true;
  };
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/crunchyroll" ];

  app = _: {
    kiosk.url = "https://www.crunchyroll.com";
    input = "keyboard";
    backKey = "escape";
    order = 30;
  };
}
