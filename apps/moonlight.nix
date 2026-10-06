# Moonlight: free, native, from the binary cache.
{
  format = 2;
  name = "Moonlight";
  summary = "Stream games from your gaming PC to the TV.";
  description = ''
    Moonlight plays games streamed from a PC running Sunshine or NVIDIA GameStream on your
    network, with your controller.
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
  installer = true;
  # Pairing keys and settings (QSettings, organisation and app name "Moonlight Game Streaming Project").
  dataPaths = [
    ".config/Moonlight Game Streaming Project"
    ".cache/Moonlight Game Streaming Project"
    ".local/share/Moonlight Game Streaming Project"
  ];

  app =
    { pkgs, ... }:
    {
      package = pkgs.moonlight-qt;
      input = "gamepad";
    };
}
