# SPDX-FileCopyrightText: 2026 Chris Palmer <chris@red-oxide.org>
# SPDX-License-Identifier: MIT

_: {
  perSystem.treefmt = {
    settings.formatter.taplo.options = [
      "fmt"
      "-o"
      "align_entries=true"
      "-o"
      "reorder_keys=true"
    ];

    programs.taplo.enable = true;
  };
}
