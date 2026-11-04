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
      unfree = false;
    };
    sizeMiB = 10;
    icon.desktopId = "org.example.Example";
    # Keyboard input: no gamepad permission needed (the default input is gamepad).
    app = { pkgs, ... }: {
      package = pkgs.hello;
      input = "keyboard";
    };
  };

  terms = {
    title = "Example Terms";
    version = "1.0";
    url = "https://example.org/terms";
    retrieved = "2026-10-06";
    text = ./fixtures/example-1.0.txt;
  };
  readme = {
    url = "https://github.com/example/example/blob/0123456789abcdef0123456789abcdef01234567/README.md";
    retrieved = "2026-10-25";
    text = ./fixtures/example.md;
  };
  unfreeRedistributable = {
    license = {
      unfree = true;
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
      unfree = false;
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
            unfree = true;
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
            unfree = false;
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
    testDeliveryOnlyUnfree = {
      expr = map (d: refuses "delivery: only for unfree entries" (good // { delivery = d; })) [
        "download"
        "build"
      ];
      expected = [
        true
        true
      ];
    };
    testBadDelivery = {
      expr = refuses "delivery: must be null or one of" (
        good // { delivery = "cache"; } // unfreeRedistributableWithTerms
      );
      expected = true;
    };
    testOldLicenceAndCacheFieldsRefused = {
      expr = [
        (refuses "license: unknown field(s) free, redistributable" (
          good
          // {
            license = {
              free = true;
              redistributable = true;
              unfree = false;
            };
          }
        ))
        (refuses "unknown field(s): cache" (good // { cache = false; }))
      ];
      expected = [
        true
        true
      ];
    };
    testDownloadedUnfreePasses = {
      expr = problems "example" (
        good
        // {
          delivery = "download";
        }
        // unfreeRedistributableWithTerms
      );
      expected = [ ];
    };
    testDeliveryDefault = {
      expr = map (e: (catalogLib.normalize "example" e).delivery) [
        good
        (good // unfreeRedistributableWithTerms)
        (good // { delivery = "build"; } // unfreeRedistributableWithTerms)
        (good // { delivery = "download"; } // unfreeRedistributableWithTerms)
      ];
      expected = [
        "download"
        "build"
        "build"
        "download"
      ];
    };
    testCacheableUnfree = {
      expr = catalogLib.cacheableUnfreeOf (
        lib.mapAttrs catalogLib.normalize {
          a = good;
          b = good // { delivery = "download"; } // unfreeRedistributableWithTerms;
          c =
            good
            // unfreeRedistributableWithTerms
            // {
              license = {
                unfree = true;
                unfreePackages = [ "other" ];
              };
            };
          d = {
            format = 3;
            name = "Gone";
            status = "removed";
            statusReason = "Gone.";
            delivery = "download";
            license = {
              unfree = true;
              unfreePackages = [ "gone" ];
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
    testSiteUrlNullNative = {
      expr = {
        problems = problems "example" (
          good
          // {
            icon = good.icon // {
              siteUrl = null;
            };
          }
        );
        index =
          (lib.head
            (catalogLib.mkIndex {
              example = catalogLib.normalize "example" (
                good
                // {
                  icon = good.icon // {
                    siteUrl = null;
                  };
                }
              );
            }).entries
          ).icon;
      };
      expected = {
        problems = [ ];
        index = {
          desktopId = "org.example.Example";
        };
      };
    };
    testReadmePasses = {
      expr = problems "example" (good // { inherit readme; });
      expected = [ ];
    };
    testReadmeFields = {
      expr = map (r: refuses "readme." (good // { readme = readme // r; })) [
        { url = "http://x.org"; }
        { retrieved = "today"; }
        { text = "/not/a/path.md"; }
        { text = ./fixtures/example-1.0.txt; }
      ];
      expected = [
        true
        true
        true
        true
      ];
    };
    testReadmeUnknownField = {
      expr = refuses "readme: unknown field(s) extra" (
        good
        // {
          readme = readme // {
            extra = 1;
          };
        }
      );
      expected = true;
    };
    testReadmeInIndex = {
      expr =
        (lib.head
          (catalogLib.mkIndex { example = catalogLib.normalize "example" (good // { inherit readme; }); })
          .entries
        ).readme;
      expected = {
        inherit (readme) url retrieved;
        file = "readme/example.md";
      };
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
        # The daemon refuses the whole index for these (is_data_path).
        ".config/Foo [beta]"
        ".config/a]b"
        ".config\\Foo"
        ".config/a\tb"
      ];
      expected = lib.genList (_: true) 13;
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
          app = _: {
            kiosk.url = "https://example.org";
            input = "keyboard";
          };
          dataPaths = [ ".local/share/hinteros/firefox/example" ];
        }
      );
      expected = [ ];
    };
    testSiteUrlNullWebRefused = {
      expr = refuses "icon.siteUrl: null (no icon discovery) only for native apps" (
        good
        // {
          icon.siteUrl = null;
          app = _: {
            kiosk.url = "https://example.org";
            input = "keyboard";
          };
          dataPaths = [ ".local/share/hinteros/firefox/example" ];
        }
      );
      expected = true;
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
          boxFeatures = [
            "graphics32"
            "steam-devices"
          ];
          app = { box, ... }: {
            package = box.steam;
            input = "keyboard";
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
      expr = refuses "boxFeatures: must be a list of box features" (
        good // { boxFeatures = [ "graphics64" ]; }
      );
      expected = true;
    };
    testBoxFeaturesAccepted = {
      expr = map (f: problems "example" (good // { boxFeatures = [ f ]; })) catalogLib.features;
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
                  if f == "boxFeatures" then
                    [ ]
                  else if f == "starter" then
                    "offered"
                  else
                    true;
              }
            )
          )
          [
            "boxFeatures"
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
            systemd.services.example.serviceConfig.Nice = 5;
            systemd.services.example-worker.serviceConfig.Nice = 5;
          };
        }
      );
      expected = [ ];
    };
    testServiceNoNetworking = {
      expr =
        map
          (
            m: refuses "service: top-level key(s) not allowed: networking" (goodService // { service = _: m; })
          )
          [
            {
              networking.hostName = "x";
              services.example.enable = true;
            }
            {
              networking.firewall.allowedTCPPorts = [ 8096 ];
              services.example.enable = true;
            }
          ];
      expected = [
        true
        true
      ];
    };
    testServiceNoOpenFirewall = {
      expr =
        map
          (
            v:
            refuses "services.example.openFirewall not allowed" (
              goodService
              // {
                service = _: {
                  services.example = {
                    enable = true;
                    openFirewall = v;
                  };
                };
              }
            )
          )
          [
            true
            false
          ];
      expected = [
        true
        true
      ];
    };
    testServicePortsSetupStateDirs = {
      expr = problems "example" (
        goodService
        // {
          ports = [
            {
              port = 8096;
              proto = "tcp";
              from = "lan";
            }
            {
              port = 8096;
              proto = "udp";
              from = "any";
            }
          ];
          setup = "jellyfin-server";
          stateDirs = [
            "example"
            "hinteros/services/example"
          ];
        }
      );
      expected = [ ];
    };
    testBadPorts = {
      expr = map (p: refuses "ports: must be a list of" (goodService // { ports = [ p ]; })) [
        {
          port = 0;
          proto = "tcp";
          from = "lan";
        }
        {
          port = 65536;
          proto = "tcp";
          from = "lan";
        }
        {
          port = 80;
          proto = "sctp";
          from = "lan";
        }
        {
          port = 80;
          proto = "tcp";
          from = "wan";
        }
        {
          port = "80";
          proto = "tcp";
          from = "lan";
        }
        {
          port = 80;
          proto = "tcp";
        }
        {
          port = 80;
          proto = "tcp";
          from = "lan";
          range = 2;
        }
      ];
      expected = lib.genList (_: true) 7;
    };
    testDuplicatePorts = {
      expr = refuses "ports: each port and proto at most once" (
        goodService
        // {
          ports = lib.genList (_: {
            port = 80;
            proto = "tcp";
            from = "lan";
          }) 2;
        }
      );
      expected = true;
    };
    testBadSetup = {
      expr = refuses "setup: must be null or one of" (goodService // { setup = "samba"; });
      expected = true;
    };
    testBadStateDirs = {
      expr = map (d: refuses "stateDirs: must be a list of" (goodService // { stateDirs = [ d ]; })) [
        "/var/lib/x"
        "../etc"
        "a/../b"
        "a//b"
        "a b"
        "a/."
        ""
      ];
      expected = lib.genList (_: true) 7;
    };
    testServiceFieldsOnlyForServices = {
      expr = [
        (refuses "ports: only for services" (
          good
          // {
            ports = [ ];
          }
        ))
        (refuses "setup: only for services" (good // { setup = null; }))
        (refuses "stateDirs: only for services" (good // { stateDirs = [ ]; }))
      ];
      expected = [
        true
        true
        true
      ];
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
    testNeedsServicesInIndex = {
      expr =
        map (e: e.needsServices or null)
          (catalogLib.mkIndex (
            lib.mapAttrs catalogLib.normalize {
              a = good // {
                needsServices = [
                  "s2"
                  "s1"
                ];
              };
              c = good;
              s1 = goodService;
              s2 = goodService;
            }
          )).entries;
      expected = [
        [
          "s2"
          "s1"
        ]
        [ ]
        [ ]
        [ ]
      ];
    };
    testIndexVersion = {
      expr = (catalogLib.mkIndex { }).indexVersion;
      expected = 4;
    };
    testIndexCarriesFields = {
      expr =
        let
          e =
            builtins.head
              (catalogLib.mkIndex {
                x = catalogLib.normalize "x" (
                  good
                  // {
                    boxFeatures = [ "graphics32" ];
                    starter = "offered";
                  }
                );
              }).entries;
        in
        [
          e.kind
          (e ? type)
          e.boxFeatures
          e.starter
          e.onIso
          e.unfree
          e.delivery
          (e ? box)
          (e ? free)
          (e ? redistributable)
          (e ? cache)
          (e ? buildsOnDevice)
          (e ? requires)
          (e ? installer)
          (e ? installerDefault)
        ];
      expected = [
        "app"
        false
        [ "graphics32" ]
        "offered"
        false
        false
        "download"
        false
        false
        false
        false
        false
        false
        false
        false
      ];
    };
    testPermissionsPass = {
      expr = problems "example" (
        good
        // {
          permissions = {
            gamepad = "required";
            mic = "optional";
            downloads = "optional";
            lan = "optional";
          };
        }
      );
      expected = [ ];
    };
    testPermissionsRefused = {
      expr = map (v: refuses "permissions: must be" (good // { permissions = v; })) [
        { camera = "optional"; }
        { mic = "maybe"; }
        { mic = true; }
        [ "mic" ]
      ];
      expected = lib.genList (_: true) 4;
    };
    testSandboxMustBeBool = {
      expr = refuses "sandbox: must be a bool" (good // { sandbox = "no"; });
      expected = true;
    };
    testGamepadInputNeedsPermission = {
      expr = refuses "permissions.gamepad: required for input" (
        good
        // {
          app = { pkgs, ... }: {
            package = pkgs.hello;
            input = "gamepad";
          };
        }
      );
      expected = true;
    };
    # The session daemon refuses these, and then drops every app of the profile's env.
    testBackKeyNeedsKeyboard = {
      expr =
        map
          (
            a:
            refuses "backKey and kiosk.fullscreenOnly need input = \"keyboard\"" (
              good
              // {
                permissions.gamepad = "required";
                dataPaths = [ ".local/share/hinteros/firefox/example" ];
                app = _: a;
              }
            )
          )
          [
            {
              command = [ "x" ];
              backKey = "escape";
            }
            {
              command = [ "x" ];
              input = "gamepad";
              backKey = "escape";
            }
            {
              kiosk = {
                url = "https://example.org";
                fullscreenOnly = true;
              };
            }
          ];
      expected = [
        true
        true
        true
      ];
    };
    testBackKeyNames = {
      expr =
        map
          (
            k:
            problems "example" (
              good
              // {
                app = _: {
                  command = [ "x" ];
                  input = "keyboard";
                  backKey = k;
                };
              }
            )
          )
          [
            "escape"
            "Esc"
            "alt+left"
            "ctrl + shift + f5"
            "backspace"
          ];
      expected = lib.genList (_: [ ]) 5;
    };
    testBackKeyUnknownName = {
      expr =
        map
          (
            k:
            refuses "app.backKey: a key name" (
              good
              // {
                app = _: {
                  command = [ "x" ];
                  input = "keyboard";
                  backKey = k;
                };
              }
            )
          )
          [
            "escap"
            "hyper+a"
            "alt+"
            ""
            42
          ];
      expected = lib.genList (_: true) 5;
    };
    testAppValueTypes = {
      expr =
        map
          (
            a:
            lib.length (
              problems "example" (
                good
                // {
                  dataPaths = [ ".local/share/hinteros/firefox/example" ];
                  app = _: { input = "keyboard"; } // a;
                }
              )
            )
          )
          [
            {
              command = [ "x" ];
              order = "1";
            }
            { command = [ ]; }
            { command = "x"; }
            {
              kiosk = {
                url = "https://example.org";
                userAgent = "a\nb";
              };
            }
            {
              kiosk = {
                url = "https://example.org";
                fullscreenOnly = "yes";
              };
            }
          ];
      expected = lib.genList (_: 1) 5;
    };
    testNoInputNeedsPermission = {
      expr = refuses "permissions.gamepad: required for input" (
        good // { app = { pkgs, ... }: { package = pkgs.hello; }; }
      );
      expected = true;
    };
    testGamepadInputUnsandboxedPasses = {
      expr = problems "example" (
        good
        // {
          sandbox = false;
          app = { pkgs, ... }: {
            package = pkgs.hello;
            input = "gamepad";
          };
        }
      );
      expected = [ ];
    };
    testUnsandboxedHasNoPermissions = {
      expr = refuses "permissions: only for sandboxed apps" (
        good
        // {
          sandbox = false;
          permissions.mic = "optional";
        }
      );
      expected = true;
    };
    testServiceHasNoSandboxFields = {
      expr = [
        (refuses "permissions: only for apps" (goodService // { permissions.mic = "optional"; }))
        (refuses "sandbox: only for apps" (goodService // { sandbox = false; }))
      ];
      expected = [
        true
        true
      ];
    };
    testSandboxDataPath = {
      expr = {
        sandboxed = (catalogLib.normalize "x" (good // { dataPaths = [ ".config/x" ]; })).dataPaths;
        listedTwice =
          (catalogLib.normalize "x" (good // { dataPaths = [ ".local/share/hinteros/sandbox/x" ]; }))
          .dataPaths;
        unsandboxed = (catalogLib.normalize "x" (good // { sandbox = false; })).dataPaths;
        service = (catalogLib.normalize "s" goodService).dataPaths;
      };
      expected = {
        sandboxed = [
          ".config/x"
          ".local/share/hinteros/sandbox/x"
        ];
        listedTwice = [ ".local/share/hinteros/sandbox/x" ];
        unsandboxed = [ ];
        service = [ ];
      };
    };
    testIndexCarriesPermissions = {
      expr =
        map
          (e: {
            inherit (e) id permissions sandbox;
          })
          (catalogLib.mkIndex {
            a = catalogLib.normalize "a" (good // { permissions.gamepad = "required"; });
            b = catalogLib.normalize "b" (good // { sandbox = false; });
            s = catalogLib.normalize "s" goodService;
          }).entries;
      expected = [
        {
          id = "a";
          permissions.gamepad = "required";
          sandbox = true;
        }
        {
          id = "b";
          permissions = { };
          sandbox = false;
        }
        {
          id = "s";
          permissions = { };
          sandbox = false;
        }
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
    # The index of a tombstone keeps its data paths and the sandbox home, so profiles can still
    # delete the data after the update removes the app.
    testTombstoneKeepsDataPaths = {
      expr =
        let
          tomb = {
            format = 3;
            name = "Old app";
            status = "removed";
            statusReason = "Discontinued upstream.";
          };
        in
        {
          problems = problems "old" (tomb // { dataPaths = [ ".config/old" ]; });
          index = map (e: e.dataPaths) (catalogLib.mkIndex {
            old = catalogLib.normalize "old" (tomb // { dataPaths = [ ".config/old" ]; });
            unsandboxed = catalogLib.normalize "unsandboxed" (tomb // { sandbox = false; });
            svc = catalogLib.normalize "svc" (tomb // { kind = "service"; });
          }).entries;
          sandbox = (catalogLib.normalize "old" tomb).sandbox;
        };
      expected = {
        problems = [ ];
        index = [
          [
            ".config/old"
            ".local/share/hinteros/sandbox/old"
          ]
          [ ]
          [ ]
        ];
        sandbox = false;
      };
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
            sha256 = "abababababababababababababababababababababababababababababababab";
          };
        }
      );
      expected = [ ];
    };
    testIconUrlNeedsSha256 = {
      expr = refuses "icon.sha256: required with iconUrl" (
        good
        // {
          icon = {
            desktopId = "x";
            iconUrl = "https://example.org/logo.png";
          };
        }
      );
      expected = true;
    };
    testBadSha256 = {
      expr =
        map
          (
            h:
            refuses "icon.sha256: 64 lowercase hex digits" (
              good
              // {
                icon = {
                  desktopId = "x";
                  iconUrl = "https://example.org/logo.png";
                  sha256 = h;
                };
              }
            )
          )
          [
            "abc"
            (lib.toUpper "abababababababababababababababababababababababababababababababab")
            "sha256-AAAA"
            5
          ];
      expected = lib.genList (_: true) 4;
    };
    testSha256NeedsIconUrl = {
      expr = refuses "icon.sha256: only with iconUrl" (
        good
        // {
          icon = {
            desktopId = "x";
            sha256 = "abababababababababababababababababababababababababababababababab";
          };
        }
      );
      expected = true;
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
                  sha256 = "abababababababababababababababababababababababababababababababab";
                };
              }
            );
          }).entries
        ).icon;
      expected = {
        desktopId = "x";
        iconUrl = "https://example.org/l.png";
        sha256 = "abababababababababababababababababababababababababababababababab";
        siteUrl = "https://example.org";
      };
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
