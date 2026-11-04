# Taisei: free (MIT code, CC-BY-4.0 assets), native, from the binary cache. The game reads the
# controller itself (SDL game controllers, menus included). Upstream's README is
# reStructuredText, so the entry has no `readme` (the Store page renders Markdown).
{
  format = 3;
  name = "Taisei";
  summary = "A shoot 'em up with many bullets on screen.";
  description = ''
    Taisei is a shoot 'em up in the style of the Touhou Project games. Fly through six stages,
    dodge patterns of bullets and fight the bosses at the end of each stage.
  '';
  category = "games";
  homepage = "https://taisei-project.org";
  license = {
    unfree = false;
  };
  # About 240 MiB more than the libraries a box already has: an estimate, not measured on a box.
  sizeMiB = 240;
  icon = {
    desktopId = "org.taisei_project.Taisei";
    # The project's own repository (xdg/icons/taisei-512.png at 5668c41, 512x512 PNG). Checked
    # 2026-10-25.
    iconUrl = "https://raw.githubusercontent.com/taisei-project/taisei/5668c41b41f7227d21fc80cf56997d4d30356ce7/xdg/icons/taisei-512.png";
    sha256 = "d2e21648a7b9677d015a6502afbc2817e1c06e6bc2d14574c70ac750b3c6665e";
  };

  # Without the sandbox: settings, progress and replays (upstream's XDG data directory; with the
  # sandbox it is in its home, listed automatically).
  dataPaths = [ ".local/share/taisei" ];
  permissions = {
    # The sandbox hides /dev/input; the game reads the controller itself.
    gamepad = "required";
  };

  app =
    { pkgs, ... }:
    {
      package = pkgs.taisei;
      input = "gamepad";
    };
}
