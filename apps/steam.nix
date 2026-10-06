# Steam: unfree (unfreeRedistributable), native. Never in the vendor cache or the ISO: the box
# fetches the bootstrap from Valve and builds the FHS wrapper itself. Its free dependencies
# (32-bit Mesa and friends) still come from cache.nixos.org.
{
  format = 1;
  name = "Steam";
  summary = "Play your Steam library on the TV.";
  description = ''
    Valve's game store and launcher. Your installed games appear in Games, and Steam's own
    Big Picture mode handles the store, downloads and settings. Each profile has its own
    Steam login and library.
  '';
  category = "games";
  homepage = "https://store.steampowered.com";
  license = {
    free = false;
    redistributable = true;
    unfreePackages = [
      "steam"
      "steam-unwrapped"
    ];
  };
  # Bootstrap and 32-bit runtime (~500 MiB), plus Steam's own client update on first start.
  sizeMiB = 1000;
  icon = {
    desktopId = "steam";
    siteUrl = "https://store.steampowered.com";
  };
  ageRating = null;
  requires = [ "graphics32" ];
  featured = true;

  # No `app`: the session daemon has a built-in `steam` entry (Big Picture, games.list).
  # programs.steam also enables 32-bit graphics and the controller udev rules.
  nixos = _: { programs.steam.enable = true; };
  packages = pkgs: [ pkgs.steam ];

  notes = ''
    Valve occasionally replaces the bootstrap tarball; a nixpkgs bump fixes the hash. The Games
    section prompts to install this entry when Steam is missing (M8).
  '';
}
