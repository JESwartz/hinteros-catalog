# hinteros-catalog

The curated App Store catalog for [HinterOS](https://justsomeshed.com/JSwartz/HinterOS/hinteros):
one entry per app that a HinterOS box can install from Settings or the first-boot wizard.

The catalog reaches boxes as a flake input of the system repo, locked per channel release, so
catalog changes ship with system updates and are covered by the same signed-commit check. Boxes
never fetch this repo on their own. Unfree apps are listed here but only redistributable ones are ever
cached: Plex is fetched from the vendor and built on the box; Steam (`unfreeRedistributable`) is
the one explicit exception (`cache = true`).

License: GPL-3.0-only, except the vendor terms in `apps/terms/`, which belong to their vendors (see `apps/terms/NOTICE`).

## Layout

```
apps/<id>.nix              one entry per app (format 2, below)
apps/terms/<id>-<version>.txt   full vendor terms, plain text, referenced by entries
lib/default.nix            the format: validator, normalizer, index generator (needs only lib)
schema/index.schema.json   JSON Schema of the generated Store index
tests/                     validator unit tests, package/licence eval, NixOS eval
```

Flake outputs:

| Output | What |
|---|---|
| `catalog` | `{ <id> = entry; }`, validated and normalized. Evaluating it throws with every problem if any entry is invalid |
| `catalogIndex` | The Store index as a Nix value |
| `packages.x86_64-linux.index` | `$out/share/hinteros/catalog.json` (the index) and `$out/share/hinteros/terms/*.txt` (the vendor terms it references, so the launcher shows them offline) |
| `lib` | `load`, `validate`, `checkEntry`, `normalize`, `mkIndex`, the enums, and `cacheableUnfree`: the unfree package names (union of `license.unfreePackages`) of entries with `cache = true`, for the system repo's cache job and `forbidUnfree` exception list |
| `checks` | formatting/lint, validator tests, index against its schema, package and licence eval, NixOS eval |

## Entry format (format 2)

An entry is a plain attrset in `apps/<id>.nix`. The id is the file name: lowercase letters,
digits and `-`, at most 32 characters. It is what `state.json`'s `apps` list stores, so it never
changes once published.

| Field | Required | Meaning |
|---|---|---|
| `format` | yes | `2` |
| `name` | yes | Display name, one line, ≤ 40 characters |
| `summary` | yes | One line, ≤ 80 characters |
| `description` | yes | ≤ 1000 characters. Wrap it freely: the index joins lines into paragraphs (a blank line separates paragraphs) |
| `category` | yes | `games`, `video`, `music`, `photos`, `utilities` |
| `homepage` | yes | https URL; also the default `icon.siteUrl` |
| `license` | yes | `{ free; redistributable; unfreePackages ? [ ]; }`. `unfreePackages` are the `lib.getName` names the box must allow; required for unfree apps, empty for free ones. Checked against nixpkgs' `meta.license` |
| `sizeMiB` | yes | Approximate download plus disk use, shown in the Store and used for the free-space check |
| `icon` | yes | Where the session daemon finds the real icon at runtime (HinterOS ships no logos): `desktopId` (the installed app's `.desktop` file; required for native apps), `siteUrl` (defaults to `homepage`; used while the app is not installed and for web apps), `firefoxProfile = true` (web apps whose site refuses icon fetches: use the favicon the kiosk profile stored) |
| `app` | one of `app`/`nixos` | Function of the NixOS module arguments returning `hinteros.apps.<id>` settings: `package`, `command`, `kiosk` (`url`, `userAgent`, `fullscreenOnly`), `input` (`gamepad`/`keyboard`), `backKey`, `order`. The system repo sets `enable`, `name` and the icon fields from metadata |
| `nixos` | one of `app`/`nixos` | Extra NixOS config, a module function or attrset. Only the top-level namespaces `programs`, `hardware`, `services`, `environment`, `xdg`, `fonts`; never `nixpkgs` (no overlays or config: packages are built exactly as in nixpkgs), `imports`, `options` or `hinteros` |
| `packages` | no | `pkgs: [ package ]`, the app's top-level packages for licence checks, cache builds and size. Defaults to `app.package` |
| `status` | no | `available` (default), `retired` (hidden from the Store, keeps working where installed), `removed` (tombstone, see below) |
| `statusReason` | if not available | One line shown to users who have the app |
| `requires` | no | System features the system repo turns on: `graphics32` |
| `depends`, `conflicts` | no | Other app ids. Installing adds dependencies; conflicting apps cannot be installed together |
| `installer` | no | Listed in the installer's and first-boot wizard's app selection when the box is online (Steam, Plex, Moonlight). Implied by `onIso` |
| `onIso` | no | Ships on the ISO, so an offline install can select it. Free apps only; its `depends` must be `onIso` too |
| `installerDefault` | no | Pre-selected in the app selection (YouTube, Firefox). Must also be `onIso`. Still an ordinary app: every app can be removed |
| `cache` | no | Default `false`. `true` only for an unfree app whose unfree packages are all `unfreeRedistributable` in nixpkgs: CI builds it, the binary cache serves it and the install is a download like a free app. Checked against nixpkgs `meta.license` by `tests/packages.nix`. Free apps are always cached and must not set it. Names go into `lib.cacheableUnfree` |
| `terms` | unfree apps | The vendor's full terms, shown in full in the install dialog before the user accepts: `{ title; version; url; retrieved; text; }`. `version` is the vendor's version or revision date (the box records which version was accepted), `retrieved` the date the text was copied (`YYYY-MM-DD`), `text` a plain UTF-8 file `./terms/<id>-<version>.txt`. The index carries title, version, url, retrieved and the file name `terms/<id>-<version>.txt`; the index package installs the files next to `catalog.json` |
| `dataPaths` | no | Paths relative to a profile's home that hold the app's data. "Remove and delete data" deletes them in every profile after a second confirmation. No leading `/` or `~`, no `.`, `..` or empty components, no wildcards. A kiosk (web) app must list its Firefox profile, `.local/share/hinteros/firefox/<id>`. Deleting Steam's `.local/share/Steam` also removes installed games |
| `notes` | no | Maintainer notes (upstream quirks, review findings); not in the index |

Derived fields in `catalog` and the index: `id`, `kind` (`web` if `app.kiosk` is set, else
`native`) and `buildsOnDevice` (true for unfree apps without `cache`: only `cache = true` unfree apps are in the vendor
cache, and nothing unfree is ever on the ISO), and `installer` (true also for `onIso` apps).

### Changes from format 1

Format 2 replaces `featured`/`preinstalled` by `installer`/`onIso`/`installerDefault` (default apps
are ordinary, removable apps now), drops `ageRating` (comes back with parental controls) and adds
`cache`, `terms` and `dataPaths`. Index version 2. Entries that name the old fields are rejected.

### Removing an app

Never delete an entry file: `state.json` on some box may still list the id, and an unknown id
fails evaluation. Set `status = "retired"` to hide the app while it still works, or replace the
file with a tombstone once it can no longer be built:

```nix
{
  format = 2;
  name = "Old app";
  status = "removed";
  statusReason = "Discontinued by its developer.";
}
```

Boxes that have a removed app lose it on their next update, and the update screen says so.

## Adding an app

1. Create `apps/<id>.nix`; copy the closest example (`moonlight.nix` for a free native app,
   `crunchyroll.nix` for a web app, `plex-htpc.nix` for an unfree one with terms, `steam.nix` for a
   cached unfree one). Unfree apps need `terms`: fetch the vendor's text, see below.
2. Run `nix flake check`. It validates the entry, checks the licence declaration against nixpkgs
   (unfree apps are evaluated only, never built), evaluates a NixOS system with every entry, and
   checks the generated index against `schema/index.schema.json`.
3. Review checklist:
   - The package is in nixpkgs and built by Hydra, or (unfree) builds from the vendor's own
     download. No overlays, patches or `override`s.
   - The app works with a controller under gamescope: `input` is right, Back leaves or goes back,
     text entry works with the on-screen keyboard.
   - `license` matches the real licence; for unfree apps the vendor's terms allow installing it
     on the box. Nothing unfree is ever on the ISO (`onIso`).
   - `cache = true` only if the vendor's licence allows redistribution: every unfree package of the
     entry has nixpkgs' `unfreeRedistributable` licence (`nix flake check` enforces it) and the
     vendor's terms agree. Plex-style apps stay `false`.
   - Terms: `terms.text` is the vendor's current full text (nothing paraphrased), `version`, `url`
     and `retrieved` are right, and the file is named `<id>-<version>.txt`.
   - `dataPaths` lists every directory the app writes under a profile's home (check on a box:
     `~/.config`, `~/.local/share`, `~/.cache`, dotfiles), and nothing shared with other apps.
   - The icon resolves on a box: `desktopId` matches the installed `.desktop` file and `siteUrl`
     serves a usable icon (or `firefoxProfile` is set).
   - `sizeMiB` measured on a box (`nix path-info -S` of the closure minus what the box already has).
   - Name, summary and description are user-facing English, no marketing.
4. Merge, then bump `hinteros-catalog` in the system repo's `flake.lock` on `beta`. CI builds and
   caches every free entry and every `cache = true` entry; boxes on `beta` see the app after their next update.

## Refreshing vendor terms

Vendors revise their terms; the box shows the text from the catalog, so it must be kept current.
Review each terms-bearing entry (Steam, Plex) at least every release and whenever a vendor
announces a change:

1. Open `terms.url` and note the version or "last updated"/"revised" date on the page.
2. If it differs from `terms.version`: save the page's agreement text as plain text (headings and
   paragraphs preserved, no navigation, scripts or footers) as `apps/terms/<id>-<new version>.txt`.
   Never paraphrase or hand-edit the vendor's wording. If the text cannot be fetched, do not
   invent it: keep the old version and open an issue.
3. In the entry, set `terms.version`, `terms.retrieved` (today) and `terms.text`; `git rm` the old
   file.
4. Read the diff against the old text for changes that affect the install decision (new
   licence restrictions, redistribution, subscription terms) and revisit `cache` and the
   description if so.
5. `nix flake check`. A new `version` makes boxes ask for acceptance again on the next install of
   that app (the box records the accepted version).

## Development

`nix develop` gives nixfmt, statix, deadnix, jq and check-jsonschema, and installs the
pre-commit hook. `nix fmt` formats. CI runs `nix flake check` on every push
(`.forgejo/workflows/check.yml`).
