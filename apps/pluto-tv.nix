# Pluto TV: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: Pluto TV is ad-supported and works in current browsers; free live TV, no Widevine needed for most streams.
{
  format = 2;
  name = "Pluto TV";
  summary = "Free live channels and on-demand TV, in a full-screen browser profile.";
  description = ''
    Pluto TV's website in its own full-screen Firefox profile, driven by the controller like a
    keyboard. 
  '';
  category = "video";
  homepage = "https://pluto.tv";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # Vendor's own icon, found in its site/manifest, checked 2026-10-07: apple-touch-icon in the head of https://pluto.tv (also in its manifest, https://pluto.tv/api/manifest/), 256x256 PNG.
    iconUrl = "https://pluto.tv/favicon/large.png";
    firefoxProfile = true;
  };
  onIso = false; # Store only: in format 2, onIso would also list it in the installer
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/pluto-tv" ];

  app = _: {
    kiosk.url = "https://pluto.tv";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 39;
  };
}
