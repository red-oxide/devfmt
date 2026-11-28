# SPDX-FileCopyrightText: 2026 Chris Palmer <chris@red-oxide.org>
# SPDX-License-Identifier: MIT

set dotenv-load := false

dev := if env("IN_NIX_SHELL", "") == "" { "nix develop --command " } else { "" }

# List available recipes
default:
    @just --list

# Check flake outputs and evaluation
check:
    nix flake check

# Format Nix and other configured files
fmt:
    nix fmt

# Check formatting without modifying files (the flake's treefmt check, run on a copy)
fmt-check:
    nix build --no-link ".#checks.$(nix eval --impure --raw --expr builtins.currentSystem).treefmt"

# Show the flake's outputs
show:
    nix flake show

# Update the pins (tack): all, or the pins named
update *names:
    {{ dev }}tack update {{ names }}

# Check formatting and the flake
verify: fmt-check check

# Show how far each pin is behind upstream, without updating
outdated *names:
    {{ dev }}tack look {{ names }}
