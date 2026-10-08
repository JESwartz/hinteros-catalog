# Twitch: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: Twitch streams are not DRM-protected and play in Firefox on Linux at up to 1080p (source quality).
{
  format = 2;
  name = "Twitch";
  summary = "Live streams and videos, in a full-screen browser profile.";
  description = ''
    Twitch's website in its own full-screen Firefox profile, driven by the controller like a
    keyboard. Free; an account is needed to chat and follow channels. Text entry (chat, search) needs a keyboard or the on-screen keyboard.
  '';
  category = "video";
  homepage = "https://www.twitch.tv";
  license = {
    free = true;
    redistributable = true;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # No iconUrl, checked 2026-10-07: its site declares only 16 px and 32 px icons and no manifest.
    firefoxProfile = true;
  };
  onIso = true;
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/twitch" ];

  app = _: {
    kiosk.url = "https://www.twitch.tv";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 42;
  };
}
