# Moonlight: free, native, from the binary cache.
{
  format = 3;
  name = "Moonlight";
  summary = "Game streaming from your PC.";
  description = ''
    Moonlight plays games that stream from a PC on your network. The PC runs Sunshine or NVIDIA
    GameStream.
  '';
  category = "games";
  homepage = "https://moonlight-stream.org";
  license = {
    free = true;
    redistributable = true;
  };
  sizeMiB = 150;
  icon = {
    desktopId = "com.moonlight_stream.Moonlight";
    # Project's own site (web app manifest of moonlight-stream.org, source: github.com/moonlight-stream/moonlight-stream.github.io, images/manifest/icons-512.png). 512x512 PNG. Checked 2026-10-06.
    iconUrl = "https://moonlight-stream.org/images/manifest/icons-512.png";
  };
  # Pairing keys and settings (QSettings, organisation and app name "Moonlight Game Streaming Project").
  dataPaths = [
    ".config/Moonlight Game Streaming Project"
    ".cache/Moonlight Game Streaming Project"
    ".local/share/Moonlight Game Streaming Project"
  ];

  # The sandbox hides /dev/input; the app reads the controller itself.
  permissions.gamepad = "required";

  app =
    { pkgs, ... }:
    {
      package = pkgs.moonlight-qt;
      input = "gamepad";
    };
}
