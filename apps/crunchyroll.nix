# Crunchyroll: free (a website), Firefox kiosk, preinstalled.
{
  format = 1;
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
  preinstalled = true;

  app = _: {
    kiosk.url = "https://www.crunchyroll.com";
    input = "keyboard";
    backKey = "escape";
    order = 30;
  };
}
