# Extreme Tux Racer: free, native, from the binary cache. A keyboard game: `keyboard` input gives
# the d-pad as arrows (steer, menus), A as Enter, Back as Escape. Its own joystick support is
# for steering only (the menus need the keyboard), so the keyboard mapping is used.
# No `readme`: the project is on SourceForge, without a README in its repository.
{
  format = 3;
  name = "Extreme Tux Racer";
  summary = "Race Tux down snowy mountains.";
  description = ''
    Extreme Tux Racer is a downhill racing game. Steer Tux down slopes of snow and ice, collect
    fish on the way and reach the finish in the best time.
  '';
  category = "games";
  homepage = "https://sourceforge.net/projects/extremetuxracer/";
  license = {
    unfree = false;
  };
  # About 50 MiB more than the libraries a box already has: an estimate, not measured on a box.
  sizeMiB = 50;
  icon = {
    desktopId = "net.sourceforge.extremetuxracer";
    # No discovery and no iconUrl: SourceForge pages show SourceForge's own logo, and SourceForge
    # refuses the daemon's requests (403) for the project's files. The Store shows the letter tile
    # until the game is installed, then the icon of its desktop file.
    siteUrl = null;
  };

  app =
    { pkgs, ... }:
    {
      package = pkgs.extremetuxracer;
      input = "keyboard";
      backKey = "escape";
    };
}
