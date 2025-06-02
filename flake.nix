{
  description = "Shared Python dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] f;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              python312
              git
              unixODBC
              unixODBCDrivers.msodbcsql18
              stdenv.cc.cc
              ruff
              pyright
            ];

            shellHook = ''
              export LD_LIBRARY_PATH=${
                pkgs.lib.makeLibraryPath (
                  with pkgs;
                  [
                    zlib zstd stdenv.cc.cc curl openssl attr libssh bzip2
                    libxml2 acl libsodium util-linux xz systemd
                    unixODBC unixODBCDrivers.msodbcsql18 libkrb5 libuuid
                  ]
                )
              }:$LD_LIBRARY_PATH

              if [ ! -d ".venv" ]; then
                echo "Creating virtual environment..."
                ${pkgs.python312.interpreter} -m venv .venv --copies
              fi
              source .venv/bin/activate
              pip install debugpy python-lsp-server[all] aider-chat flake8 openai rich requests
              if [ -f requirements.txt ]; then
                pip install -r requirements.txt
              fi
            '';
          };
        }
      );
    };
}
