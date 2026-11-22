# Checks for devfmt itself, not part of the module other flakes import.
_: {
  perSystem =
    { config, pkgs, ... }:
    let
      # The same setup treefmt-nix's own check uses: a writable copy of the
      # fixtures, committed to a fresh git repository so treefmt walks it the
      # way it walks a real project.
      setup = ''
        export HOME=$TMPDIR
        cat > "$HOME/.gitconfig" <<EOF
        [user]
          name = Nix
          email = nix@localhost
        [init]
          defaultBranch = main
        EOF
        cp -r ${./fixtures} "$TMPDIR/project"
        chmod -R u+w "$TMPDIR/project"
        cd "$TMPDIR/project"
        export LANG=C.UTF-8 LC_ALL=C.UTF-8
      '';
    in
    {
      checks = {
        # One sample per supported language, already formatted: every formatter
        # and linter has to run and leave them unchanged, and leave no files
        # behind (logs, backups). A nixpkgs bump that breaks or changes one
        # formatter fails here, before downstream repos.
        fixtures =
          pkgs.runCommandLocal "treefmt-fixtures"
            {
              nativeBuildInputs = [
                pkgs.gitMinimal
                config.treefmt.build.wrapper
              ];
            }
            ''
              ${setup}
              git init --quiet
              git add .
              git commit --quiet -m init
              treefmt --no-cache
              status=$(git status --porcelain --untracked-files=all)
              if [ -n "$status" ]; then
                echo "$status"
                git --no-pager diff
                echo "treefmt changed the fixtures or left files behind" >&2
                exit 1
              fi
              touch $out
            '';

        # A file no formatter handles has to fail (`on-unmatched = "fatal"`).
        fixtures-unmatched =
          pkgs.runCommandLocal "treefmt-fixtures-unmatched"
            {
              nativeBuildInputs = [
                pkgs.gitMinimal
                config.treefmt.build.wrapper
              ];
            }
            ''
              ${setup}
              echo unmatched > unmatched.devfmt-fixture
              git init --quiet
              git add .
              git commit --quiet -m init
              if treefmt --no-cache >"$TMPDIR/log" 2>&1; then
                cat "$TMPDIR/log"
                echo "treefmt accepted a file no formatter handles" >&2
                exit 1
              fi
              cat "$TMPDIR/log"
              grep -q 'no formatter for path.*unmatched\.devfmt-fixture' "$TMPDIR/log"
              touch $out
            '';
      };
    };
}
