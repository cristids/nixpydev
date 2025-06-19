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

          pythonEnv = pkgs.python312.withPackages (ps: with ps; [
            debugpy
            requests
            rich
            openai
            # Add other packages here if needed
          ]);

        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              pythonEnv
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
                    gcc.cc
                  ]
                )
              }:$LD_LIBRARY_PATH

              if [ ! -d ".venv" ]; then
                echo "Creating virtual environment..."
                ${pkgs.python312.interpreter} -m venv .venv --copies
                source .venv/bin/activate
                pip install --upgrade pip
                pip install debugpy python-lsp-server[all] aider-chat flake8 openai rich requests
                if [ -f requirements.txt ]; then
                  pip install -r requirements.txt
                fi
              fi
              source .venv/bin/activate
              
              export ODBCINI=$XDG_CONFIG_HOME/odbc/odbc.ini
              export ODBCSYSINI=$XDG_CONFIG_HOME/odbc
        
              if [ ! -d "$XDG_CONFIG_HOME/odbc" ]; then
                mkdir -p $XDG_CONFIG_HOME/odbc
                # driver config
                echo "
                  [ODBC Driver 18 for SQL Server]
                  Description=Microsoft ODBC Driver 18 for SQL Server
                  Driver=$(ls -1 ${pkgs.unixODBCDrivers.msodbcsql18}/lib/*.so*)
                  " > $XDG_CONFIG_HOME/odbc/odbcinst.ini
              fi
            '';
          };
        }
      );
    };
}
