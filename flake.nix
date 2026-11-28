# SPDX-FileCopyrightText: 2026 Chris Palmer <chris@red-oxide.org>
# SPDX-License-Identifier: MIT

{
  description = "One treefmt setup for all my repos";

  # No flake inputs: everything is pinned with tack in .tack/pins.toml
  # (`tack update` to move pins, `tack add` to add one). Using devfmt doesn't
  # need tack; the resolver in .tack/default.nix reads the lock.
  #
  # A tack project that pins devfmt can override its pins through
  # `tackOverrides`. A flake can't `follows` them, but doesn't need to: devfmt
  # formats with the calling flake's pkgs, nixfmt-rs included, so devfmt's own
  # nixpkgs is only fetched for its own checks.
  outputs =
    { self, ... }@args:
    let
      pins = (import ./.tack) { overrides = args.tackOverrides or { }; };
      # Flake-style inputs, the way flake-parts expects them.
      devfmtInputs =
        removeAttrs pins [
          "__functor"
          "_meta"
          "_patched"
        ]
        // {
          inherit self;
        };

      sharedModule = {
        imports = [
          devfmtInputs.treefmt-nix.flakeModule
          devfmtInputs.flake-parts.flakeModules.modules
          (devfmtInputs.import-tree ./nix)
        ];

        perSystem =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            # Built with the calling flake's pkgs from nixfmt-rs' own package
            # definition (the pin is a plain source tree, not a flake).
            treefmt.programs.nixfmt.package = pkgs.callPackage "${devfmtInputs.nixfmt-rs}/nix/package.nix" { };

            # A minimal shell so `nix develop` and direnv's `use flake` work in
            # every repo; a repo's own devShells.default replaces it.
            devShells.default = lib.mkDefault (
              pkgs.mkShellNoCC {
                packages = [
                  config.treefmt.build.wrapper
                  pkgs.just
                ];
              }
            );
          };
      };

      mkFlake =
        args@{ inputs, ... }:
        userModule:
        devfmtInputs.flake-parts.lib.mkFlake args (
          { ... }:
          {
            systems = import devfmtInputs.systems;

            imports = [
              sharedModule
              (if builtins.isList userModule then { imports = userModule; } else userModule)
            ];

            perSystem =
              { system, ... }:
              {
                _module.args.pkgs = inputs.nixpkgs.legacyPackages.${system};
              };
          }
        );
    in
    # devfmt's own outputs, built the way it builds everyone else's (which also
    # sets pkgs: flake-parts can't find nixpkgs among a tack flake's inputs).
    mkFlake { inputs = devfmtInputs; } {
      imports = [
        ./tests/fixtures.nix
        ./tests/reuse.nix
      ];

      flake = {
        flakeModules.default = sharedModule;

        lib = {
          inherit mkFlake;
          importTree = devfmtInputs.import-tree;
        };
      };

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        {
          formatter = config.treefmt.build.wrapper;

          # The default shell plus tack, for working on devfmt's pins.
          devShells.default = pkgs.mkShellNoCC {
            packages = [
              config.treefmt.build.wrapper
              pkgs.just
              devfmtInputs.tack.packages.${system}.tack
            ];
          };
        };
    };
}
