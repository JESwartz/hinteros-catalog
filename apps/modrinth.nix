# Modrinth App: unfreeRedistributable in nixpkgs (GPL-3.0 code with unfree parts), native (Tauri),
# cached like Steam (`delivery = "download"`): CI builds it, the binary cache serves it. A launcher for
# Minecraft: Java Edition with mods and modpacks from Modrinth.
# Playing Minecraft needs a paid Microsoft account, signed in from the app. Minecraft: Java
# Edition has no controller support of its own: `keyboard` input gives the right stick as the
# mouse, RT and LT as left and right click, the d-pad as arrows, A as Enter, Back as Escape. A
# controller mod (for example MidnightControls, installed from Modrinth) adds controller play.
{
  format = 3;
  name = "Modrinth";
  summary = "A launcher for Minecraft with mods and modpacks.";
  description = ''
    The Modrinth App starts Minecraft: Java Edition. Find mods, resource packs and modpacks on
    Modrinth, install them in instances and keep them up to date.
  '';
  category = "games";
  homepage = "https://modrinth.com";
  # The upstream README, unmodified (see README, "Upstream READMEs").
  readme = {
    url = "https://github.com/modrinth/code/blob/4ccf4d51804627cd0687ce7dfd5004f20c267acc/README.md";
    retrieved = "2026-10-25";
    text = ./readme/modrinth.md;
  };
  license = {
    unfree = true;
    unfreePackages = [
      "modrinth-app"
      "modrinth-app-unwrapped"
    ];
  };
  # The app with the Java runtimes it brings for Minecraft (about 2150 MiB more than the libraries
  # a box already has), plus Minecraft and the mods it downloads: an estimate, not measured on a
  # box.
  sizeMiB = 2500;
  icon = {
    # The package's desktop file is "Modrinth App.desktop", a name with a space, which desktopId
    # cannot hold: this is its icon name, and the icon comes from iconUrl.
    desktopId = "ModrinthApp";
    # The project's own repository (apps/app/icons/128x128@2x.png at 4ccf4d5, 256x256 PNG).
    # Checked 2026-10-25.
    iconUrl = "https://raw.githubusercontent.com/modrinth/code/4ccf4d51804627cd0687ce7dfd5004f20c267acc/apps/app/icons/128x128@2x.png";
    sha256 = "9cf29b6b33efbcc5fbf6968abbde374b0bf49a658efed63d46066c858ffc729c";
  };
  # unfreeRedistributable (checked against nixpkgs by tests/packages.nix).
  delivery = "download";

  # Refresh when Modrinth revises its terms (see README, "Refreshing vendor terms"). The text is
  # the page's source in Modrinth's repository (apps/frontend/src/pages/legal/terms.vue at
  # 4ccf4d5), as plain text.
  terms = {
    title = "Modrinth Terms of Use";
    version = "2026-08-13"; # "Last modified: August 13, 2026"
    url = "https://modrinth.com/legal/terms";
    retrieved = "2026-10-25";
    text = ./terms/modrinth-2026-08-13.txt;
  };

  permissions = {
    # Minecraft worlds opened to LAN, and servers on the home network.
    lan = "optional";
  };

  app =
    { pkgs, ... }:
    {
      package = pkgs.modrinth-app;
      input = "keyboard";
      backKey = "escape";
    };
}
