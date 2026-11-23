# SPDX-FileCopyrightText: 2026 Chris Palmer <chris@red-oxide.org>
# SPDX-License-Identifier: MIT

_: {
  perSystem =
    { lib, pkgs, ... }:
    {
      treefmt.programs = {
        latexindent = {
          enable = true;
          # latexindent writes indent.log, and backups when it changes a file,
          # into the directory it runs from, which leaves untracked files in the
          # repo. Point its cruft directory at a temporary one instead.
          package = pkgs.writeShellApplication {
            name = "latexindent";
            text = ''
              cruft=$(mktemp -d)
              trap 'rm -rf "$cruft"' EXIT
              ${lib.getExe pkgs.texlivePackages.latexindent} --cruft="$cruft/" "$@"
            '';
          };
        };
        texfmt.enable = true;
      };
    };
}
