# Evaluates (never builds) one NixOS system with every box feature and every service module,
# with the union of the services' unfreePackages allowed. Catches typos in option names, failed
# assertions and conflicts between features and services. Apps are not part of the system any
# more (each profile has its own app env), so their packages are checked by tests/packages.nix.
# The real feature table is the system repo's box-features.nix; the one below is this repo's
# stand-in, documented in apps.md, and must name every feature the validator accepts.
{
  pkgs,
  nixpkgs,
  catalog,
  features,
}:
let
  inherit (pkgs) lib;
  services = lib.filter (e: e.kind == "service" && e.status != "removed") (lib.attrValues catalog);
  unfree = lib.concatMap (e: e.license.unfreePackages) services;

  featureConfig = {
    graphics32 = {
      hardware.graphics.enable32Bit = true;
      services.pipewire.alsa.support32Bit = true;
    };
    steam-devices.hardware.steam-hardware.enable = true;
  };

  system = nixpkgs.lib.nixosSystem {
    modules = [
      (
        { pkgs, ... }:
        {
          nixpkgs.hostPlatform = "x86_64-linux";
          nixpkgs.config.allowUnfreePredicate = p: builtins.elem (lib.getName p) unfree;
          boot.loader.grub.enable = false;
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };
          system.stateVersion = "25.11";
          environment.systemPackages = lib.concatMap (e: e.packages pkgs) services;
          services.pipewire = {
            enable = true;
            alsa.enable = true;
          };
        }
      )
    ]
    ++ map (f: featureConfig.${f}) features
    ++ map (e: e.service) services;
  };
  drvPath = builtins.unsafeDiscardStringContext system.config.system.build.toplevel.drvPath;
in
assert lib.sort lib.lessThan features == lib.sort lib.lessThan (lib.attrNames featureConfig);
pkgs.runCommand "catalog-nixos-eval" { } ''
  echo ${drvPath} > $out
''
