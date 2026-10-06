# Every entry's packages evaluate against nixpkgs (nothing is built), and each entry's licence
# declaration matches nixpkgs' meta:
#   - with exactly the entry's unfreePackages allowed, its packages evaluate;
#   - an unfree entry fails to evaluate with nothing allowed (so the declaration is needed);
#   - license.free / license.redistributable equal what nixpkgs says about the packages;
#   - cache = true only if every unfree package of the entry has nixpkgs' unfreeRedistributable
#     licence.
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
  isUnfreeRedistributable = p: lib.all (l: l == lib.licenses.unfreeRedistributable) (licenses p);
  isRedistributable = p: lib.all (l: l.redistributable or (l.free or true)) (licenses p);

  checkEntry =
    id: e:
    let
      own = if e.license.free then pkgsFree else pkgsAllowing e.license.unfreePackages;
      ok = evaluates own e;
      ps = if ok then e.packages own else [ ];
    in
    lib.optional (!ok)
      "${id}: packages do not evaluate with unfreePackages ${builtins.toJSON e.license.unfreePackages} allowed"
    ++ lib.optional (
      !e.license.free && evaluates pkgsFree e
    ) "${id}: declared unfree, but its packages evaluate with no unfree package allowed"
    ++
      lib.optional (ok && ps != [ ] && lib.all isFree ps != e.license.free)
        "${id}: license.free = ${lib.boolToString e.license.free}, but nixpkgs says ${lib.boolToString (lib.all isFree ps)}"
    ++ lib.optionals (ok && e.cache) (
      map (p: "${id}: cache = true, but ${lib.getName p} is not unfreeRedistributable in nixpkgs") (
        lib.filter (p: !isFree p && !isUnfreeRedistributable p) ps
      )
    )
    ++
      lib.optional (ok && ps != [ ] && lib.all isRedistributable ps != e.license.redistributable)
        "${id}: license.redistributable = ${lib.boolToString e.license.redistributable}, but nixpkgs says ${lib.boolToString (lib.all isRedistributable ps)}";

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
