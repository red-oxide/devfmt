<!--
SPDX-FileCopyrightText: 2026 Chris Palmer <chris@red-oxide.org>
SPDX-License-Identifier: MIT
-->

# devfmt

One formatting setup for all my repos: a [flake-parts](https://flake.parts)
module built on [treefmt-nix](https://github.com/numtide/treefmt-nix), with
formatters and linters for the languages I use and a strict rule that every file
in a repo is formatted by something or explicitly excluded.

A flake that uses it gets `nix fmt` to format the whole tree, and a `treefmt`
check in `nix flake check` that fails when anything isn't formatted.

## Using it

Add devfmt as an input and build the flake with `devfmt.lib.mkFlake`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devfmt.url = "github:red-oxide/devfmt";
  };

  outputs =
    inputs:
    inputs.devfmt.lib.mkFlake { inherit inputs; } {
      imports = [ (inputs.devfmt.lib.importTree ./nix) ];
    };
}
```

`github:red-oxide/devfmt` follows master. To pin a release, use its tag, such as
`github:red-oxide/devfmt/v26.0.0`; see the [changelog](CHANGELOG.md).

devfmt pins its own inputs with [tack](https://github.com/manic-systems/tack)
rather than flake inputs, so there is nothing to `follows`, and nothing needs
to: it formats with your flake's `pkgs`, nixfmt-rs included, so devfmt's own
nixpkgs is never fetched.

### With tack

In a repo that pins with tack, pin devfmt like any other flake and pass it to
`mkFlake` with the rest of your pins (see
[rebar](https://github.com/red-oxide/rebar) for a full example):

```toml
[all_follow]
nixpkgs = "nixpkgs"

[inputs.nixpkgs]
url = "gh:nixos/nixpkgs/nixos-unstable"

[inputs.devfmt]
url = "gh:red-oxide/devfmt"
```

devfmt's pins are recomposable, so `[all_follow]` or a pin's `follows` reaches
into them like into a flake's inputs.

Then:

```sh
nix fmt                 # format everything
nix flake check         # includes checks.<system>.treefmt, run on a copy
```

### What it provides

| Output | What it is |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib.mkFlake args module` | flake-parts' `mkFlake` with devfmt included, `systems` from [nix-systems/default](https://github.com/nix-systems/default), and `pkgs` taken from _your_ `nixpkgs` input. `module` can be one module or a list of them. |
| `lib.importTree dir` | [import-tree](https://github.com/denful/import-tree): every `.nix` file under `dir` as a flake-parts module. Files there must be modules; paths containing `/_` (such as `nix/_options.nix`) are skipped, for plain Nix helpers. |
| `flakeModules.default` | The module itself, to add to a flake that already uses flake-parts: `imports = [ inputs.devfmt.flakeModules.default ];`. |
| `formatter.<system>` | devfmt's own treefmt wrapper, for formatting devfmt. |

Flakes using the module get `formatter.<system>` (for `nix fmt`) and
`checks.<system>.treefmt` from treefmt-nix's defaults. Turn either off with
`perSystem.treefmt.flakeFormatter = false` or `flakeCheck = false`.

### Dev shell and direnv

Flakes using the module also get a minimal `devShells.<system>.default` (the
treefmt wrapper and `just`). Define your own `devShells.default` to replace it.

Since every repo using devfmt has a dev shell, this `.envrc` works anywhere
(with [nix-direnv](https://github.com/nix-community/nix-direnv) for caching):

```sh
# shellcheck shell=bash
use flake
watch_dir nix
```

`watch_dir nix` reloads the shell when a file loaded through `importTree ./nix`
changes, not just `flake.nix` and `flake.lock`. treefmt runs shellcheck on
`.envrc`, which needs the `shell=bash` directive.

## Formatters

treefmt runs every formatter that matches a file, in priority order.

| Files | Formatters |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Nix | deadnix, statix, nixf-diagnose, then nixfmt ([nixfmt-rs](https://github.com/Mic92/nixfmt-rs)) |
| Rust | rustfmt |
| C, C++ | clang-format, clang-tidy |
| Go | gofmt, gofumpt, goimports, golangci-lint |
| Shell, fish | shellcheck, fish_indent |
| Swift | swift-format |
| Kotlin (`.kt`, `.kts`) | ktfmt |
| QML | qmlformat |
| TOML | taplo, with aligned entries and sorted keys |
| justfiles | `just --fmt` |
| LaTeX | latexindent, texfmt |
| XML, property lists (`.plist`, `.entitlements`) | xmllint |
| Markdown | deno fmt, then mdformat |
| JSON, JSONC, YAML, CSS, SCSS, Sass | deno fmt |
| HTML | djlint (Tera profile), which also lints |

### Every file must match

`on-unmatched` is `fatal`: a file no formatter handles fails `nix fmt` and the
check, so new file types can't slip in unformatted. These are excluded
everywhere:

- `LICENSE`, `LICENSE-*`, and `LICENSES/**` (license texts, which
  [REUSE](https://reuse.software) keeps verbatim)
- `.git`, `.gitattributes`, `.gitignore`, `**/.gitkeep`
- images and fonts: `*.avif`, `*.gif`, `*.ico`, `*.jpeg`, `*.jpg`, `*.png`,
  `*.svg`, `*.webp`, `*.woff`, `*.woff2`
- the Gradle wrapper and settings: `gradlew`, `gradlew.bat`,
  `gradle/wrapper/**`, `gradle.properties`
- `*.patch`, `**/qmldir`, `secrets/**`
- the files [tack](https://github.com/manic-systems/tack) writes itself:
  `.tack/default.nix`, `.tack/pins.lock.json`, `.tack/.gitignore`
  (`.tack/pins.toml` is still formatted)

To exclude more in a project, add to the list (it merges with devfmt's):

```nix
perSystem.treefmt.settings.global.excludes = [ "vendor/**" ];
```

Other treefmt-nix options work the same way, for example
`perSystem.treefmt.programs.<name>.enable` to add a formatter.

## Working on devfmt

```sh
just            # list the recipes
just fmt        # nix fmt
just verify     # check formatting (on a copy), then nix flake check
just update     # tack update: move the pins (all, or the ones named)
just outdated   # tack look: how far each pin is behind, without updating
```

`nix flake check` also runs every formatter over
[`tests/fixtures`](tests/fixtures), one already formatted sample per language,
and fails if any of them changes; and it checks that a file no formatter handles
still fails. CI runs it on every push to master and every pull request.

Inputs are pinned with tack in [`.tack/pins.toml`](.tack/pins.toml), and a daily
workflow runs `tack update` and commits the lock. import-tree and nixfmt-rs
follow their release tags (`tag = "v{version}"` and `"{version}"`), so the
update moves them to a new release and nothing in between. The dev shell has
`tack`; `tack add` adds a pin.

nixfmt-rs is a plain source pin, not a flake: devfmt builds its
`nix/package.nix` with the calling flake's `pkgs`, so it brings no nixpkgs or
Rust toolchain of its own.

## License

[MIT](LICENSE).
