# SPDX-FileCopyrightText: 2026 Chris Palmer <chris@red-oxide.org>
# SPDX-License-Identifier: MIT

_: {
  perSystem.treefmt = {
    settings.formatter.djlint.options = [
      "--profile=tera"
    ];

    programs = {
      deno = {
        enable = true;
        includes = [
          "*.css"
          "*.json"
          "*.jsonc"
          "*.markdown"
          "*.md"
          "*.sass"
          "*.scss"
          "*.yaml"
          "*.yml"
        ];
      };
      djlint = {
        enable = true;
        includes = [
          "*.html"
        ];
        lint = true;
      };
      mdformat.enable = true;
    };
  };
}
