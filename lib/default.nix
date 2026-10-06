# The catalog entry format (format 2) and its validator. Pure: needs only nixpkgs' `lib`, so the
# system repo and the index can read entry metadata without evaluating any package.
#
# An entry is `apps/<id>.nix`, a plain attrset (see README.md for every field). `app` and
# `nixos` are functions of the NixOS module arguments and are only called by the system repo
# (and by this repo's package checks).
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

  # Format 2 replaced `featured`/`preinstalled` by `installer`/`onIso`/`installerDefault`, dropped
  # `ageRating` and added `cache`, `terms` and `dataPaths`; no format 1 entry exists any more.
  supportedFormats = [ 2 ];
  indexVersion = 2;

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
  # System features an entry can ask for; the system repo maps each to NixOS options.
  features = [
    "graphics32" # 32-bit graphics drivers (hardware.graphics.enable32Bit)
  ];
  # Keys an entry's `app` may return: a subset of the system repo's hinteros.apps.<id>
  # options. `enable`, `name` and the icon fields are set by the system repo from metadata;
  # `icon` (a packaged image) and `unfreeName` are never set by an entry.
  appKeys = [
    "package"
    "command"
    "kiosk"
    "input"
    "backKey"
    "order"
  ];
  # The one non-https kiosk URL: Firefox's own start page (the `firefox` app).
  kioskUrls = [ "about:home" ];
  kioskKeys = [
    "url"
    "userAgent"
    "fullscreenOnly"
  ];
  # Top-level NixOS option namespaces an entry's `nixos` may set. No `nixpkgs` (overlays or
  # config would change how packages are built), no `imports`/`options`, no `hinteros`.
  nixosKeys = [
    "programs"
    "hardware"
    "services"
    "environment"
    "xdg"
    "fonts"
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
      what = "an attrset { desktopId?; siteUrl?; firefoxProfile?; }";
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
    requires = {
      default = [ ];
      check = listOf (oneOf features);
      what = "a list of: ${lib.concatStringsSep ", " features}";
    };
    depends = {
      default = [ ];
      check = listOf isId;
      what = "a list of app ids";
    };
    conflicts = {
      default = [ ];
      check = listOf isId;
      what = "a list of app ids";
    };
    installer = {
      default = false;
      check = isBool;
      what = "a bool";
    };
    onIso = {
      default = false;
      check = isBool;
      what = "a bool";
    };
    installerDefault = {
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
      what = "null or a function { pkgs, lib, config, ... } -> hinteros.apps attrs";
    };
    nixos = {
      default = null;
      check = either isNull isFn;
      what = "null or a function { pkgs, lib, config, ... } -> NixOS config";
    };
    packages = {
      default = null;
      check = either isNull isFunction;
      what = "null or a function pkgs -> [ package ]";
    };
  };

  # Arguments used to inspect `app`/`nixos` results without evaluating packages: only the
  # attribute names (and kiosk settings) are looked at, never values that depend on pkgs.
  stubArgs = {
    inherit lib;
    pkgs = throw "catalog: pkgs is not available while validating entry structure";
    config = throw "catalog: config is not available while validating entry structure";
    options = throw "catalog: options is not available while validating entry structure";
  };
  callStub = f: if isFunction f then f stubArgs else f;

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

      ic = full.icon;
      iconProblems =
        let
          unknownKeys = lib.subtractLists [
            "desktopId"
            "siteUrl"
            "firefoxProfile"
          ] (attrNames ic);
        in
        lib.optional (unknownKeys != [ ]) "icon: unknown field(s) ${lib.concatStringsSep ", " unknownKeys}"
        ++ lib.optional (
          ic ? desktopId && builtins.match "[A-Za-z0-9._-]+" ic.desktopId == null
        ) "icon.desktopId: a .desktop file name without the extension"
        ++ lib.optional (ic ? siteUrl && !isHttps ic.siteUrl) "icon.siteUrl: an https URL"
        ++ lib.optional (ic ? firefoxProfile && !isBool ic.firefoxProfile) "icon.firefoxProfile: a bool"
        ++ lib.optional (
          (ic.firefoxProfile or false) && full.kind != "web"
        ) "icon.firefoxProfile: only for kiosk (web) apps"
        ++ lib.optional (
          full.kind == "native" && !(ic ? desktopId)
        ) "icon.desktopId: required for native apps (the icon of the installed app)";

      appAttrs = callStub full.app;
      appProblems =
        if full.app == null then
          [ ]
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
          ) "app.input: gamepad or keyboard";

      nixosAttrs = callStub full.nixos;
      nixosProblems =
        if full.nixos == null then
          [ ]
        else if !isAttrs nixosAttrs then
          [ "nixos: must return an attrset" ]
        else
          let
            bad = lib.subtractLists nixosKeys (attrNames nixosAttrs);
          in
          lib.optional (bad != [ ])
            "nixos: top-level key(s) not allowed: ${lib.concatStringsSep ", " bad} (allowed: ${lib.concatStringsSep ", " nixosKeys})";

      crossField =
        lib.optional (full.app == null && full.nixos == null) "needs app or nixos (or status = \"removed\")"
        ++ lib.optional (
          full.status != "available" && full.statusReason == null
        ) "statusReason: required when status is ${full.status}"
        ++ lib.optional (elem id full.depends) "depends: an app cannot depend on itself"
        ++ lib.optional (elem id full.conflicts) "conflicts: an app cannot conflict with itself"
        ++ lib.optional (
          full.onIso && !lic.free
        ) "onIso: only free apps (the ISO never contains unfree software)"
        ++ lib.optional (
          full.installerDefault && !full.onIso
        ) "installerDefault: the app must also be onIso, so an offline install can pick it"
        ++ lib.optional (
          (full.installer || full.onIso || full.installerDefault) && full.status != "available"
        ) "installer/onIso/installerDefault: only available apps"
        ++ lib.optional (
          full.cache && lic.free
        ) "cache: only for unfree apps (free apps are always in the binary cache)"
        ++ lib.optional (
          full.cache && !lic.redistributable
        ) "cache: only unfreeRedistributable apps may be cached (license.redistributable = true)"
        ++ lib.optional (
          full.kind == "web" && !elem ".local/share/hinteros/firefox/${id}" full.dataPaths
        ) "dataPaths: a kiosk (web) app must list its Firefox profile, .local/share/hinteros/firefox/${id}";
    in
    lib.optional (!isId id) "id: must match ${idPattern} (the file name without .nix)"
    ++ map (n: "missing field: ${n}") missing
    ++ lib.optional (unknown != [ ]) "unknown field(s): ${lib.concatStringsSep ", " unknown}"
    ++ map (n: "${n}: must be ${fields.${n}.what}") invalid
    ++ lib.optionals (missing == [ ] && invalid == [ ] && !tombstone) (
      licProblems ++ termsProblems ++ iconProblems ++ appProblems ++ nixosProblems ++ crossField
    )
    ++ lib.optional (
      tombstone && (e.app or null != null || e.nixos or null != null)
    ) "a removed entry has no app or nixos";

  # Problems between entries.
  checkCatalog =
    entries:
    lib.concatLists (
      lib.mapAttrsToList (
        id: e:
        map (d: "${id}: depends on unknown app ${d}") (lib.filter (d: !(entries ? ${d})) e.depends)
        ++ map (d: "${id}: depends on ${d}, which is ${entries.${d}.status}") (
          lib.filter (d: entries ? ${d} && entries.${d}.status == "removed") e.depends
        )
        ++ map (c: "${id}: conflicts with unknown app ${c}") (lib.filter (c: !(entries ? ${c})) e.conflicts)
        ++ map (d: "${id}: depends on ${d} but also conflicts with it") (
          lib.intersectLists e.depends e.conflicts
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
      lic = {
        unfreePackages = [ ];
      }
      // withDefaults.license;
    in
    withDefaults
    // {
      inherit id;
      license = lic;
      kind = if isAttrs appAttrs && appAttrs ? kiosk then "web" else "native";
      # The ISO and the binary cache never contain unfree software, except apps that opt in with
      # `cache` (checked to be unfreeRedistributable): everything else unfree is built on the box.
      buildsOnDevice = !(lic.free or true) && !withDefaults.cache;
      # Apps on the ISO are always offered in the installer (offline), others only when online.
      installer = withDefaults.installer || withDefaults.onIso;
      icon =
        lib.optionalAttrs (withDefaults.status != "removed") { siteUrl = withDefaults.homepage; }
        // withDefaults.icon;
      packages =
        if withDefaults.packages != null then
          withDefaults.packages
        else
          pkgs:
          let
            a =
              if isFunction withDefaults.app then
                withDefaults.app (stubArgs // { inherit pkgs; })
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
          name
          status
          statusReason
          ;
      }
    else
      {
        inherit (e)
          id
          name
          summary
          category
          homepage
          kind
          sizeMiB
          icon
          requires
          depends
          conflicts
          installer
          onIso
          installerDefault
          dataPaths
          status
          statusReason
          buildsOnDevice
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

  mkIndex = catalog: {
    inherit indexVersion;
    apps = map indexEntry (lib.sort (a: b: a.id < b.id) (lib.attrValues catalog));
  };
in
{
  inherit
    supportedFormats
    indexVersion
    categories
    statuses
    features
    appKeys
    nixosKeys
    checkEntry
    validate
    formatProblems
    normalize
    readDir
    load
    mkIndex
    cacheableUnfreeOf
    ;
}
