# Unit tests for the entry validator (lib/default.nix): each broken entry must be refused with
# the expected message, and the example entries must pass. Eval only.
{ pkgs, catalogLib }:
let
  inherit (pkgs) lib;

  good = {
    format = 2;
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

  terms = {
    title = "Example Terms";
    version = "1.0";
    url = "https://example.org/terms";
    retrieved = "2026-10-06";
    text = ./fixtures/example-1.0.txt;
  };
  unfreeRedistributable = {
    license = {
      free = false;
      redistributable = true;
      unfreePackages = [ "x" ];
    };
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
      expr = refuses "format: must be one of 2" (good // { format = 1; });
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
    testUnfreeNotOnIso = {
      expr = refuses "onIso: only free apps" (good // { onIso = true; } // unfreeRedistributable);
      expected = true;
    };
    testInstallerDefaultNeedsOnIso = {
      expr = refuses "installerDefault: the app must also be onIso" (
        good // { installerDefault = true; }
      );
      expected = true;
    };
    testOnIsoInstallerDefaultPasses = {
      expr = problems "example" (
        good
        // {
          onIso = true;
          installerDefault = true;
        }
      );
      expected = [ ];
    };
    testOnIsoImpliesInstaller = {
      expr = map (e: (catalogLib.normalize "x" e).installer) [
        good
        (good // { onIso = true; })
        (good // { installer = true; })
      ];
      expected = [
        false
        true
        true
      ];
    };
    testRemovedFormatFields = {
      expr = map (f: refuses "unknown field(s): ${f}" (good // { ${f} = true; })) [
        "preinstalled"
        "featured"
        "ageRating"
      ];
      expected = [
        true
        true
        true
      ];
    };
    testOnIsoDependsOnIso = {
      expr = catalogLib.validate {
        a = good // {
          onIso = true;
          depends = [ "b" ];
        };
        b = good;
      };
      expected = {
        _catalog = [ "a: onIso but depends on b, which is not onIso" ];
      };
    };
    testCacheOnlyUnfree = {
      expr = refuses "cache: only for unfree apps" (good // { cache = true; });
      expected = true;
    };
    testCacheNeedsRedistributable = {
      expr = refuses "only unfreeRedistributable apps may be cached" (
        good
        // {
          cache = true;
          license = {
            free = false;
            redistributable = false;
            unfreePackages = [ "x" ];
          };
          inherit terms;
        }
      );
      expected = true;
    };
    testCachedUnfreePasses = {
      expr = problems "example" (
        good
        // {
          cache = true;
          inherit terms;
        }
        // unfreeRedistributable
      );
      expected = [ ];
    };
    testBuildsOnDevice = {
      expr = map (e: (catalogLib.normalize "example" e).buildsOnDevice) [
        good
        (good // { inherit terms; } // unfreeRedistributable)
        (
          good
          // {
            cache = true;
            inherit terms;
          }
          // unfreeRedistributable
        )
      ];
      expected = [
        false
        true
        false
      ];
    };
    testCacheableUnfree = {
      expr = catalogLib.cacheableUnfreeOf (
        lib.mapAttrs catalogLib.normalize {
          a = good;
          b =
            good
            // {
              cache = true;
              inherit terms;
            }
            // unfreeRedistributable;
          c =
            good
            // {
              inherit terms;
            }
            // unfreeRedistributable
            // {
              license = {
                free = false;
                redistributable = true;
                unfreePackages = [ "other" ];
              };
            };
        }
      );
      expected = [ "x" ];
    };
    testUnfreeNeedsTerms = {
      expr = refuses "terms: required for unfree apps" (good // unfreeRedistributable);
      expected = true;
    };
    testTermsFileName = {
      expr = refuses "the file must be named example-2.0.txt" (
        good
        // {
          terms = terms // {
            version = "2.0";
          };
        }
      );
      expected = true;
    };
    testTermsFields = {
      expr = map (t: refuses "terms." (good // { terms = terms // t; })) [
        { url = "http://x.org"; }
        { retrieved = "yesterday"; }
        { text = "/not/a/path.txt"; }
        { title = ""; }
      ];
      expected = [
        true
        true
        true
        true
      ];
    };
    testTermsPasses = {
      expr = problems "example" (good // { inherit terms; });
      expected = [ ];
    };
    testDataPathsPass = {
      expr = problems "example" (
        good
        // {
          dataPaths = [
            ".local/share/Steam"
            ".config/Plex HTPC"
          ];
        }
      );
      expected = [ ];
    };
    testDataPathsRefused = {
      expr = map (p: refuses "dataPaths:" (good // { dataPaths = [ p ]; })) [
        "/etc"
        "~/x"
        "../x"
        ".config/../../x"
        "."
        ""
        "a//b"
        "a/"
        ".config/*"
      ];
      expected = lib.genList (_: true) 9;
    };
    testKioskNeedsProfileDataPath = {
      expr = refuses "dataPaths: a kiosk (web) app must list its Firefox profile" (
        good
        // {
          icon = { };
          app = _: { kiosk.url = "https://example.org"; };
        }
      );
      expected = true;
    };
    testKioskWithProfilePasses = {
      expr = problems "example" (
        good
        // {
          icon = { };
          app = _: { kiosk.url = "https://example.org"; };
          dataPaths = [ ".local/share/hinteros/firefox/example" ];
        }
      );
      expected = [ ];
    };
    testKioskAboutHome = {
      expr = refuses "app.kiosk.url" (
        good
        // {
          icon = { };
          app = _: { kiosk.url = "about:config"; };
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
        format = 2;
        name = "Old app";
        status = "removed";
        statusReason = "Discontinued upstream.";
      };
      expected = [ ];
    };
    testTombstoneHasNoModule = {
      expr = refuses "a removed entry has no app or nixos" {
        format = 2;
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
    testIconUrlHttpsPasses = {
      expr = problems "example" (
        good
        // {
          icon = {
            desktopId = "org.example.Example";
            iconUrl = "https://example.org/logo.png";
          };
        }
      );
      expected = [ ];
    };
    testIconUrlRejectsOtherSchemes = {
      expr =
        map
          (
            u:
            refuses "icon.iconUrl" (
              good
              // {
                icon = {
                  desktopId = "x";
                  iconUrl = u;
                };
              }
            )
          )
          [
            "http://example.org/logo.png"
            "file:///etc/passwd"
            "data:image/png;base64,AAAA"
            "//example.org/logo.png"
            "https://example.org/a b.png"
            ""
            "https://example.org/${lib.concatStrings (lib.genList (_: "a") 500)}"
          ];
      expected = lib.genList (_: true) 7;
    };
    testIconUrlMustBeString = {
      expr = refuses "icon.iconUrl" (
        good
        // {
          icon = {
            desktopId = "x";
            iconUrl = 5;
          };
        }
      );
      expected = true;
    };
    testIconUrlInIndex = {
      expr =
        (builtins.head
          (catalogLib.mkIndex {
            x = catalogLib.normalize "x" (
              good
              // {
                icon = {
                  desktopId = "x";
                  iconUrl = "https://example.org/l.png";
                };
              }
            );
          }).apps
        ).icon.iconUrl;
      expected = "https://example.org/l.png";
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
