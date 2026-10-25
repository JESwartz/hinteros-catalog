# Firefox: free, the plain browser in a Firefox kiosk profile (address bar and tabs stay; the
# compositor shows it fullscreen). On the ISO and pre-selected in the installer.
{
  format = 3;
  name = "Firefox";
  summary = "A web browser.";
  # Full screen, with its own profile. Keyboard and mouse work, or the controller as a pointer.
  description = ''
    Firefox is a free, open-source web browser from Mozilla. It has tabs, bookmarks and add-ons.
  '';
  category = "utilities";
  homepage = "https://www.mozilla.org/firefox/";
  # The upstream README, unmodified (see README, "Upstream READMEs").
  readme = {
    url = "https://github.com/mozilla-firefox/firefox/blob/efd2d1e6f77570ae6bc5294731a68101e45c81a3/README.md";
    retrieved = "2026-10-25";
    text = ./readme/firefox.md;
  };
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # about:home has no favicon of its own: use the Mozilla site's.
    siteUrl = "https://www.mozilla.org";
    # Mozilla's official Firefox source repo, https://github.com/mozilla-firefox/firefox (browser/branding/official/content/about-logo@2x.png, 384x384 PNG). Checked 2026-10-06.
    iconUrl = "https://raw.githubusercontent.com/mozilla-firefox/firefox/main/browser/branding/official/content/about-logo@2x.png";
    sha256 = "310bc31d4b036d47c84fc020005b08e7b1a2a5582bd9ff54781b647cc0ff3ba3";
  };
  onIso = true;
  starter = "ticked";
  # Bookmarks, history, logins and add-ons of the kiosk profile.
  dataPaths = [ ".local/share/hinteros/firefox/firefox" ];

  permissions = {
    # Save files to the profile's Downloads folder.
    downloads = "optional";
    # Pages on the home network (a router, a NAS) and on this box.
    lan = "optional";
  };

  app = _: {
    kiosk = {
      url = "about:home";
      fullscreenOnly = true; # keep the address bar and tabs
    };
    input = "keyboard";
    backKey = "escape";
    order = 40;
  };
}
