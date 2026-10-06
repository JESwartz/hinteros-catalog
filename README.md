# hinteros-catalog

The curated App Store catalog for [HinterOS](https://justsomeshed.com/JSwartz/HinterOS/hinteros):
one entry per app that a HinterOS box can install from Settings or the first-boot wizard.

The catalog reaches boxes as a flake input of the system repo, locked per channel release, so
catalog changes ship with system updates and are covered by the same signed-commit check. Boxes
never fetch this repo on their own. Unfree apps such as Plex and Steam are listed here but never
redistributed: the box fetches them from the vendor and builds them itself.

License: GPL-3.0-only.

## Layout

```
apps/<id>.nix              one entry per app (format 1, below)
lib/default.nix            the format: validator, normalizer, index generator (needs only lib)
schema/index.schema.json   JSON Schema of the generated Store index
tests/                     validator unit tests, package/licence eval, NixOS eval
```

Flake outputs:

| Output | What |
|---|---|
| `catalog` | `{ <id> = entry; }`, validated and normalized. Evaluating it throws with every problem if any entry is invalid |
| `catalogIndex` | The Store index as a Nix value |
| `packages.x86_64-linux.index` | `$out/share/hinteros/catalog.json` (the index, pretty-printed) |
| `lib` | `load`, `validate`, `checkEntry`, `normalize`, `mkIndex`, and the enums |
| `checks` | formatting/lint, validator tests, index against its schema, package and licence eval, NixOS eval |

## Entry format (format 1)

An entry is a plain attrset in `apps/<id>.nix`. The id is the file name: lowercase letters,
digits and `-`, at most 32 characters. It is what `state.json`'s `apps` list stores, so it never
changes once published.

| Field | Required | Meaning |
|---|---|---|
| `format` | yes | `1` |
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
| `ageRating` | no | `null` (default) or a PEGI-style age: 3, 7, 12, 16, 18 (for future parental controls) |
| `requires` | no | System features the system repo turns on: `graphics32` |
| `depends`, `conflicts` | no | Other app ids. Installing adds dependencies; conflicting apps cannot be installed together |
| `featured` | no | Offered in the installer's app step. Not for preinstalled apps |
| `preinstalled` | no | A default app: always installed, in the ISO, no Remove. Free apps only |
| `notes` | no | Maintainer notes (upstream quirks, review findings); not in the index |

Derived fields in `catalog` and the index: `id`, `kind` (`web` if `app.kiosk` is set, else
`native`) and `buildsOnDevice` (true for every unfree app: nothing unfree is ever in the vendor
cache or the ISO).

### Removing an app

Never delete an entry file: `state.json` on some box may still list the id, and an unknown id
fails evaluation. Set `status = "retired"` to hide the app while it still works, or replace the
file with a tombstone once it can no longer be built:

```nix
{
  format = 1;
  name = "Old app";
  status = "removed";
  statusReason = "Discontinued by its developer.";
}
```

Boxes that have a removed app lose it on their next update, and the update screen says so.

## Adding an app

1. Create `apps/<id>.nix`; copy the closest example (`moonlight.nix` for a free native app,
   `crunchyroll.nix` for a web app, `plex-htpc.nix` for an unfree one).
2. Run `nix flake check`. It validates the entry, checks the licence declaration against nixpkgs
   (unfree apps are evaluated only, never built), evaluates a NixOS system with every entry, and
   checks the generated index against `schema/index.schema.json`.
3. Review checklist:
   - The package is in nixpkgs and built by Hydra, or (unfree) builds from the vendor's own
     download. No overlays, patches or `override`s.
   - The app works with a controller under gamescope: `input` is right, Back leaves or goes back,
     text entry works with the on-screen keyboard.
   - `license` matches the real licence; for unfree apps the vendor's terms allow installing it
     on the box. Nothing unfree is ever preinstalled or featured in an offline install.
   - The icon resolves on a box: `desktopId` matches the installed `.desktop` file and `siteUrl`
     serves a usable icon (or `firefoxProfile` is set).
   - `sizeMiB` measured on a box (`nix path-info -S` of the closure minus what the box already has).
   - Name, summary and description are user-facing English, no marketing.
4. Merge, then bump `hinteros-catalog` in the system repo's `flake.lock` on `beta`. CI builds and
   caches every free entry; boxes on `beta` see the app after their next update.

## Development

`nix develop` gives nixfmt, statix, deadnix, jq and check-jsonschema, and installs the
pre-commit hook. `nix fmt` formats. CI runs `nix flake check` on every push
(`.forgejo/workflows/check.yml`).
