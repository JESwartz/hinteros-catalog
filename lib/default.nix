# The catalog entry format (format 3) and its validator. Pure: needs only nixpkgs' `lib`, so the
# system repo and the index can read entry metadata without evaluating any package.
#
# An entry is `apps/<id>.nix`, a plain attrset (see README.md for every field). `kind = "app"`
# entries have `app`, a function of `{ pkgs, lib, box }`; `kind = "service"` entries have
# `service`, a restricted NixOS module. Both are only called by the system repo (and by this
# repo's package checks).
{ lib }:
let
  inherit (builtins)
    attrNames
    elem
    isAttrs
    isBool
    isFunction
    isInt
    isList
    isPath
    isString
    stringLength
    ;

  # Format 3 added `kind` (app/service), `box` (replacing `requires`), `service` (replacing
  # `nixos`, services only) and `starter` (replacing `installer`/`installerDefault`); no format
  # 1 or 2 entry exists any more.
  supportedFormats = [ 3 ];
  indexVersion = 3;

  entryKinds = [
    "app" # installed per profile
    "service" # box-wide NixOS module, admin only
  ];
  starters = [
    "offered" # listed in the installer's app step
    "ticked" # listed and pre-selected (needs onIso)
  ];
  categories = [
    "games"
    "video"
    "music"
    "photos"
    "utilities"
  ];
  statuses = [
    "available" # listed and installable
    "retired" # hidden from the Store; stays working where installed
    "removed" # tombstone: no module, installed copies go away on the next update
  ];
  # Box features an app can name in `box`; the system repo maps each to NixOS options
  # (box-features.nix). A new feature is a system-repo change.
  features = [
    "graphics32" # hardware.graphics.enable32Bit, services.pipewire.alsa.support32Bit
    "steam-devices" # hardware.steam-hardware.enable (controller udev rules)
  ];
  # Sandbox permissions an app can declare (`permissions = { <name> = <level>; }`). The session
  # daemon enforces each one in its bwrap sandbox; a permission that is not enforced is not listed.
  permissionNames = [
    "gamepad" # /dev/input (device ACLs limit it to controllers) and /run/udev
    "mic" # a pulse socket that may record
    "downloads" # the profile's ~/Downloads, read-write
    "lan" # the local network (home devices, this box's own services); without it only DNS and the internet
  ];
  permissionLevels = [
    "required" # always granted
    "optional" # granted unless the profile user switches it off
  ];
  # The sandboxed app's home, below the profile's home (bound at the real $HOME path inside).
  sandboxHome = id: ".local/share/hinteros/sandbox/${id}";
  # What `app` receives: `{ pkgs, lib, box }` and nothing else (no `config`).
  appArgs = [
    "pkgs"
    "lib"
    "box"
  ];
  # Members of `box`, the box's inputs to apps (built by the system repo).
  boxMembers = [
    "firefoxKiosk" # the kiosk wrapper and its Firefox
    "steam" # pkgs.steam with this box's graphics packages
  ];
  # Keys an entry's `app` may return: what the system repo's env builder reads. `name` and the
  # icon fields are set from metadata; `icon` (a packaged image) and unfree allowances are never
  # set by an entry.
  appKeys = [
    "package"
    "command"
    "kiosk"
    "input"
    "backKey"
    "order"
    "listed"
  ];
  # The one non-https kiosk URL: Firefox's own start page (the `firefox` app).
  kioskUrls = [ "about:home" ];
  kioskKeys = [
    "url"
    "userAgent"
    "fullscreenOnly"
  ];
  # What a service's module function receives (the usual module arguments it may need).
  serviceArgs = [
    "pkgs"
    "lib"
    "config"
    "options"
  ];
  # Top-level NixOS namespaces a service may set, narrowed below: `systemd` to
  # `services.<own unit>`. No `networking` (open ports come from `ports`, which the system repo
  # turns into firewall rules), `nixpkgs` (overlays or config would change how packages are
  # built), `imports`, `options`, `users`, `environment` (nothing is installed for profiles) or
  # `hinteros`.
  serviceKeys = [
    "services"
    "hardware"
    "systemd"
  ];
  # Setup flows the daemon and launcher show for a service (`setup`). A new one is a daemon and
  # launcher change.
  setupKinds = [
    "jellyfin" # first run done by the system, libraries, one user per profile
    "plex" # claim code from plex.tv/claim
    "tailscale" # sign in by QR
    "cloudflare" # Zero Trust tunnel token
  ];
  # Who may reach a service port (`ports.*.from`).
  portSources = [
    "lan" # the local networks (the system's list) and the tailscale0 interface
    "any" # every source (a service that does its own remote access, e.g. Plex)
  ];
  portProtos = [
    "tcp"
    "udp"
  ];

  idPattern = "[a-z0-9][a-z0-9-]{0,31}";
  isId = v: isString v && builtins.match idPattern v != null;
  isHttps = v: isString v && builtins.match "https://[^[:space:]]+" v != null;
  isText =
    max: v:
    isString v && v != "" && stringLength v <= max && builtins.match ".*[[:cntrl:]].*" v == null;
  # Like isText, but newlines are allowed (descriptions, notes).
  isLongText = max: v: isString v && v != "" && stringLength v <= max;
  # Relative path below a profile's home: no leading / or ~, no empty, . or .. components.
  isHomePath =
    v:
    isText 200 v
    && builtins.match "[/~].*|.*[*?$`].*" v == null
    && lib.all (c: c != "" && c != "." && c != "..") (lib.splitString "/" v);
  # Relative path below /var/lib (a service's state directory): the same rules as isHomePath,
  # and only letters, digits, `.`, `_`, `-` and `/`.
  isVarLibPath = v: isHomePath v && builtins.match "[A-Za-z0-9._/-]+" v != null;
  isPort =
    v:
    isAttrs v
    &&
      lib.sort lib.lessThan (attrNames v) == [
        "from"
        "port"
        "proto"
      ]
    && isInt v.port
    && v.port >= 1
    && v.port <= 65535
    && elem v.proto portProtos
    && elem v.from portSources;
  isNull = v: v == null;
  isFn = v: isFunction v || isAttrs v;
  listOf = p: v: isList v && lib.all p v;
  oneOf = xs: v: elem v xs;
  either =
    a: b: v:
    a v || b v;

  # field = { check; what; required ? false; default ? null; }
  fields = {
    format = {
      required = true;
      check = oneOf supportedFormats;
      what = "one of ${toString supportedFormats}";
    };
    kind = {
      default = "app";
      check = oneOf entryKinds;
      what = "one of ${lib.concatStringsSep ", " entryKinds}";
    };
    name = {
      required = true;
      check = isText 40;
      what = "a single-line string of at most 40 characters";
    };
    summary = {
      required = true;
      check = isText 80;
      what = "a single-line string of at most 80 characters";
    };
    description = {
      required = true;
      check = isLongText 1000;
      what = "a string of at most 1000 characters";
    };
    category = {
      required = true;
      check = oneOf categories;
      what = "one of ${lib.concatStringsSep ", " categories}";
    };
    homepage = {
      required = true;
      check = isHttps;
      what = "an https URL";
    };
    license = {
      required = true;
      check = isAttrs;
      what = "an attrset { free; redistributable; unfreePackages; }";
    };
    sizeMiB = {
      required = true;
      check = v: isInt v && v > 0 && v < 100000;
      what = "a positive integer (approximate download plus disk, MiB)";
    };
    icon = {
      required = true;
      check = isAttrs;
      what = "an attrset { desktopId?; siteUrl?; iconUrl?; sha256?; firefoxProfile?; }";
    };
    status = {
      default = "available";
      check = oneOf statuses;
      what = "one of ${lib.concatStringsSep ", " statuses}";
    };
    statusReason = {
      default = null;
      check = either isNull (isText 200);
      what = "null or a single-line string of at most 200 characters";
    };
    box = {
      default = [ ];
      check = listOf (oneOf features);
      what = "a list of box features: ${lib.concatStringsSep ", " features}";
    };
    depends = {
      default = [ ];
      check = listOf isId;
      what = "a list of entry ids";
    };
    needsServices = {
      default = [ ];
      check = listOf isId;
      what = "a list of service entry ids";
    };
    conflicts = {
      default = [ ];
      check = listOf isId;
      what = "a list of entry ids";
    };
    starter = {
      default = null;
      check = either isNull (oneOf starters);
      what = "null or one of ${lib.concatStringsSep ", " starters}";
    };
    onIso = {
      default = false;
      check = isBool;
      what = "a bool";
    };
    cache = {
      default = false;
      check = isBool;
      what = "a bool";
    };
    terms = {
      default = null;
      check = either isNull isAttrs;
      what = "null or an attrset { title; version; url; retrieved; text; }";
    };
    readme = {
      default = null;
      check = either isNull isAttrs;
      what = "null or an attrset { url; retrieved; text; }";
    };
    dataPaths = {
      default = [ ];
      check = listOf isHomePath;
      what = "a list of paths relative to a profile's home (no leading / or ~, no ., .. or empty components, no wildcards)";
    };
    notes = {
      default = null;
      check = either isNull (isLongText 4000);
      what = "null or a string (maintainer notes, not shown to users)";
    };
    app = {
      default = null;
      check = either isNull isFn;
      what = "null or a function { pkgs, lib, box }: { package?; command?; kiosk?; ... } (apps only)";
    };
    service = {
      default = null;
      check = either isNull isFn;
      what = "null or a restricted NixOS module: a function of pkgs, lib, config, options, or an attrset (services only)";
    };
    ports = {
      default = [ ];
      check = listOf isPort;
      what = "a list of { port (1-65535); proto (${lib.concatStringsSep "/" portProtos}); from (${lib.concatStringsSep "/" portSources}); } (services only)";
    };
    setup = {
      default = null;
      check = either isNull (oneOf setupKinds);
      what = "null or one of ${lib.concatStringsSep ", " setupKinds} (services only)";
    };
    stateDirs = {
      default = [ ];
      check = listOf isVarLibPath;
      what = "a list of paths relative to /var/lib (letters, digits, . _ - /; no ., .. or empty components) (services only)";
    };
    permissions = {
      default = { };
      check =
        v:
        isAttrs v
        && lib.all (n: elem n permissionNames) (attrNames v)
        && lib.all (oneOf permissionLevels) (lib.attrValues v);
      what = "an attrset of permissions (${lib.concatStringsSep ", " permissionNames}), each \"required\" or \"optional\"";
    };
    sandbox = {
      default = true;
      check = isBool;
      what = "a bool";
    };
    packages = {
      default = null;
      check = either isNull isFunction;
      what = "null or a function pkgs -> [ package ]";
    };
  };

  # Arguments used to inspect `app`/`service` results without evaluating packages: only the
  # attribute names (and kiosk settings) are looked at, never values that depend on pkgs.
  unavailable = what: throw "catalog: ${what} is not available while validating entry structure";
  stubArgs = {
    inherit lib;
    pkgs = unavailable "pkgs";
    box = lib.genAttrs boxMembers unavailable;
    config = unavailable "config";
    options = unavailable "options";
  };
  # Call `f` with only the arguments it names. An argument outside the allowed set still gets a
  # (throwing) value, so it is reported by the argument check instead of crashing evaluation.
  callStub =
    f:
    if isFunction f then
      let
        named = builtins.functionArgs f;
      in
      f (lib.mapAttrs (n: _: unavailable n) named // builtins.intersectAttrs named stubArgs)
    else
      f;
  # Stand-in for `box` when evaluating packages outside a box (licence checks, cache builds,
  # sizes): plain nixpkgs packages. The system repo builds the real ones.
  boxFor = pkgs: {
    inherit (pkgs) steam;
    firefoxKiosk = pkgs.firefox;
  };
  # Names a function takes that are not in `allowed`.
  badArgs =
    allowed: f:
    if isFunction f then lib.subtractLists allowed (attrNames (builtins.functionArgs f)) else [ ];

  # Problems with one entry on its own: a list of strings.
  checkEntry =
    id: e:
    let
      tombstone = (e.status or "available") == "removed";
      required =
        if tombstone then
          [
            "format"
            "name"
            "status"
            "statusReason"
          ]
        else
          lib.filter (n: fields.${n}.required or false) (attrNames fields);
      missing = lib.filter (n: !(e ? ${n}) || (tombstone && e.${n} == null)) required;
      unknown = lib.subtractLists (attrNames fields) (attrNames e);
      invalid = lib.filter (n: fields ? ${n} && !(fields.${n}.check e.${n})) (attrNames e);

      full = normalize id e;
      lic = full.license;
      isService = full.kind == "service";
      licProblems =
        let
          unknownKeys = lib.subtractLists [
            "free"
            "redistributable"
            "unfreePackages"
          ] (attrNames lic);
        in
        lib.optional (
          unknownKeys != [ ]
        ) "license: unknown field(s) ${lib.concatStringsSep ", " unknownKeys}"
        ++ lib.optional (!isBool (lic.free or null)) "license.free: must be a bool"
        ++ lib.optional (!isBool (lic.redistributable or null)) "license.redistributable: must be a bool"
        ++ lib.optional (
          !(listOf (isText 64) (lic.unfreePackages or [ ]))
        ) "license.unfreePackages: must be a list of package names"
        ++ lib.optional (
          (lic.free or false) && (lic.unfreePackages or [ ]) != [ ]
        ) "license: a free app has no unfreePackages"
        ++ lib.optional (
          !(lic.free or true) && (lic.unfreePackages or [ ]) == [ ]
        ) "license: an unfree app must list its unfreePackages (names for the allowlist)"
        ++ lib.optional (
          (lic.free or false) && !(lic.redistributable or true)
        ) "license: free implies redistributable";

      tm = full.terms;
      termsProblems =
        if tm == null then
          lib.optional (!lic.free) "terms: required for unfree apps (the vendor's full terms text)"
        else
          let
            unknownKeys = lib.subtractLists [
              "title"
              "version"
              "url"
              "retrieved"
              "text"
            ] (attrNames tm);
            file = "${id}-${tm.version or ""}.txt";
          in
          lib.optional (unknownKeys != [ ]) "terms: unknown field(s) ${lib.concatStringsSep ", " unknownKeys}"
          ++ lib.optional (
            !isText 80 (tm.title or null)
          ) "terms.title: a single-line string of at most 80 characters"
          ++ lib.optional (
            !(isString (tm.version or null) && builtins.match "[A-Za-z0-9._-]{1,32}" tm.version != null)
          ) "terms.version: letters, digits, . _ - (at most 32), the vendor's version or revision date"
          ++ lib.optional (!isHttps (tm.url or null)) "terms.url: an https URL"
          ++ lib.optional (
            !(
              isString (tm.retrieved or null) && builtins.match "[0-9]{4}-[0-9]{2}-[0-9]{2}" tm.retrieved != null
            )
          ) "terms.retrieved: the retrieval date, YYYY-MM-DD"
          ++ (
            if !isPath (tm.text or null) then
              [ "terms.text: a path to the plain-text terms, ./terms/<id>-<version>.txt" ]
            else
              lib.optional (
                baseNameOf tm.text != file
              ) "terms.text: the file must be named ${file} (<id>-<version>.txt)"
              ++ lib.optional (!builtins.pathExists tm.text) "terms.text: file does not exist"
          );

      rm = full.readme;
      readmeProblems = lib.optionals (rm != null) (
        let
          unknownKeys = lib.subtractLists [
            "url"
            "retrieved"
            "text"
          ] (attrNames rm);
        in
        lib.optional (
          unknownKeys != [ ]
        ) "readme: unknown field(s) ${lib.concatStringsSep ", " unknownKeys}"
        ++ lib.optional (
          !isHttps (rm.url or null)
        ) "readme.url: an https URL (where the text was copied from)"
        ++ lib.optional (
          !(
            isString (rm.retrieved or null) && builtins.match "[0-9]{4}-[0-9]{2}-[0-9]{2}" rm.retrieved != null
          )
        ) "readme.retrieved: the retrieval date, YYYY-MM-DD"
        ++ (
          if !isPath (rm.text or null) then
            [ "readme.text: a path to the Markdown file, ./readme/<id>.md" ]
          else
            lib.optional (baseNameOf rm.text != "${id}.md") "readme.text: the file must be named ${id}.md"
            ++ lib.optional (!builtins.pathExists rm.text) "readme.text: file does not exist"
        )
      );

      ic = full.icon;
      iconProblems =
        let
          unknownKeys = lib.subtractLists [
            "desktopId"
            "siteUrl"
            "iconUrl"
            "sha256"
            "firefoxProfile"
          ] (attrNames ic);
        in
        lib.optional (unknownKeys != [ ]) "icon: unknown field(s) ${lib.concatStringsSep ", " unknownKeys}"
        ++ lib.optional (
          ic ? desktopId && builtins.match "[A-Za-z0-9._-]+" ic.desktopId == null
        ) "icon.desktopId: a .desktop file name without the extension"
        ++ lib.optional (ic ? siteUrl && !isHttps ic.siteUrl) "icon.siteUrl: an https URL"
        ++ lib.optional (
          (e.icon or { }) ? siteUrl && e.icon.siteUrl == null && full.type != "native"
        ) "icon.siteUrl: null (no icon discovery) only for native apps"
        ++ lib.optional (
          ic ? iconUrl && !(isHttps ic.iconUrl && stringLength ic.iconUrl <= 500)
        ) "icon.iconUrl: an https URL of the vendor's own public logo (at most 500 characters)"
        ++ lib.optional (
          ic ? iconUrl && !(ic ? sha256)
        ) "icon.sha256: required with iconUrl (the file's SHA-256, 64 lowercase hex digits)"
        ++ lib.optional (
          ic ? sha256 && !(isString ic.sha256 && builtins.match "[0-9a-f]{64}" ic.sha256 != null)
        ) "icon.sha256: 64 lowercase hex digits (the SHA-256 of the iconUrl file)"
        ++ lib.optional (ic ? sha256 && !(ic ? iconUrl)) "icon.sha256: only with iconUrl"
        ++ lib.optional (ic ? firefoxProfile && !isBool ic.firefoxProfile) "icon.firefoxProfile: a bool"
        ++ lib.optional (
          (ic.firefoxProfile or false) && full.type != "web"
        ) "icon.firefoxProfile: only for kiosk (web) apps"
        ++ lib.optional (
          full.type == "native" && !(ic ? desktopId)
        ) "icon.desktopId: required for native apps (the icon of the installed app)";

      appBadArgs = badArgs appArgs full.app;
      appAttrs = callStub full.app;
      appProblems =
        if full.app == null then
          [ ]
        else if appBadArgs != [ ] then
          [ "app: a function of { pkgs, lib, box } only (not ${lib.concatStringsSep ", " appBadArgs})" ]
        else if !isAttrs appAttrs then
          [ "app: must return an attrset" ]
        else
          let
            unknownKeys = lib.subtractLists appKeys (attrNames appAttrs);
            kiosk = appAttrs.kiosk or { };
            unknownKiosk = lib.subtractLists kioskKeys (attrNames kiosk);
          in
          lib.optional (unknownKeys != [ ])
            "app: field(s) not allowed: ${lib.concatStringsSep ", " unknownKeys} (allowed: ${lib.concatStringsSep ", " appKeys})"
          ++ lib.optional (
            unknownKiosk != [ ]
          ) "app.kiosk: unknown field(s) ${lib.concatStringsSep ", " unknownKiosk}"
          ++ lib.optional (
            appAttrs ? kiosk && !(isHttps (kiosk.url or null) || elem (kiosk.url or null) kioskUrls)
          ) "app.kiosk.url: an https URL (or ${lib.concatStringsSep ", " kioskUrls})"
          ++ lib.optional (
            !(appAttrs ? kiosk) && !(appAttrs ? package) && !(appAttrs ? command)
          ) "app: needs package, command or kiosk"
          ++ lib.optional (
            appAttrs ? input
            && !elem appAttrs.input [
              "gamepad"
              "keyboard"
            ]
          ) "app.input: gamepad or keyboard"
          ++ lib.optional (appAttrs ? listed && !isBool appAttrs.listed) "app.listed: a bool"
          ++
            lib.optional
              (
                # No input: the daemon's default, gamepad.
                (appAttrs.input or "gamepad") == "gamepad" && full.sandbox && !(full.permissions ? gamepad)
              )
              "permissions.gamepad: required for input = \"gamepad\" or no input (the sandbox hides /dev/input)";

      serviceBadArgs = badArgs serviceArgs full.service;
      serviceAttrs = callStub full.service;
      serviceProblems =
        if full.service == null then
          [ ]
        else if serviceBadArgs != [ ] then
          [
            "service: a module function of ${lib.concatStringsSep ", " serviceArgs} only (not ${lib.concatStringsSep ", " serviceBadArgs})"
          ]
        else if !isAttrs serviceAttrs then
          [ "service: must return an attrset" ]
        else
          let
            bad = lib.subtractLists serviceKeys (attrNames serviceAttrs);
            systemd = serviceAttrs.systemd or { };
            badSystemd = lib.subtractLists [ "services" ] (attrNames systemd);
            # `systemd.services.<own unit>`: a unit named after one of the module's own
            # `services.<name>` (jellyfin, tailscale -> tailscaled).
            owners = attrNames (serviceAttrs.services or { });
            badUnits = lib.filter (u: !lib.any (o: lib.hasPrefix o u) owners) (
              attrNames (systemd.services or { })
            );
            # Open ports come from `ports` only: no module's own openFirewall, whatever its value.
            openFw = lib.filter (
              o: isAttrs serviceAttrs.services.${o} && serviceAttrs.services.${o} ? openFirewall
            ) owners;
          in
          lib.optional (bad != [ ])
            "service: top-level key(s) not allowed: ${lib.concatStringsSep ", " bad} (allowed: services, hardware, systemd.services.<own unit>; open ports with `ports`)"
          ++
            lib.optional (openFw != [ ])
              "service: services.${lib.concatStringsSep ", services." openFw}.openFirewall not allowed (open ports with `ports`)"
          ++
            lib.optional (badSystemd != [ ])
              "service: systemd.${lib.concatStringsSep ", systemd." badSystemd} not allowed (only systemd.services.<own unit>)"
          ++
            lib.optional (badUnits != [ ])
              "service: systemd.services.${lib.concatStringsSep ", systemd.services." badUnits} is not the module's own unit (named after one of its services.<name>)";

      kindProblems =
        if isService then
          lib.optional (full.service == null) "service: required for kind = \"service\""
          ++ lib.optional (full.app != null) "app: only for kind = \"app\" (a service has `service`)"
          ++ lib.optional (e ? box) "box: only for apps (a service is box-wide already)"
          ++ lib.optional (e ? starter) "starter: only for apps"
          ++ lib.optional (e ? onIso) "onIso: only for apps"
          ++ lib.optional (e ? needsServices) "needsServices: only for apps (a service cannot need a service)"
          ++ lib.optional (e ? permissions) "permissions: only for apps"
          ++ lib.optional (e ? sandbox) "sandbox: only for apps"
          ++ lib.optional (
            fields.ports.check full.ports
            &&
              lib.length (lib.unique (map (p: "${toString p.port}/${p.proto}") full.ports))
              != lib.length full.ports
          ) "ports: each port and proto at most once"
        else
          lib.optional (full.app == null) "app: required for kind = \"app\" (or status = \"removed\")"
          ++ lib.optional (e ? ports) "ports: only for services"
          ++ lib.optional (e ? setup) "setup: only for services"
          ++ lib.optional (e ? stateDirs) "stateDirs: only for services (apps list dataPaths)"
          ++ lib.optional (
            !full.sandbox && full.permissions != { }
          ) "permissions: only for sandboxed apps (sandbox = false has every permission)"
          ++ lib.optional (
            full.service != null
          ) "service: only for kind = \"service\" (an app has `app` and `box`)";

      crossField =
        lib.optional (
          full.status != "available" && full.statusReason == null
        ) "statusReason: required when status is ${full.status}"
        ++ lib.optional (elem id full.depends) "depends: an entry cannot depend on itself"
        ++ lib.optional (elem id full.conflicts) "conflicts: an entry cannot conflict with itself"
        ++ lib.optional (
          full.onIso && !lic.free
        ) "onIso: only free apps (the ISO never contains unfree software)"
        ++ lib.optional (
          full.starter == "ticked" && !full.onIso
        ) "starter: \"ticked\" needs onIso, so an offline install can pick it"
        ++ lib.optional (
          (full.starter != null || full.onIso) && full.status != "available"
        ) "starter/onIso: only available apps"
        ++ lib.optional (
          full.cache && lic.free
        ) "cache: only for unfree entries (free ones are always in the binary cache)"
        ++ lib.optional (
          full.cache && !lic.redistributable
        ) "cache: only unfreeRedistributable entries may be cached (license.redistributable = true)"
        ++ lib.optional (
          full.type == "web" && !elem ".local/share/hinteros/firefox/${id}" full.dataPaths
        ) "dataPaths: a kiosk (web) app must list its Firefox profile, .local/share/hinteros/firefox/${id}";
    in
    lib.optional (!isId id) "id: must match ${idPattern} (the file name without .nix)"
    ++ map (n: "missing field: ${n}") missing
    ++ lib.optional (unknown != [ ]) "unknown field(s): ${lib.concatStringsSep ", " unknown}"
    ++ map (n: "${n}: must be ${fields.${n}.what}") invalid
    ++ lib.optionals (missing == [ ] && invalid == [ ] && !tombstone) (
      licProblems
      ++ termsProblems
      ++ readmeProblems
      ++ iconProblems
      ++ kindProblems
      ++ appProblems
      ++ serviceProblems
      ++ crossField
    )
    ++ lib.optional (
      tombstone && (e.app or null != null || e.service or null != null)
    ) "a removed entry has no app or service";

  # Problems between entries.
  checkCatalog =
    entries:
    lib.concatLists (
      lib.mapAttrsToList (
        id: e:
        map (d: "${id}: depends on unknown entry ${d}") (lib.filter (d: !(entries ? ${d})) e.depends)
        ++ map (d: "${id}: depends on ${d}, which is ${entries.${d}.status}") (
          lib.filter (d: entries ? ${d} && entries.${d}.status == "removed") e.depends
        )
        ++ map (c: "${id}: conflicts with unknown entry ${c}") (
          lib.filter (c: !(entries ? ${c})) e.conflicts
        )
        ++ map (d: "${id}: depends on ${d} but also conflicts with it") (
          lib.intersectLists e.depends e.conflicts
        )
        ++ map (d: "${id}: a ${e.kind} cannot depend on ${d}, which is a ${entries.${d}.kind}") (
          lib.filter (d: entries ? ${d} && entries.${d}.kind != e.kind) e.depends
        )
        ++ map (d: "${id}: needsServices: unknown entry ${d}") (
          lib.filter (d: !(entries ? ${d})) e.needsServices
        )
        ++ map (d: "${id}: needsServices: ${d} is a ${entries.${d}.kind}, not a service") (
          lib.filter (d: entries ? ${d} && entries.${d}.kind != "service") e.needsServices
        )
        ++ map (d: "${id}: needsServices: ${d} is removed") (
          lib.filter (d: entries ? ${d} && entries.${d}.status == "removed") e.needsServices
        )
        ++ map (d: "${id}: onIso but depends on ${d}, which is not onIso") (
          lib.filter (d: e.onIso && entries ? ${d} && !entries.${d}.onIso) e.depends
        )
      ) entries
    );

  # Fill defaults and derived fields. Only call on entries without problems (or for checks).
  normalize =
    id: e:
    let
      withDefaults =
        lib.mapAttrs (_: f: f.default) (lib.filterAttrs (_: f: !(f.required or false)) fields)
        // {
          license = {
            free = true;
            redistributable = true;
            unfreePackages = [ ];
          };
          icon = { };
        }
        // e;
      appAttrs = callStub withDefaults.app;
      sandbox = withDefaults.kind == "app" && withDefaults.status != "removed" && withDefaults.sandbox;
      lic = {
        unfreePackages = [ ];
      }
      // withDefaults.license;
    in
    withDefaults
    // {
      inherit id sandbox;
      license = lic;
      # A sandboxed app's whole home is app data: "delete data" removes it too.
      dataPaths = lib.unique (withDefaults.dataPaths ++ lib.optional sandbox (sandboxHome id));
      # `kind` is the entry kind; `type` what the entry is: web/native apps, or a service.
      type =
        if withDefaults.kind == "service" then
          "service"
        else if isAttrs appAttrs && appAttrs ? kiosk then
          "web"
        else
          "native";
      # The ISO and the binary cache never contain unfree software, except entries that opt in with
      # `cache` (checked to be unfreeRedistributable): everything else unfree is built on the box.
      buildsOnDevice = !(lic.free or true) && !withDefaults.cache;
      # `siteUrl = null`: no discovery (a native app whose site gives no icon of its own).
      icon = lib.filterAttrs (_: v: v != null) (
        lib.optionalAttrs (withDefaults.status != "removed") { siteUrl = withDefaults.homepage; }
        // withDefaults.icon
      );
      packages =
        if withDefaults.packages != null then
          withDefaults.packages
        else
          pkgs:
          let
            a =
              if isFunction withDefaults.app then
                withDefaults.app (
                  builtins.intersectAttrs (builtins.functionArgs withDefaults.app) {
                    inherit lib pkgs;
                    box = boxFor pkgs;
                  }
                )
              else
                withDefaults.app;
          in
          lib.optional (a != null && a ? package) a.package;
    };

  # Read every apps/<id>.nix in `dir`: { id = raw entry; }.
  readDir =
    dir:
    lib.mapAttrs'
      (file: _: lib.nameValuePair (lib.removeSuffix ".nix" file) (import (dir + "/${file}")))
      (
        lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".nix" file) (builtins.readDir dir)
      );

  # { id = [ problem ]; } for entries with problems, plus "_catalog" for cross-entry problems.
  validate =
    raw:
    let
      perEntry = lib.filterAttrs (_: ps: ps != [ ]) (lib.mapAttrs checkEntry raw);
      cross = if perEntry == { } then checkCatalog (lib.mapAttrs normalize raw) else [ ];
    in
    perEntry // lib.optionalAttrs (cross != [ ]) { _catalog = cross; };

  formatProblems =
    problems:
    lib.concatStringsSep "\n" (
      lib.concatLists (lib.mapAttrsToList (id: ps: map (p: "  ${id}: ${p}") ps) problems)
    );

  # The validated, normalized catalog. Throws with every problem if any entry is invalid, so
  # consumers never see a broken catalog.
  load =
    dir:
    let
      raw = readDir dir;
      problems = validate raw;
    in
    if problems == { } then
      lib.mapAttrs normalize raw
    else
      throw "hinteros-catalog: invalid entries:\n${formatProblems problems}";

  # Descriptions are written wrapped in Nix files; the index carries paragraphs separated by
  # a blank line ("\n\n") and no other line breaks, so the UI can wrap text itself.
  reflow =
    s:
    lib.concatStringsSep "\n\n" (
      lib.filter (p: p != "") (
        map (p: lib.trim (lib.concatStringsSep " " (map lib.trim (lib.splitString "\n" p)))) (
          lib.splitString "\n\n" s
        )
      )
    );

  # Public, machine-readable view for the launcher's Store UI (schema/index.schema.json).
  # Maintainer notes and the Nix functions stay out.
  indexEntry =
    e:
    if e.status == "removed" then
      {
        inherit (e)
          id
          kind
          name
          status
          statusReason
          ;
      }
    else
      {
        inherit (e)
          id
          kind
          type
          name
          summary
          category
          homepage
          sizeMiB
          icon
          box
          starter
          onIso
          depends
          needsServices
          conflicts
          dataPaths
          status
          statusReason
          buildsOnDevice
          cache
          permissions
          sandbox
          ports
          setup
          stateDirs
          ;
        inherit (e.license) free redistributable;
        description = reflow e.description;
        # `file` is relative to catalog.json (the index package installs it next to it).
        terms =
          if e.terms == null then
            null
          else
            {
              inherit (e.terms)
                title
                version
                url
                retrieved
                ;
              file = "terms/${baseNameOf e.terms.text}";
            };
        readme =
          if e.readme == null then
            null
          else
            {
              inherit (e.readme) url retrieved;
              file = "readme/${baseNameOf e.readme.text}";
            };
      };

  # Unfree package names the system repo's `forbidUnfree` / cache job may allow: the union of
  # unfreePackages of every available entry with `cache = true`.
  cacheableUnfreeOf =
    catalog:
    lib.unique (
      lib.sort lib.lessThan (
        lib.concatMap (e: e.license.unfreePackages) (
          lib.filter (e: e.cache && e.status != "removed") (lib.attrValues catalog)
        )
      )
    );

  # Views of a loaded catalog for the system repo.
  appsOnlyOf = lib.filterAttrs (_: e: e.kind == "app");
  servicesOf = lib.filterAttrs (_: e: e.kind == "service");

  # The union of box features the given app ids need, sorted. Unknown ids throw: callers
  # validate ids first, and a silent [] would drop a feature.
  featuresOfIn =
    catalog: ids:
    lib.sort lib.lessThan (
      lib.unique (
        lib.concatMap (id: (catalog.${id} or (throw "hinteros-catalog: unknown entry ${id}")).box) ids
      )
    );

  # The service ids the given app ids need, sorted and unique. The Store disables Install (red
  # "needs the X server, the admin profile can install it in Server") while one is not installed,
  # and the privileged service refuses the install. Unknown ids throw, as in featuresOfIn.
  servicesNeededBy =
    catalog: ids:
    lib.sort lib.lessThan (
      lib.unique (
        lib.concatMap (
          id: (catalog.${id} or (throw "hinteros-catalog: unknown entry ${id}")).needsServices
        ) ids
      )
    );

  # The installer's app step: ids of available apps with `starter` set, sorted. `offered` lists
  # everything the installer shows (ticked ones included), `ticked` the pre-selected subset,
  # `onIso` the ones that ship on the ISO (usable offline).
  starterDefaultsOf =
    catalog:
    let
      apps = lib.filter (e: e.kind == "app" && e.status == "available") (lib.attrValues catalog);
      idsWhere = p: lib.sort lib.lessThan (map (e: e.id) (lib.filter p apps));
    in
    {
      offered = idsWhere (e: e.starter != null);
      ticked = idsWhere (e: e.starter == "ticked");
      onIso = idsWhere (e: e.onIso);
    };

  # { "<id>" = { name, kind, status, statusReason }; }: cheap, package-free, evaluable for any
  # revision of the catalog (update.check, state.nix id checks).
  catalogIdsOf =
    catalog:
    lib.mapAttrs (_: e: {
      inherit (e)
        name
        kind
        status
        statusReason
        ;
    }) catalog;

  mkIndex = catalog: {
    inherit indexVersion;
    apps = map indexEntry (lib.sort (a: b: a.id < b.id) (lib.attrValues catalog));
  };
in
{
  inherit
    supportedFormats
    indexVersion
    entryKinds
    starters
    categories
    statuses
    features
    boxMembers
    permissionNames
    permissionLevels
    sandboxHome
    appKeys
    serviceKeys
    checkEntry
    validate
    formatProblems
    normalize
    readDir
    load
    mkIndex
    cacheableUnfreeOf
    appsOnlyOf
    servicesOf
    featuresOfIn
    servicesNeededBy
    starterDefaultsOf
    catalogIdsOf
    ;
}
