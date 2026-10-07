# VacuumTube: free, native Electron wrapper around YouTube's TV interface, from the binary cache.
# Optional: not on the ISO and not in the installer; the YouTube kiosk entry is the default.
{
  format = 2;
  name = "VacuumTube";
  summary = "YouTube TV app; fallback if YouTube's TV page stops loading in Firefox.";
  description = ''
    An unofficial desktop app that shows YouTube's TV interface and handles game controllers
    itself. Install it if the YouTube app stops working in the browser. Sign in with your Google
    account from the TV screen.
  '';
  category = "video";
  homepage = "https://github.com/shy1132/VacuumTube";
  license = {
    free = true;
    redistributable = true;
  };
  # nix path-info -S of the closure is about 1.7 GiB including Electron's dependencies, most of
  # which a box already has; this is an estimate, not measured on a box.
  sizeMiB = 450;
  icon = {
    # VacuumTube's own repository (assets/icon.png, 1024x1024 PNG, MIT). Checked 2026-10-07.
    desktopId = "VacuumTube";
    iconUrl = "https://raw.githubusercontent.com/shy1132/VacuumTube/main/assets/icon.png";
  };
  # Not offered in the installer: the YouTube entry already covers the same service; users add this
  # from the Store only if that one breaks.
  # Settings, login and Chromium cache (Electron userData, "VacuumTube"; config folder per upstream README).
  dataPaths = [
    ".config/VacuumTube"
    ".cache/VacuumTube"
  ];

  app =
    { pkgs, ... }:
    {
      package = pkgs.vacuum-tube;
      # Implements controller navigation and playback controls itself (upstream README).
      input = "gamepad";
      order = 25;
    };
}
