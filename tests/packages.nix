# Every entry's packages evaluate against nixpkgs (nothing is built), and each entry's licence
# declaration matches nixpkgs' meta:
#   - with exactly the entry's unfreePackages allowed, its packages evaluate;
#   - an unfree entry fails to evaluate with nothing allowed (so the declaration is needed);
#   - license.unfree equals what nixpkgs says about the packages;
#   - delivery = "download" only if every package is redistributable in nixpkgs;
#   - delivery = "download" only if every unfree package of the entry has nixpkgs' unfreeRedistributable
#     licence (with free licences beside it at most: Modrinth is GPL-3.0 and unfreeRedistributable).
# Unfree packages are only evaluated, never built: anything built on the runner would end up
# in the store Harmonia serves. Run under pure evaluation (nix flake check): impure evaluation
# would let NIXPKGS_ALLOW_UNFREE or a user nixpkgs config hide a missing declaration.
{
  pkgs,
  nixpkgs,
  catalog,
}:
let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;

  pkgsAllowing =
    names:
    import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = p: builtins.elem (lib.getName p) names;
    };
  pkgsFree = import nixpkgs { inherit system; };

  drvPaths = ps: map (p: builtins.unsafeDiscardStringContext p.drvPath) ps;
  evaluates =
    p: e:
    let
      r = builtins.tryEval (builtins.deepSeq (drvPaths (e.packages p)) true);
    in
    r.success && r.value;

  licenses = p: lib.toList (p.meta.license or [ ]);
  isFree = p: lib.all (l: l.free or true) (licenses p);
  isUnfreeRedistributable =
    p: lib.all (l: l == lib.licenses.unfreeRedistributable || (l.free or true)) (licenses p);
  isRedistributable = p: lib.all (l: l.redistributable or (l.free or true)) (licenses p);

  checkEntry =
    id: e:
    let
      own = if e.license.unfree then pkgsAllowing e.license.unfreePackages else pkgsFree;
      ok = evaluates own e;
      ps = if ok then e.packages own else [ ];
    in
    lib.optional (!ok)
      "${id}: packages do not evaluate with unfreePackages ${builtins.toJSON e.license.unfreePackages} allowed"
    ++ lib.optional (
      e.license.unfree && evaluates pkgsFree e
    ) "${id}: declared unfree, but its packages evaluate with no unfree package allowed"
    ++
      lib.optional (ok && ps != [ ] && lib.all isFree ps == e.license.unfree)
        "${id}: license.unfree = ${lib.boolToString e.license.unfree}, but nixpkgs says ${
          lib.boolToString (!lib.all isFree ps)
        }"
    ++ lib.optionals (ok && e.delivery == "download") (
      map (
        p: "${id}: delivery = download, but ${lib.getName p} is not unfreeRedistributable in nixpkgs"
      ) (lib.filter (p: !isFree p && !isUnfreeRedistributable p) ps)
    )
    ++ lib.optional (
      ok && e.delivery == "download" && !lib.all isRedistributable ps
    ) "${id}: delivery = download, but nixpkgs says it is not redistributable";

  problems = lib.concatLists (
    lib.mapAttrsToList checkEntry (lib.filterAttrs (_: e: e.status != "removed") catalog)
  );
  report = lib.concatStringsSep "\n" problems;
in
pkgs.runCommand "catalog-packages-eval" { inherit report; } (
  if problems == [ ] then
    "touch $out"
  else
    ''
      echo "$report" >&2
      exit 1
    ''
)
