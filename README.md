# hinteros-catalog

The curated App Store catalog for [HinterOS](https://hinteros.org):
one entry per app that a HinterOS profile can install from the Store or the installer, and per
service (box-wide software) that the admin can turn on.

The catalog reaches boxes as a flake input of the system repo, locked per channel release, so
catalog changes ship with system updates and are covered by the same signed-commit check. Boxes
never fetch this repo on their own. Unfree apps are listed here but only redistributable ones are ever
cached: Plex is fetched from the vendor and built on the box; Steam and Modrinth
(`unfreeRedistributable`) are the explicit exceptions (`delivery = "download"`).

License: GPL-3.0-only, except the vendor terms in `apps/terms/`, which belong to their vendors (see `apps/terms/NOTICE`), and the upstream READMEs in `apps/readme/`, which keep their projects' licences (see `apps/readme/NOTICE`).

## Layout

```
apps/<id>.nix              one entry per app or service (format 3, below)
apps/terms/<name>-<version>.txt full vendor terms, plain text, referenced by entries
apps/readme/<id>.md        upstream READMEs, Markdown, referenced by entries
lib/default.nix            the format: validator, normalizer, index generator (needs only lib)
schema/index.schema.json   JSON Schema of the generated Store index
check-urls.sh               online URL check behind `nix run .#check-icon-urls`
tests/                     validator unit tests, package/licence eval, NixOS eval
```

Flake outputs:

| Output | What |
|---|---|
| `catalog` | `{ <id> = entry; }`, validated and normalized. Evaluating it throws with every problem if any entry is invalid |
| `catalogIndex` | The Store index as a Nix value |
| `packages.x86_64-linux.index` | `$out/share/hinteros/catalog.json` (the index) `$out/share/hinteros/terms/*.txt` and `$out/share/hinteros/readme/*.md` (the vendor terms and READMEs it references, so the launcher shows them offline) |
| `lib` | `load`, `validate`, `checkEntry`, `normalize`, `mkIndex`, the enums, `cacheableUnfree` (the unfree package names of entries with `delivery = "download"`, for the cache job and the `forbidUnfree` exception list; `cacheableUnfreeOf` takes a catalog). The system repo derives its own views (installer lists in `nixos/lib/app-ids.nix`, `lib.catalogIds`) from `catalog` |
| `apps.x86_64-linux.check-icon-urls` | Online check of `iconUrl`, `siteUrl`, `terms.url` and `readme.url` (see Icons) |
| `checks` | formatting/lint, validator tests, index against its schema (v4), package and licence eval, NixOS eval of every box feature and service |

## Entry format (format 3)

An entry is a plain attrset in `apps/<id>.nix`. The id is the file name: lowercase letters,
digits and `-`, at most 32 characters. It is what the box stores (env manifests, the registry,
`starter.json`, `state.json`'s `services`), so it never changes once published.

There are two kinds. An **app** (`kind = "app"`, the default) is installed per profile into that
profile's own app env, with no system rebuild, and shows in the Store. A **service**
(`kind = "service"`) is a box-wide NixOS module, enabled by the admin profile (Server section,
M10); it is never in the Store. See [How to add an app](#adding-an-app-or-a-service) below.

| Field | Required | Meaning |
|---|---|---|
| `format` | yes | `3` |
| `kind` | no | `app` (default) or `service` |
| `name` | yes | Display name, one line, ≤ 40 characters |
| `summary` | yes | One line, ≤ 80 characters |
| `description` | yes | ≤ 1000 characters. Wrap it freely: the index joins lines into paragraphs (a blank line separates paragraphs) |
| `category` | yes | `games`, `video`, `music`, `photos`, `utilities` |
| `homepage` | yes | https URL; also the default `icon.siteUrl` |
| `license` | yes | `{ unfree; unfreePackages ? [ ]; }`. `unfreePackages` are the `lib.getName` names that must be allowed; required for unfree entries, empty for free ones. Checked against nixpkgs' `meta.license` |
| `sizeMiB` | yes | Approximate download plus disk use, shown in the Store and used for the free-space check |
| `icon` | yes | Where the session daemon finds the real icon at runtime (HinterOS ships no logos, see Icons): `desktopId` (the installed app's `.desktop` file; required for native apps), `iconUrl` (optional, https: the vendor's own public logo) with `sha256` (required with `iconUrl`: the hex SHA-256 of that file; the daemon refuses any other file), `siteUrl` (defaults to `homepage`; used while the app is not installed and for web apps; `null` turns discovery off for a native app whose site gives no icon of its own), `firefoxProfile = true` (web apps whose site refuses icon fetches: use the favicon the kiosk profile stored) |
| `app` | apps | `{ pkgs, lib, box }: { … }`, called by the system repo's env builder. Returns `package`, `command`, `kiosk` (`url`, `userAgent`, `fullscreenOnly`), `input` (`gamepad`/`keyboard`), `backKey`, `order` and `listed` (`false`: no tile of its own, as Steam's built-in one). `backKey` (one of the session daemon's key names, with optional `ctrl+`/`shift+`/`alt+`/`meta+`) and `kiosk.fullscreenOnly = true` need `input = "keyboard"`: the daemon refuses an app that breaks this, and then ignores every app of that profile. It takes exactly those three arguments: no `config`, an app depends on the box only through `box`. `box.firefoxKiosk` is the kiosk wrapper with its Firefox, `box.steam` is `pkgs.steam` with this box's graphics packages. The system repo sets `name` and the icon fields from metadata; an entry can never set a packaged `icon` or an unfree allowance beyond `license.unfreePackages` |
| `boxFeatures` | no (apps) | Box features the app needs, from a closed list: `graphics32` (32-bit graphics drivers and PipeWire ALSA) and `steam-devices` (controller udev rules). The system turns them on box-wide when any profile has the app. A new feature is a system-repo change (`box-features.nix`); the validator refuses unknown names. Services cannot set `boxFeatures` |
| `service` | services | A restricted NixOS module, a function of `pkgs`, `lib`, `config`, `options` or an attrset. Allowed top-level namespaces: `services`, `hardware` and `systemd.services.<own unit>` (exactly `<name>` or `<name>d` for one of the module's own `services.<name>`, e.g. `systemd.services.tailscaled` for `services.tailscale`). Never `networking` or a module's own `openFirewall` (open ports with `ports`), `nixpkgs` (no overlays or config: packages are built exactly as in nixpkgs), `imports`, `options`, `users`, `environment` (nothing is installed for profiles), `boot`, `programs` or `hinteros`. Do not wrap the module, `services`, `systemd` or `systemd.services` in `mkIf`/`mkMerge`: the validator reads their names (inside `services.<name>` they are fine, and `openFirewall` is refused there too). Services have no `app`, `boxFeatures`, `starter` or `onIso` |
| `ports` | no (services) | Ports the system opens while the service is on: `[ { port; proto = "tcp" \| "udp"; from = "lan" \| "any"; } ]`. `lan` is the local networks (the system's list, as for SSH) and the `tailscale0` interface; `any` is every source, only for a server that does its own sign-in and remote access (Plex). Each port and proto once. In the index |
| `setup` | no (services) | The Server section's setup flow, named after the service id: `jellyfin-server` (first run by the system, libraries, one user per profile), `plex-media-server` (claim code), `tailscale` (sign in by QR), `cloudflare-tunnel` (Zero Trust tunnel token), or `null` (on and off only). A new flow is a daemon and launcher change. In the index |
| `stateDirs` | no (services) | Directories below `/var/lib` that "Delete server data" removes when the service is turned off: letters, digits, `.`, `_`, `-` and `/`; no `.`, `..` or empty components. In the index |
| `packages` | services | `pkgs: [ package ]`, the entry's top-level packages for licence checks, cache builds and size. Apps: defaults to `app.package` (with `box` standing in as plain nixpkgs packages). Required for services |
| `status` | no | `available` (default), `retired` (hidden from the Store, keeps working where installed), `removed` (tombstone, see below) |
| `statusReason` | if not available | One line shown to users who have the app |
| `depends`, `conflicts` | no | Other ids of the same kind. Installing adds dependencies; conflicting apps cannot be installed together |
| `starter` | no (apps) | `null` (default: Store only), `"offered"` (listed in the installer's app step) or `"ticked"` (listed and pre-selected; needs `onIso`). The installer's picks are the starter set, copied into every new profile and guest session. Offered: YouTube, Jellyfin, Firefox, Steam, VacuumTube, Plex; ticked: YouTube, Firefox. Offered apps that are not `onIso` (Steam, VacuumTube, Plex) are downloaded, so picking one needs a network connection |
| `needsServices` | no (apps) | Ids of `kind = "service"` entries the app needs (e.g. `[ "jellyfin-server" ]`); the validator refuses unknown ids, apps, removed entries, and the field on a service. Never installed with the app. In the index, but not enforced yet: the daemon parses it, and neither the Store nor the privileged service checks it, so an app with `needsServices` installs like any other. Do not rely on it until the daemon refuses the install while a needed service is off. An app's `depends` stays app-to-app |
| `onIso` | no (apps) | Its closure ships on the ISO. The free web (kiosk) apps and Jellyfin set it. An offline install offers only the `onIso` apps that also have `starter` (YouTube, Jellyfin, Firefox); the others are on the ISO but only in the Store. Free apps only; its `depends` must be `onIso` too |
| `delivery` | no (unfree entries) | `"build"` (the default for unfree entries): fetched from the vendor and built on the box during install. `"download"`: only for an unfree entry whose unfree packages are all `unfreeRedistributable` in nixpkgs (free licences beside it are fine): CI builds it, the binary cache serves it and the install is a download like a free app. Checked against nixpkgs `meta.license` by `tests/packages.nix`. Free entries are always cached and must not set it (their `delivery` is always `"download"`). Names of `"download"` entries go into `lib.cacheableUnfree` |
| `terms` | unfree entries | The vendor's full terms, shown in full in the install dialog before the user accepts: `{ title; version; url; retrieved; text; }`. `version` is the vendor's version or revision date (the box records which version each profile accepted), `retrieved` the date the text was copied (`YYYY-MM-DD`), `text` a plain UTF-8 file `./terms/<name>-<version>.txt`, `<name>` the id, or a vendor name when entries share one document (Plex HTPC and Plex Media Server use `plex-<version>.txt`): entries with the same `url` or file must have the same terms. The index carries title, version, url, retrieved and the file name `terms/<name>-<version>.txt`; the index package installs the files next to `catalog.json` |
| `readme` | no | The upstream project's README, shown on the app's Store page: `{ url; retrieved; text; }`. `url` is the file at the exact upstream commit (`https://github.com/<repo>/blob/<sha>/README.md`), `retrieved` the date it was copied, `text` the file `./readme/<id>.md`, unmodified, at most 64 KiB. Apps with the same upstream (the OpenRA mods) each have their own copy. The index carries url, retrieved and `readme/<id>.md`; the index package installs the files next to `catalog.json`. See "Upstream READMEs" |
| `dataPaths` | no | Paths relative to a profile's home that hold the app's data when it runs without the sandbox (the sandbox home is added automatically, see `sandbox`). "Remove and delete data" deletes them in the removing profile's home only, after a second confirmation. No leading `/` or `~`, no `.`, `..` or empty components, none of `* ? [ ] \ $` and backtick (the daemon refuses the whole index for a path it does not accept). A kiosk (web) app must list its Firefox profile, `.local/share/hinteros/firefox/<id>`. Deleting Steam's `.local/share/Steam` also removes installed games. Services keep their data in `/var/lib` (`stateDirs`); the validator refuses `dataPaths` on them |
| `permissions` | no (apps) | What the app may use in its sandbox, `{ <name> = "required" \| "optional"; }`, default `{ }`. Names: `gamepad` (`/dev/input`, device ACLs limit it to controllers, and `/run/udev`; `"required"` for every app with `input = "gamepad"` or no `input`, the daemon's default), `mic` (a pulse socket that may record), `downloads` (the profile's `~/Downloads`, read-write), `lan` (the local network: devices at home and this box's own services; without it the app reaches only DNS and the internet). The install sheet shows them all switched on; the user can switch optional ones off (then and on the app's page). The validator refuses other names and values. In the index |
| `sandbox` | no (apps) | Default `true`: the session daemon starts the app in its bwrap sandbox, with its own home `.local/share/hinteros/sandbox/<id>` (added to `dataPaths` automatically). `false` only for Steam, which runs its own sandbox; such an app has no `permissions`. In the index |
| `notes` | no | Maintainer notes (upstream quirks, review findings); not in the index |

Derived fields in `catalog` and the index: `id` and `delivery` (see above; nothing unfree is ever
on the ISO). For a sandboxed app, `dataPaths` also has its sandbox home,
`.local/share/hinteros/sandbox/<id>`, and `sandbox` is always `false` for services. `catalog` also
has `type` (`web` if `app.kiosk` is set, else `native`; `service` for services), which the
validator reads; it is not in the index. In the index, `license.unfree` is the entry field `unfree`.

### Icons

The repo never contains logos or other images. An entry may instead link to the vendor's own
public logo with `icon.iconUrl`; the box's session daemon downloads it at runtime (https only,
at most 1 MiB, image content-type and magic bytes checked, and only the file whose SHA-256 is
`icon.sha256`), caches it under `~/.cache/hinteros/icons` and refreshes it about monthly. A
changed or replaced file upstream is refused (logged on the box) until the entry gets the new
hash. The index carries `iconUrl` and `sha256`, so the launcher's Store can
show logos before an app is installed. Priority, first hit wins:

1. the installed app's own desktop icon (`desktopId`)
2. `iconUrl`
3. discovery on `siteUrl` (web app manifest, `apple-touch-icon`, `<link rel=icon>`, `/favicon.ico`)
4. the favicon Firefox stored in the kiosk profile (`firefoxProfile`)
5. a letter tile

Choosing an `iconUrl`: a square PNG or SVG of at least 192 px, hosted on the vendor's or
project's own domain (or its official GitHub organisation, for open-source projects), never a
Wikimedia page or third-party mirror, and as stable as possible (press-kit or branding-repo
assets over CDN hashes; a GitHub raw URL at a commit, never at a branch such as `main`, which moves and breaks the hash). Say in a comment where it came from and the date it was checked. If no
suitable official URL exists, leave `iconUrl` unset and say why; the fallbacks cover it. Set
`sha256` to the file's hash: `curl -sSL <iconUrl> | sha256sum`; look at the file first.

`nix run .#check-icon-urls` fetches every `iconUrl`, `siteUrl`, `terms.url` and `readme.url` (HTTP 200; for
`iconUrl` also an image content-type, at most 1 MiB, image magic bytes and the `sha256`), prints a table and
exits non-zero on failures. It needs network, so it is not part of `nix flake check`; the
scheduled `.forgejo/workflows/links.yml` runs it weekly.

### Removing an app

Never delete an entry file: a profile's env, the starter set or `state.json`'s `services` on some box may still list the id, and an unknown id fails evaluation. A tombstone of a service keeps `kind = "service"`. Set `status = "retired"` to hide the app while it still works, or replace the
file with a tombstone once it can no longer be built:

```nix
{
  format = 3;
  name = "Old app";
  status = "removed";
  statusReason = "Discontinued by its developer.";
  # Keep the app's dataPaths (and `sandbox = false` if it had it), so profiles can still delete its data.
  dataPaths = [ ".config/old-app" ];
}
```

Boxes that have a removed app lose it on their next update, and the update screen says so. The
app's data stays in each profile's home: the tombstone's index entry keeps `dataPaths`, with the
sandbox home of an app that had one.

## Adding an app or a service

**An app** is something a profile uses: it goes in the Store. **A service** runs for the whole box
(a media server, a VPN) and only the admin profile turns it on; it is never in the Store. If it
needs box-wide configuration but runs nothing for users (Steam's 32-bit graphics), it is an app
with `boxFeatures`, not a service.

1. Create `apps/<id>.nix`; copy the closest example (`moonlight.nix` for a free native app,
   `crunchyroll.nix` for a web app, `plex-htpc.nix` for an unfree one with terms, `steam.nix` for a
   cached unfree one with `boxFeatures`, `youtube.nix` for a starter-set app on the ISO,
   `jellyfin-server.nix` for a service: `kind = "service"`, a `service` module in the allowed
   namespaces, `packages`, `ports`, `setup`, `stateDirs`, no `app`/`boxFeatures`/`starter`/`onIso`). Unfree apps need `terms`: fetch the vendor's text, see below.
2. Run `nix flake check`. It validates the entry, checks the licence declaration against nixpkgs
   (unfree apps are evaluated only, never built), evaluates a NixOS system with every box feature and service, and
   checks the generated index against `schema/index.schema.json`.
3. Review checklist:
   - The package is in nixpkgs and built by Hydra, or (unfree) builds from the vendor's own
     download. No overlays, patches or `override`s.
   - The app works with a controller under gamescope: `input` is right, Back leaves or goes back,
     text entry works with the on-screen keyboard.
   - `license` matches the real licence; for unfree apps the vendor's terms allow installing it
     on the box. Nothing unfree is ever on the ISO (`onIso`).
   - `delivery = "download"` only if the vendor's licence allows redistribution: every unfree package of the
     entry has nixpkgs' `unfreeRedistributable` licence (`nix flake check` enforces it) and the
     vendor's terms agree. Plex-style apps stay `"build"`.
   - Terms: `terms.text` is the vendor's current full text (nothing paraphrased), `version`, `url`
     and `retrieved` are right, and the file is named `<name>-<version>.txt`.
   - `dataPaths` lists every directory the app writes under a profile's home when it runs without
     the sandbox (`hinteros.sandbox.enable = false`, a supported setting; check on a box:
     `~/.config`, `~/.local/share`, `~/.cache`, dotfiles), and nothing shared with other apps.
     With the sandbox the app writes only inside its sandbox home, which is listed automatically,
     so a sandboxed app lists these paths too: they are what "delete data" removes without it.
   - `permissions` lists what the app needs in its sandbox and nothing more: `gamepad = "required"`
     for `input = "gamepad"` or no `input`, optional for anything the app works without.
   - The icon resolves on a box: `desktopId` matches the installed `.desktop` file, `iconUrl` (if any) passes `nix run .#check-icon-urls` and `siteUrl`
     serves a usable icon (or `firefoxProfile` is set).
   - `sizeMiB` measured on a box (`nix path-info -S` of the closure minus what the box already has).
   - Name, summary and description are user-facing English (ASD-STE100 Simplified Technical
     English), no marketing. They describe the app or service only: what it is and what it offers.
     No advice on when to install it, no account or subscription notes, no install, DRM,
     resolution or Linux-support notes and no implementation details: those go in comments.
4. Merge, then bump `hinteros-catalog` in the system repo's `flake.lock` on `main` and release it
   with `nix run .#promote` (main to beta; `beta` and `stable` take only signed release commits).
   Boxes on `beta` see the app after their next update. There is no HinterOS binary cache yet
   (`hinteros.cache.enable` is off by default): what cache.nixos.org does not have, the box builds.

## Refreshing vendor terms

Vendors revise their terms; the box shows the text from the catalog, so it must be kept current.
Review each terms-bearing entry (Steam, Plex) at least every release and whenever a vendor
announces a change:

1. Open `terms.url` and note the version or "last updated"/"revised" date on the page.
2. If it differs from `terms.version`: save the page's agreement text as plain text (headings and
   paragraphs preserved, no navigation, scripts or footers) as `apps/terms/<name>-<new version>.txt`.
   Never paraphrase or hand-edit the vendor's wording. If the text cannot be fetched, do not
   invent it: keep the old version and open an issue.
3. In each entry that uses the file, set `terms.version`, `terms.retrieved` (today) and
   `terms.text`; `git rm` the old file.
4. Read the diff against the old text for changes that affect the install decision (new
   licence restrictions, redistribution, subscription terms) and revisit `delivery` and the
   description if so.
5. `nix flake check`. A new `version` makes boxes ask for acceptance again on the next install of
   that app (the box records the accepted version).

## Upstream READMEs

The Store page of an app shows its upstream README (Markdown; images, HTML and links are shown
as plain text or left out). Only open-source apps with a README in their repository have one.
To add or refresh one:

1. Take the README of the commit the packaged release comes from, or of the default branch.
2. Save it unmodified as `apps/readme/<id>.md`. Never edit or shorten the upstream text.
3. Set `readme.url` to the file at that commit and `readme.retrieved` to today.

Refresh them with the vendor terms, at least every release.

## Development

`nix develop` gives nixfmt, statix, deadnix, jq and check-jsonschema, and installs the
pre-commit hook. `nix fmt` formats. CI runs `nix flake check` on every push
(`.forgejo/workflows/check.yml`); a weekly job checks the online URLs (`links.yml`, see Icons).
