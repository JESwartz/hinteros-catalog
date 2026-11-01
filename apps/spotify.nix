# Spotify: free (a website), Firefox kiosk. On the ISO (no vendor software is installed, only a
# Firefox profile); Store only, not in the installer. Playback limits checked 2026-10-07: Spotify's web player supports Firefox on Linux; audio is Widevine-protected, so Firefox needs its DRM module (it downloads it itself).
{
  format = 3;
  name = "Spotify";
  summary = "Music and podcasts.";
  # The web player runs in its own full-screen Firefox profile; the controller acts as a keyboard.
  description = ''
    Spotify streams music, podcasts and audiobooks. You can make playlists and follow artists.
  '';
  category = "music";
  homepage = "https://open.spotify.com";
  license = {
    unfree = false;
  };
  # Only the shared Firefox; nothing app-specific is downloaded.
  sizeMiB = 1;
  icon = {
    # Vendor's own icon, found in its site/manifest, checked 2026-10-07: icon in its web player manifest (open.spotifycdn.com/cdn/generated/manifest-web-player.*.json), 256x256 PNG on Spotify's own spotifycdn.com.
    iconUrl = "https://open.spotifycdn.com/cdn/images/icons/Spotify_256.png";
    sha256 = "17e41e58ac71f2688f1653ef40e6d97973db98f33714316387e1d04c72f899a6";
    firefoxProfile = true;
  };
  onIso = true;
  # The kiosk profile (cookies, login, Widevine) lives in one directory per app.
  dataPaths = [ ".local/share/hinteros/firefox/spotify" ];

  app = _: {
    kiosk.url = "https://open.spotify.com";
    # Web players are made for mouse and touch: the controller acts as keyboard, Escape goes back.
    input = "keyboard";
    backKey = "escape";
    order = 41;
  };
}
