# Freedoom: Phase 2 in UZDoom: free (UZDoom GPL-3.0, Freedoom BSD-3-Clause), native, from the
# binary cache. UZDoom is the engine, Freedoom the game data (a free replacement for Doom's), so
# the command starts UZDoom with Freedoom's Phase 2 IWAD. Phase 1 (freedoom-phase1) is its own
# entry with the same packages. UZDoom reads the controller itself (SDL game controllers,
# menus included).
# No `package`: the app's `package` sets the command to its main program, so this entry sets
# only `command`; its store paths bring UZDoom and Freedoom into the env. Without a package in
# the env there is no desktop file, so the icon comes from iconUrl. Freedoom's own icons are made
# at build time and are not in its repository: the icon is UZDoom's.
{
  format = 3;
  name = "Freedoom: Phase 2";
  summary = "A first-person shooter in 32 levels.";
  description = ''
    Freedoom: Phase 2 is a free first-person shooter for Doom engines, here in UZDoom. Fight
    through 32 levels full of monsters and bigger weapons, with new graphics, sounds and music.
  '';
  category = "games";
  homepage = "https://freedoom.github.io";
  # The engine's upstream README, unmodified (see README, "Upstream READMEs"). Freedoom's own
  # README is AsciiDoc, which the Store page does not render.
  readme = {
    url = "https://github.com/UZDoom/UZDoom/blob/62afe5f0a914610bd70ea9302da992ede38a36ad/README.md";
    retrieved = "2026-10-25";
    text = ./readme/freedoom-phase2.md;
  };
  license = {
    unfree = false;
  };
  # UZDoom (about 40 MiB more than the libraries a box already has) and Freedoom's IWADs (about
  # 85 MiB): an estimate, not measured on a box. Phase 1 shares both.
  sizeMiB = 130;
  icon = {
    desktopId = "org.zdoom.UZDoom";
    # UZDoom's own repository (branding/misc/appicon.png at 62afe5f, 1024x1024 PNG, CC-BY-SA-4.0).
    # Checked 2026-10-25.
    iconUrl = "https://raw.githubusercontent.com/UZDoom/UZDoom/62afe5f0a914610bd70ea9302da992ede38a36ad/branding/misc/appicon.png";
    sha256 = "f6df99e6d67f5ee108580c334b3436ab63e0b04fe728a2a4939bcb06100381dd";
  };

  permissions = {
    # The sandbox hides /dev/input; the engine reads the controller itself.
    gamepad = "required";
  };

  app =
    { pkgs, ... }:
    {
      command = [
        (pkgs.lib.getExe pkgs.uzdoom)
        "-iwad"
        "${pkgs.freedoom}/share/games/doom/freedoom2.wad"
      ];
      input = "gamepad";
    };

  # `packages` (licence checks, cache builds, size) defaults to app.package; this entry has
  # only a command.
  packages = pkgs: [
    pkgs.uzdoom
    pkgs.freedoom
  ];
}
