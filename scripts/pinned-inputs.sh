#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Chris Palmer <chris@red-oxide.org>
# SPDX-License-Identifier: MIT

# List flake inputs pinned to a release tag (such as `v0.2.0` or `0.5.3`) that
# have a newer release upstream. `nix flake update` never moves these, so they
# have to be bumped by hand in flake.nix.
#
# Prints one line per outdated input: `input repository current latest`.
# Pre-release tags (anything with a suffix such as `-rc1`) are ignored.
set -euo pipefail

lock=${1:-flake.lock}

jq -r '
  .nodes
  | to_entries[]
  | .value.original as $o
  | select($o.type == "github" and (($o.ref // "") | test("^v?[0-9]+(\\.[0-9]+)*$")))
  | "\(.key) \($o.owner)/\($o.repo) \($o.ref)"
' "$lock" |
  while read -r input repo current; do
    # Only compare against tags written the same way, with or without a `v`.
    prefix=
    [[ $current == v* ]] && prefix=v
    latest=$(
      git ls-remote --tags --refs "https://github.com/$repo" |
        sed 's|.*refs/tags/||' |
        grep -E "^${prefix}[0-9]+(\.[0-9]+)*$" |
        sort -V |
        tail -n 1
    ) || true
    if [[ -n $latest && $latest != "$current" ]] &&
      [[ $(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -n 1) == "$latest" ]]; then
      echo "$input $repo $current $latest"
    fi
  done
