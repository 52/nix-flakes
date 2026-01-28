{
  description = "Development environment flake for EVM";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crytic.url = "github:crytic/crytic.nix";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      crytic,
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

        ## Packages to install.
        ##
        #@ [Package]
        packages = with pkgs; [
          foundry

          ## Crytic security tools.
          ## See: https://github.com/crytic
          crytic.packages.${system}.solc-select
          crytic.packages.${system}.echidna
          crytic.packages.${system}.slither
          crytic.packages.${system}.medusa
          crytic.packages.${system}.mewt

          ## Aderyn static analyzer.
          ## See: https://github.com/cyfrin/aderyn
          (stdenv.mkDerivation rec {
            pname = "aderyn";
            version = "0.6.8";

            src = fetchurl {
              url = "https://github.com/Cyfrin/aderyn/releases/download/${pname}-v${version}/aderyn-x86_64-unknown-linux-gnu.tar.xz";
              sha256 = "sha256-/9bKZYli4hGjrIIcZG9pyOFL8bEAHL/gkbzUU1ppHkY=";
            };

            buildInputs = [
              stdenv.cc.cc.lib
            ];

            nativeBuildInputs = [
              autoPatchelfHook
            ];

            installPhase = ''
              install -Dm755 aderyn $out/bin/aderyn
            '';
          })

        ];
      in
      {
        devShells.default = ext_lib.mkDevShell {
          name = "evm";
          inherit packages;
          shellHook = name: ''
            export NIX_FLAKE_NAME="''${NIX_FLAKE_NAME:+$NIX_FLAKE_NAME }tools:${name}"
          '';
        };
      }
    );
}
