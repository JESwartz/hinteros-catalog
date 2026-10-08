# Unit tests for the entry validator (lib/default.nix): each broken entry must be refused with
# the expected message, and the example entries must pass. Eval only.
{ pkgs, catalogLib }:
let
  inherit (pkgs) lib;

  good = {
    format = 3;
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
  unfreeRedistributableWithTerms = unfreeRedistributable // {
    inherit terms;
  };

  goodService = {
    format = 3;
    kind = "service";
    name = "Example server";
    summary = "An example service.";
    description = "An example service used by the validator tests.";
    category = "utilities";
    homepage = "https://example.org";
    license = {
      free = true;
      redistributable = true;
    };
    sizeMiB = 10;
    icon = { };
    service = _: { services.example.enable = true; };
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
      expr = refuses "format: must be one of 3" (good // { format = 2; });
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
    testRemovedFormatFields = {
      expr = map (f: refuses "unknown field(s): ${f}" (good // { ${f} = true; })) [
        "preinstalled"
        "featured"
        "ageRating"
        "requires"
        "installer"
        "installerDefault"
        "nixos"
      ];
      expected = lib.genList (_: true) 7;
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
      expr = refuses "cache: only for unfree entries" (good // { cache = true; });
      expected = true;
    };
    testCacheNeedsRedistributable = {
      expr = refuses "only unfreeRedistributable entries may be cached" (
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
    testAppNeedsApp = {
      expr = refuses "app: required for kind = \"app\"" (builtins.removeAttrs good [ "app" ]);
      expected = true;
    };
    testAppCannotCarryService = {
      expr = refuses "service: only for kind = \"service\"" (
        good // { service = _: { services.foo.enable = true; }; }
      );
      expected = true;
    };
    testAppCannotCarryNixos = {
      expr = refuses "unknown field(s): nixos" (
        good // { nixos = _: { programs.steam.enable = true; }; }
      );
      expected = true;
    };
    testAppReadingConfigRefused = {
      expr = refuses "app: a function of { pkgs, lib, box } only (not config)" (
        good // { app = { pkgs, config, ... }: { package = builtins.seq config pkgs.hello; }; }
      );
      expected = true;
    };
    testAppWithBoxPasses = {
      expr = problems "example" (
        good
        // {
          box = [
            "graphics32"
            "steam-devices"
          ];
          app = { box, ... }: {
            package = box.steam;
            listed = false;
          };
        }
      );
      expected = [ ];
    };
    testAppListedIsBool = {
      expr = refuses "app.listed: a bool" (
        good
        // {
          app = { pkgs, ... }: {
            package = pkgs.hello;
            listed = 1;
          };
        }
      );
      expected = true;
    };
    testUnknownBoxFeature = {
      expr = refuses "box: must be a list of box features" (good // { box = [ "graphics64" ]; });
      expected = true;
    };
    testBoxFeaturesAccepted = {
      expr = map (f: problems "example" (good // { box = [ f ]; })) catalogLib.features;
      expected = [
        [ ]
        [ ]
      ];
    };
    testOldRequiresName = {
      expr = refuses "unknown field(s): requires" (good // { requires = [ "graphics32" ]; });
      expected = true;
    };
    testUnknownKind = {
      expr = refuses "kind: must be one of app, service" (good // { kind = "driver"; });
      expected = true;
    };
    testTickedNeedsOnIso = {
      expr = refuses "starter: \"ticked\" needs onIso" (good // { starter = "ticked"; });
      expected = true;
    };
    testStarterValues = {
      expr = map (s: refuses "starter: must be" (good // { starter = s; })) [
        "offered"
        "ticked"
        "default"
        true
      ];
      expected = [
        false
        false
        true
        true
      ];
    };
    testStarterOfferedPasses = {
      expr = problems "example" (good // { starter = "offered"; } // unfreeRedistributableWithTerms);
      expected = [ ];
    };
    testTickedOnIsoPasses = {
      expr = problems "example" (
        good
        // {
          onIso = true;
          starter = "ticked";
        }
      );
      expected = [ ];
    };
    testStarterOnlyAvailable = {
      expr = refuses "starter/onIso: only available apps" (
        good
        // {
          starter = "offered";
          status = "retired";
          statusReason = "Gone.";
        }
      );
      expected = true;
    };
    testTypeDerived = {
      expr = map (e: (catalogLib.normalize "x" e).type) [
        good
        (good // { app = _: { kiosk.url = "https://example.org"; }; })
        goodService
      ];
      expected = [
        "native"
        "web"
        "service"
      ];
    };
    testKindDefaultsToApp = {
      expr = (catalogLib.normalize "x" good).kind;
      expected = "app";
    };

    # Services.
    testGoodServicePasses = {
      expr = problems "example" goodService;
      expected = [ ];
    };
    testServiceNeedsService = {
      expr = refuses "service: required for kind = \"service\"" (
        builtins.removeAttrs goodService [ "service" ]
      );
      expected = true;
    };
    testServiceCannotCarryApp = {
      expr = refuses "app: only for kind = \"app\"" (goodService // { inherit (good) app; });
      expected = true;
    };
    testServiceCarriesNoAppFields = {
      expr =
        map
          (
            f:
            refuses "${f}: only for apps" (
              goodService
              // {
                ${f} =
                  if f == "box" then
                    [ ]
                  else if f == "starter" then
                    "offered"
                  else
                    true;
              }
            )
          )
          [
            "box"
            "starter"
            "onIso"
          ];
      expected = [
        true
        true
        true
      ];
    };
    testServiceNamespaces = {
      expr =
        map (m: refuses "service: top-level key(s) not allowed" (goodService // { service = _: m; }))
          [
            { nixpkgs.config.allowUnfree = true; }
            { imports = [ ]; }
            { options = { }; }
            { users.users.hinteros-p2.isNormalUser = true; }
            { environment.systemPackages = [ ]; }
            { hinteros.apps = [ ]; }
            { boot.kernelParams = [ ]; }
            { programs.steam.enable = true; }
          ];
      expected = lib.genList (_: true) 8;
    };
    testServiceAllowedNamespaces = {
      expr = problems "example" (
        goodService
        // {
          service = _: {
            services.example.enable = true;
            hardware.bluetooth.enable = true;
            networking.firewall.allowedTCPPorts = [ 8096 ];
            systemd.services.example.serviceConfig.Nice = 5;
            systemd.services.example-worker.serviceConfig.Nice = 5;
          };
        }
      );
      expected = [ ];
    };
    testServiceNetworkingOnlyFirewall = {
      expr = refuses "networking.hostName not allowed" (
        goodService
        // {
          service = _: {
            networking.hostName = "x";
            services.example.enable = true;
          };
        }
      );
      expected = true;
    };
    testServiceOwnUnitOnly = {
      expr = refuses "systemd.services.sshd is not the module's own unit" (
        goodService
        // {
          service = _: {
            services.example.enable = true;
            systemd.services.sshd.enable = false;
          };
        }
      );
      expected = true;
    };
    testServiceSystemdOnlyServices = {
      expr = refuses "systemd.timers not allowed" (
        goodService
        // {
          service = _: {
            services.example.enable = true;
            systemd.timers.x = { };
          };
        }
      );
      expected = true;
    };
    testServiceModuleArgs = {
      expr = [
        (refuses "service: a module function of" (
          goodService // { service = { host, ... }: { services.example.enable = host; }; }
        ))
        (problems "example" (
          goodService
          // {
            service =
              {
                config,
                pkgs,
                lib,
                options,
                ...
              }:
              {
                services.example.enable =
                  builtins.length [
                    config
                    pkgs
                    lib
                    options
                  ] > 0;
              };
          }
        ))
      ];
      expected = [
        true
        [ ]
      ];
    };
    testServiceAttrsetModule = {
      expr = problems "example" (
        goodService
        // {
          service = {
            services.example.enable = true;
          };
        }
      );
      expected = [ ];
    };
    testServiceDependsOnlyOnServices = {
      expr = catalogLib.validate {
        a = goodService // {
          depends = [ "b" ];
        };
        b = good;
      };
      expected = {
        _catalog = [ "a: a service cannot depend on b, which is a app" ];
      };
    };
    testTombstoneKind = {
      expr =
        (catalogLib.normalize "x" {
          format = 3;
          kind = "service";
          name = "Old";
          status = "removed";
          statusReason = "Gone.";
        }).kind;
      expected = "service";
    };

    # Library views.
    testViews =
      let
        cat = lib.mapAttrs catalogLib.normalize {
          a = good // {
            box = [ "steam-devices" ];
            starter = "offered";
          };
          b = good // {
            box = [
              "graphics32"
              "steam-devices"
            ];
            onIso = true;
            starter = "ticked";
          };
          c = good;
          s = goodService;
        };
      in
      {
        expr = {
          apps = lib.attrNames (catalogLib.appsOnlyOf cat);
          services = lib.attrNames (catalogLib.servicesOf cat);
          features = catalogLib.featuresOfIn cat [
            "a"
            "b"
            "c"
          ];
          none = catalogLib.featuresOfIn cat [ ];
          starter = catalogLib.starterDefaultsOf cat;
          ids = catalogLib.catalogIdsOf cat;
        };
        expected = {
          apps = [
            "a"
            "b"
            "c"
          ];
          services = [ "s" ];
          features = [
            "graphics32"
            "steam-devices"
          ];
          none = [ ];
          starter = {
            offered = [
              "a"
              "b"
            ];
            ticked = [ "b" ];
            onIso = [ "b" ];
          };
          ids = lib.genAttrs [ "a" "b" "c" "s" ] (id: {
            name = if id == "s" then "Example server" else "Example";
            kind = if id == "s" then "service" else "app";
            status = "available";
            statusReason = null;
          });
        };
      };
    # needsServices: apps may need services (not depends, which stays within a kind).
    testNeedsServicesValid = {
      expr = catalogLib.validate {
        a = good // {
          needsServices = [ "s" ];
        };
        s = goodService;
      };
      expected = { };
    };
    testNeedsServicesUnknown = {
      expr = catalogLib.validate {
        a = good // {
          needsServices = [ "missing" ];
        };
      };
      expected = {
        _catalog = [ "a: needsServices: unknown entry missing" ];
      };
    };
    testNeedsServicesPointsAtApp = {
      expr = catalogLib.validate {
        a = good // {
          needsServices = [ "b" ];
        };
        b = good;
      };
      expected = {
        _catalog = [ "a: needsServices: b is a app, not a service" ];
      };
    };
    testNeedsServicesOnService = {
      expr = problems "example" (goodService // { needsServices = [ "s" ]; });
      expected = [ "needsServices: only for apps (a service cannot need a service)" ];
    };
    testAppDependsOnServiceStillRefused = {
      expr = catalogLib.validate {
        a = good // {
          depends = [ "s" ];
        };
        s = goodService;
      };
      expected = {
        _catalog = [ "a: a app cannot depend on s, which is a service" ];
      };
    };
    testServicesNeededBy = {
      expr =
        let
          cat = lib.mapAttrs catalogLib.normalize {
            a = good // {
              needsServices = [
                "s2"
                "s1"
              ];
            };
            b = good // {
              needsServices = [ "s1" ];
            };
            c = good;
            s1 = goodService;
            s2 = goodService;
          };
        in
        {
          some = catalogLib.servicesNeededBy cat [
            "a"
            "b"
          ];
          none = catalogLib.servicesNeededBy cat [ "c" ];
          index = map (e: e.needsServices or null) (catalogLib.mkIndex cat).apps;
        };
      expected = {
        some = [
          "s1"
          "s2"
        ];
        none = [ ];
        index = [
          [
            "s2"
            "s1"
          ]
          [ "s1" ]
          [ ]
          [ ]
          [ ]
        ];
      };
    };
    testServicesNeededByUnknownThrows = {
      expr =
        (builtins.tryEval (builtins.deepSeq (catalogLib.servicesNeededBy { } [ "nope" ]) true)).success;
      expected = false;
    };
    testFeaturesOfUnknownThrows = {
      expr = (builtins.tryEval (builtins.deepSeq (catalogLib.featuresOfIn { } [ "nope" ]) true)).success;
      expected = false;
    };
    testIndexVersion = {
      expr = (catalogLib.mkIndex { }).indexVersion;
      expected = 3;
    };
    testIndexCarriesV3Fields = {
      expr =
        let
          e =
            builtins.head
              (catalogLib.mkIndex {
                x = catalogLib.normalize "x" (
                  good
                  // {
                    box = [ "graphics32" ];
                    starter = "offered";
                  }
                );
              }).apps;
        in
        [
          e.kind
          e.type
          e.box
          e.starter
          e.onIso
          (e ? requires)
          (e ? installer)
          (e ? installerDefault)
        ];
      expected = [
        "app"
        "native"
        [ "graphics32" ]
        "offered"
        false
        false
        false
        false
      ];
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
        format = 3;
        name = "Old app";
        status = "removed";
        statusReason = "Discontinued upstream.";
      };
      expected = [ ];
    };
    testTombstoneHasNoModule = {
      expr = refuses "a removed entry has no app or service" {
        format = 3;
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
        _catalog = [ "a: depends on unknown entry missing" ];
      };
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
