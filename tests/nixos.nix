# Evaluates (never builds) one NixOS system with every catalog entry's `nixos` module and
# packages, with the union of the entries' unfreePackages allowed. Catches typos in option
# names, failed assertions and conflicts between entries. The full integration with
# hinteros.apps is tested in the system repo.
{
  pkgs,
  nixpkgs,
  catalog,
}:
let
  inherit (pkgs) lib;
  entries = lib.attrValues (lib.filterAttrs (_: e: e.status != "removed") catalog);
  unfree = lib.concatMap (e: e.license.unfreePackages) entries;

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
          environment.systemPackages = lib.concatMap (e: e.packages pkgs) entries;
        }
      )
    ]
    ++ map (e: e.nixos) (lib.filter (e: e.nixos != null) entries);
  };
  drvPath = builtins.unsafeDiscardStringContext system.config.system.build.toplevel.drvPath;
in
pkgs.runCommand "catalog-nixos-eval" { } ''
  echo ${drvPath} > $out
''
