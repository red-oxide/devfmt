_: {
  perSystem =
    { lib, pkgs, ... }:
    {
      treefmt.programs = {
        gofmt.enable = true;
        gofumpt.enable = true;
        goimports.enable = true;
        golangci-lint = {
          enable = true;
          # golangci-lint loads packages through the `go` command, which isn't
          # on PATH in `nix flake check`'s sandbox (or for anyone without Go
          # installed). Use the Go it was built with.
          package = pkgs.symlinkJoin {
            name = "golangci-lint-with-go";
            paths = [ pkgs.golangci-lint ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/golangci-lint \
                --prefix PATH : ${lib.makeBinPath [ (pkgs.golangci-lint.go or pkgs.go) ]}
            '';
            meta.mainProgram = "golangci-lint";
          };
        };
      };
    };
}
