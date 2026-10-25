# VacuumTube: free, native Electron wrapper around YouTube's TV interface, from the binary cache.
# Not on the ISO, so picking it needs a network connection. Offered in the installer (not
# pre-selected): the YouTube kiosk entry stays the default, and this is the fallback if YouTube's
# TV page stops loading in Firefox.
{
  format = 3;
  name = "VacuumTube";
  summary = "An app for YouTube's TV interface.";
  # Unofficial; handles game controllers itself. Users sign in with a Google account from the TV
  # screen.
  description = ''
    VacuumTube shows YouTube's TV interface in its own app. You can use a game controller to
    watch videos and browse channels.
  '';
  category = "video";
  homepage = "https://github.com/shy1132/VacuumTube";
  # The upstream README, unmodified (see README, "Upstream READMEs").
  readme = {
    url = "https://github.com/shy1132/VacuumTube/blob/21ed770379deefc123c1026774b7d8fc1bc0d84b/README.md";
    retrieved = "2026-10-25";
    text = ./readme/vacuum-tube.md;
  };
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
    sha256 = "a315a1175e5835eee596891a65c57ace8d24ba940e464854c7f0d380e56802e7";
  };
  # Offered, not ticked: the YouTube entry already covers the same service.
  starter = "offered";
  # Settings, login and Chromium cache (Electron userData, "VacuumTube"; config folder per upstream README).
  dataPaths = [
    ".config/VacuumTube"
    ".cache/VacuumTube"
  ];

  # The sandbox hides /dev/input; the app reads the controller itself.
  permissions.gamepad = "required";

  app =
    { pkgs, ... }:
    {
      package = pkgs.vacuum-tube;
      # Implements controller navigation and playback controls itself (upstream README).
      input = "gamepad";
      order = 25;
    };
}
