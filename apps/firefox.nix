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
  };
  onIso = true;
  starter = "ticked";
  # Bookmarks, history, logins and add-ons of the kiosk profile.
  dataPaths = [ ".local/share/hinteros/firefox/firefox" ];

  # Save files to the profile's Downloads folder.
  permissions.downloads = "optional";

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
