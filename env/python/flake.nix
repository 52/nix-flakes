{
  description = "Development environment flake for python";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit (nixpkgs) lib;

        pkgs = import nixpkgs {
          inherit system;
        };

        ext_lib = import ../../lib {
          inherit lib pkgs;
        };

        ## Available Python versions.
        ##
        #@ [String]
        defaultVersions = [
          "311"
          "312"
          "313"
        ];

        ## Additional packages to install.
        ##
        #@ [Package]
        extraPackages = with pkgs; [
          ruff
          ty
          uv
        ];

        ## Common libraries needed by python.
        ##
        #@ [Package]
        libs = with pkgs; [
          stdenv.cc.cc.lib
          glib
          zlib
        ];

        ## Python package for each version.
        ##
        #@ AttrSet
        runtimes = lib.genAttrs defaultVersions (version: pkgs."python${version}");
      in
      {
        devShells = ext_lib.mkDevShells {
          default = "312";
          variants = runtimes;
          packages = extraPackages;
          shellHook = version: ''
            export SHELL="${pkgs.bashInteractive}/bin/bash"
            export NIX_FLAKE_NAME="python:${version}"

            export UV_PYTHON="${runtimes.${version}}/bin/python"
            export UV_PYTHON_DOWNLOADS="never"

            ${lib.optionalString pkgs.stdenv.isLinux ''
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libs}:$LD_LIBRARY_PATH"
            ''}

            PKGS=(python uv ty ruff)
            echo "Environment:"
            for pkg in "''${PKGS[@]}"; do
              printf "  %-12s →  %s\n" "$pkg" "$($pkg --version)"
            done
          '';
        };
      }
    );
}
