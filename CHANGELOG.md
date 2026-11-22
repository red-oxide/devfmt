# Changelog

All notable changes to devfmt are recorded here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Versions are CalVer, `YY.MINOR.PATCH`: the major number is the two-digit year.
Routine flake input updates are left out.

## Unreleased

#### Fixed

- latexindent no longer leaves `indent.log` (or `.bak` backups) in the repo; it
  writes them to a temporary directory. The `fixtures` check now also fails if a
  formatter leaves any file behind.

## [26.0.0] - 2026-11-22

The first tagged release. Pin it with `github:red-oxide/devfmt/v26.0.0`. Changes
before it are listed by date.

### 2026-11-22

#### Added

- CI: `nix flake check` runs on pushes to master and on pull requests.
- Fixture tests: `tests/fixtures` holds one formatted sample per supported
  language, and the `fixtures` check fails if treefmt changes any of them. A
  second check, `fixtures-unmatched`, makes sure a file no formatter handles
  still fails.
- A weekly workflow opens an issue when an input pinned to a release tag
  (import-tree, nixfmt-rs) has a newer release, and `just outdated` lists them.

#### Fixed

- golangci-lint gets Go on its PATH. Without it, Go files failed
  `nix flake check` (and `nix fmt` where Go isn't installed) with "go command
  required, not found". Found by the new fixture tests.

#### Changed

- The flake description is "One treefmt setup for all my repos" instead of "My
  flake setup".
- import-tree is updated from v0.2.0 to v0.3.0. `lib.importTree dir` now returns
  the module function itself rather than `{ imports = [ … ]; }`; both work in
  `imports`.

### 2026-11-12

#### Added

- Apple privacy manifests (`PrivacyInfo.xcprivacy`) are formatted with xmllint,
  like the other property lists. They used to fail `nix fmt` with "no formatter
  for path".

#### Changed

- Web app manifests (`*.webmanifest`) and static-host routing files
  (`_redirects`, `_headers`) are skipped. They used to fail `nix fmt` with "no
  formatter for path".

### 2026-11-11

#### Added

- Apple property lists (`*.plist`, `*.entitlements`) are formatted with xmllint.
  A macOS entitlements file used to fail `nix fmt` with "no formatter for path".

### 2026-11-09

#### Added

- Kotlin (`.kt` and `.kts`, including Gradle build scripts) is formatted with
  ktfmt. The Gradle wrapper (`gradlew`, `gradlew.bat`, `gradle/wrapper/**`) and
  `gradle.properties` are excluded.

### 2026-11-07

#### Added

- Swift is formatted with swift-format.
- More binary assets are excluded from formatting: `*.avif`, `*.gif`, `*.ico`,
  `*.jpeg`, `*.webp`, `*.woff` and `*.woff2`. A WebP image used to fail
  `nix fmt` with "no formatter for path".
- `LICENSES/**` is excluded, so REUSE license texts stay verbatim.
- justfile with `check`, `fmt`, `fmt-check`, `show`, `update`, `update-input`
  and `verify` recipes.
- README.

### 2026-11-01

#### Fixed

- nixfmt-rs follows devfmt's nixpkgs and treefmt-nix, so flakes using devfmt
  lock one nixpkgs instead of three and don't build a second Rust toolchain.

### 2026-10-17 to 2026-10-19

#### Added

- `**/qmldir` is excluded from formatting.
- Flake inputs are updated by a scheduled workflow.

### 2026-10-12

- Initial release: a flake-parts module on treefmt-nix with formatters and
  linters for each language, a fatal `on-unmatched` rule, deno for web formats,
  `LICENSE-*` and other common excludes, and re-exported inputs.

[26.0.0]: https://github.com/red-oxide/devfmt/releases/tag/v26.0.0
