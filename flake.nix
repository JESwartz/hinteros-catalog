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
      catalogLib = import ./lib { inherit (nixpkgs) lib; };
    in
    {
      # Entry format implementation (validator, normalizer, index), pure: needs only `lib`.
      lib = catalogLib;

      # Every entry, validated and normalized: { <id> = entry; }. Evaluating it throws with every
      # problem if any entry is invalid. Metadata is plain data; `app`, `nixos` and `packages`
      # are functions the system repo calls with its own pkgs.
      catalog = catalogLib.load ./apps;

      # The Store index as a value (what the index package writes).
      catalogIndex = catalogLib.mkIndex self.catalog;

      packages.${system} = {
        # $out/share/hinteros/catalog.json: the system repo installs it, so a box finds the
        # index of its running generation at /run/current-system/sw/share/hinteros/catalog.json.
        index =
          pkgs.runCommand "hinteros-catalog-index"
            {
              nativeBuildInputs = [ pkgs.jq ];
              passAsFile = [ "json" ];
              json = builtins.toJSON self.catalogIndex;
            }
            ''
              mkdir -p $out/share/hinteros
              jq --sort-keys . "$jsonPath" > $out/share/hinteros/catalog.json
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
              nativeBuildInputs = [ pkgs.check-jsonschema ];
            }
            ''
              check-jsonschema --check-metaschema ${./schema/index.schema.json}
              check-jsonschema --schemafile ${./schema/index.schema.json} \
                ${self.packages.${system}.index}/share/hinteros/catalog.json
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
        };
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
