{
  description = "HinterOS App Store catalog: one Nix entry per app, a validator and the Store index";

  inputs = {
    # Only for checks, the index package and the dev shell. Entries take pkgs from whoever
    # consumes them (the system repo, with `inputs.nixpkgs.follows`), so they work on either
    # nixpkgs base.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (nixpkgs) lib;
      catalogLib = import ./lib { inherit lib; };
      # Each terms file once: entries with the same document share one (Plex).
      termsFiles = lib.unique (
        map (e: e.terms.text) (lib.filter (e: e.terms or null != null) (lib.attrValues self.catalog))
      );
      readmeEntries = lib.filter (e: e.readme or null != null) (lib.attrValues self.catalog);
    in
    {
      # Entry format implementation (validator, normalizer, index), pure: needs only `lib`.
      lib = catalogLib // {
        # Unfree package names allowed in the binary cache and the ISO build despite
        # `forbidUnfree`: unfree entries with `delivery = "download"` (nixpkgs-checked unfreeRedistributable).
        cacheableUnfree = catalogLib.cacheableUnfreeOf self.catalog;
      };

      # Every entry, validated and normalized: { <id> = entry; }. Evaluating it throws with every
      # problem if any entry is invalid. Metadata is plain data; `app`, `service` and `packages`
      # are functions the system repo calls with its own pkgs.
      catalog = catalogLib.load ./apps;

      # The Store index as a value (what the index package writes).
      catalogIndex = catalogLib.mkIndex self.catalog;

      packages.${system} = {
        # $out/share/hinteros/catalog.json plus terms/*.txt and readme/*.md (the vendor terms and
        # upstream READMEs it references, so the launcher shows them offline): the system repo installs it, so a box finds the
        # index of its running generation at /run/current-system/sw/share/hinteros/catalog.json.
        index =
          pkgs.runCommand "hinteros-catalog-index"
            {
              nativeBuildInputs = [ pkgs.jq ];
              passAsFile = [ "json" ];
              json = builtins.toJSON self.catalogIndex;
            }
            ''
              mkdir -p $out/share/hinteros/terms $out/share/hinteros/readme
              jq --sort-keys . "$jsonPath" > $out/share/hinteros/catalog.json
              ${lib.concatMapStringsSep "\n" (
                f: "cp ${f} $out/share/hinteros/terms/${baseNameOf f}"
              ) termsFiles}
              ${lib.concatMapStringsSep "\n" (
                e: "cp ${e.readme.text} $out/share/hinteros/readme/${baseNameOf e.readme.text}"
              ) readmeEntries}
            '';
        default = self.packages.${system}.index;
      };

      checks.${system} = {
        pre-commit = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };
        # The index builds (so every entry is valid) and matches schema/index.schema.json.
        index =
          pkgs.runCommand "catalog-index-schema"
            {
              nativeBuildInputs = [
                pkgs.check-jsonschema
                pkgs.jq
              ];
            }
            ''
              check-jsonschema --check-metaschema ${./schema/index.schema.json}
              check-jsonschema --schemafile ${./schema/index.schema.json} \
                ${self.packages.${system}.index}/share/hinteros/catalog.json
              # Every terms file the index references exists, is non-empty and is not a TODO stub.
              idx=${self.packages.${system}.index}/share/hinteros
              for f in $(jq -r '.entries[].terms.file // empty' $idx/catalog.json); do
                test -s "$idx/$f"
                if head -c 200 "$idx/$f" | grep -q TODO; then echo "$f is a TODO stub" >&2; exit 1; fi
              done
              # Every README the index references exists, is non-empty and at most 64 KiB.
              for f in $(jq -r '.entries[].readme.file // empty' $idx/catalog.json); do
                test -s "$idx/$f"
                if [ "$(stat -c %s "$idx/$f")" -gt 65536 ]; then echo "$f is over 64 KiB" >&2; exit 1; fi
              done
              touch $out
            '';
        validator = import ./tests/validator.nix { inherit pkgs catalogLib; };
        packages = import ./tests/packages.nix {
          inherit pkgs nixpkgs;
          inherit (self) catalog;
        };
        nixos = import ./tests/nixos.nix {
          inherit pkgs nixpkgs;
          inherit (self) catalog;
          inherit (catalogLib) features;
        };
      };

      # Online check of every iconUrl, siteUrl, terms.url and readme.url (`nix run .#check-icon-urls`); kept out
      # of `nix flake check`, which stays offline. Run weekly by .forgejo/workflows/links.yml.
      apps.${system}.check-icon-urls = {
        type = "app";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "check-icon-urls";
            runtimeInputs = [
              pkgs.curl
              pkgs.jq
              pkgs.coreutils
              pkgs.gnugrep
            ];
            excludeShellChecks = [ "SC2312" ];
            text = ''
              set -- "${self.packages.${system}.index}/share/hinteros/catalog.json"
              ${builtins.readFile ./check-urls.sh}
            '';
          }
        );
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.nixfmt
          pkgs.statix
          pkgs.deadnix
          pkgs.jq
          pkgs.check-jsonschema
        ];
        shellHook = self.checks.${system}.pre-commit.shellHook;
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
