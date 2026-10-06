# Unit tests for the entry validator (lib/default.nix): each broken entry must be refused with
# the expected message, and the example entries must pass. Eval only.
{ pkgs, catalogLib }:
let
  inherit (pkgs) lib;

  good = {
    format = 1;
    name = "Example";
    summary = "An example app.";
    description = "An example app used by the validator tests.";
    category = "utilities";
    homepage = "https://example.org";
    license = {
      free = true;
      redistributable = true;
    };
    sizeMiB = 10;
    icon.desktopId = "org.example.Example";
    app = { pkgs, ... }: { package = pkgs.hello; };
  };

  problems = id: e: catalogLib.checkEntry id e;
  # True when some problem of `e` contains `text`.
  refuses = text: e: lib.any (lib.hasInfix text) (problems "example" e);

  results = lib.runTests {
    testGoodEntryPasses = {
      expr = problems "example" good;
      expected = [ ];
    };
    testBadId = {
      expr = lib.any (lib.hasPrefix "id:") (problems "Bad_Id" good);
      expected = true;
    };
    testUnknownField = {
      expr = refuses "unknown field(s): colour" (good // { colour = "red"; });
      expected = true;
    };
    testMissingField = {
      expr = refuses "missing field: summary" (builtins.removeAttrs good [ "summary" ]);
      expected = true;
    };
    testUnsupportedFormat = {
      expr = refuses "format: must be one of 1" (good // { format = 2; });
      expected = true;
    };
    testHttpHomepage = {
      expr = refuses "homepage: must be an https URL" (good // { homepage = "http://example.org"; });
      expected = true;
    };
    testMultiLineName = {
      expr = refuses "name: must be" (good // { name = "Two\nlines"; });
      expected = true;
    };
    testUnfreeNeedsPackageNames = {
      expr = refuses "must list its unfreePackages" (
        good
        // {
          license = {
            free = false;
            redistributable = false;
          };
        }
      );
      expected = true;
    };
    testFreeHasNoUnfreePackages = {
      expr = refuses "a free app has no unfreePackages" (
        good
        // {
          license = {
            free = true;
            redistributable = true;
            unfreePackages = [ "hello" ];
          };
        }
      );
      expected = true;
    };
    testUnfreeNotPreinstalled = {
      expr = refuses "preinstalled: only free apps" (
        good
        // {
          preinstalled = true;
          license = {
            free = false;
            redistributable = true;
            unfreePackages = [ "x" ];
          };
        }
      );
      expected = true;
    };
    testNativeNeedsDesktopId = {
      expr = refuses "icon.desktopId: required" (good // { icon = { }; });
      expected = true;
    };
    testNoPackagedIcon = {
      expr = refuses "app: field(s) not allowed: icon" (
        good
        // {
          app = _: {
            command = [ "x" ];
            icon = ./validator.nix;
          };
        }
      );
      expected = true;
    };
    testKioskNeedsHttps = {
      expr = refuses "app.kiosk.url" (
        good
        // {
          icon = { };
          app = _: { kiosk.url = "about:blank"; };
        }
      );
      expected = true;
    };
    testNoNixpkgsOverrides = {
      expr = refuses "nixos: top-level key(s) not allowed: nixpkgs" (
        good // { nixos = _: { nixpkgs.config.allowUnfree = true; }; }
      );
      expected = true;
    };
    testNoImports = {
      expr = refuses "not allowed: imports" (good // { nixos = _: { imports = [ ]; }; });
      expected = true;
    };
    testNeedsAppOrNixos = {
      expr = refuses "needs app or nixos" (builtins.removeAttrs good [ "app" ]);
      expected = true;
    };
    testRetiredNeedsReason = {
      expr = refuses "statusReason: required" (good // { status = "retired"; });
      expected = true;
    };
    testSelfDependency = {
      expr = refuses "cannot depend on itself" (good // { depends = [ "example" ]; });
      expected = true;
    };
    testTombstone = {
      expr = problems "old-app" {
        format = 1;
        name = "Old app";
        status = "removed";
        statusReason = "Discontinued upstream.";
      };
      expected = [ ];
    };
    testTombstoneHasNoModule = {
      expr = refuses "a removed entry has no app or nixos" {
        format = 1;
        name = "Old app";
        status = "removed";
        statusReason = "Discontinued upstream.";
        inherit (good) app;
      };
      expected = true;
    };
    testUnknownDependency = {
      expr = catalogLib.validate {
        a = good // {
          depends = [ "missing" ];
        };
      };
      expected = {
        _catalog = [ "a: depends on unknown app missing" ];
      };
    };
    testKindDerived = {
      expr = map (e: (catalogLib.normalize "x" e).kind) [
        good
        (good // { app = _: { kiosk.url = "https://example.org"; }; })
      ];
      expected = [
        "native"
        "web"
      ];
    };
    testSiteUrlDefaultsToHomepage = {
      expr = (catalogLib.normalize "x" good).icon;
      expected = {
        desktopId = "org.example.Example";
        siteUrl = "https://example.org";
      };
    };
  };
in
if results == [ ] then
  pkgs.runCommand "catalog-validator-tests" { } "touch $out"
else
  throw "catalog validator tests failed:\n${builtins.toJSON results}"
