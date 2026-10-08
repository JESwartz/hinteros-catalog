# Disney+: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: Disney+ does not list Linux, but works in Firefox on Linux with DRM enabled since Disney fixed its 2019 Linux block; resolution is capped at 720p (reports of 480p on some setups).
{
  format = 2;
  name = "Disney+";
  summary = "Disney, Pixar, Marvel and Star Wars, in a full-screen browser profile.";
  description = ''
    Disney+'s website in its own full-screen Firefox profile, driven by the controller like a
    keyboard. 
  '';
  category = "video";
  homepage = "https://www.disneyplus.com";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # Vendor's own icon, found in its site/manifest, checked 2026-10-07: its own web app manifest (https://www.disneyplus.com/manifest.json), 192x192 PNG on Disney's bamgrid.com asset host.
    iconUrl = "https://static-assets.bamgrid.com/product/disneyplus/favicons/msftpwa-192x192-aurora.97f08a1eb58995c81687d0cf3f953796.png";
    firefoxProfile = true;
  };
  onIso = true;
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/disney-plus" ];

  app = _: {
    kiosk.url = "https://www.disneyplus.com/login";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 32;
  };
}
