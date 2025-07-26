{
  description = "HR Application Python/Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python312Full;
        pythonPackages = python.withPackages (ps: with ps; [
          pip setuptools wheel virtualenv
        ]);
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonPackages
            pkgs.postgresql
            pkgs.openssl
            pkgs.libffi
            pkgs.zlib
            pkgs.curl
            pkgs.gcc
          ];
          shellHook = ''
            export LD_LIBRARY_PATH=${
                pkgs.lib.makeLibraryPath (
                    with pkgs;
                    [
                        zlib zstd stdenv.cc.cc curl openssl attr libssh bzip2
                        libxml2 acl libsodium util-linux xz systemd
                        libkrb5 libuuid gcc.cc
                    ]
                )
            }:$LD_LIBRARY_PATH


            export PIP_DISABLE_PIP_VERSION_CHECK=1
            export PYTHONPATH=$PWD
          
            if [ ! -d .venv ]; then
              echo "[flake] Creating Python virtual environment in .venv..."
              python -m venv .venv
            fi
          
            source .venv/bin/activate
            echo "[flake] .venv activated. Installing requirements-dev.txt if needed..."
            pip install --upgrade pip
            pip install -r requirements-dev.txt
          '';
        };
      }
    );
}
