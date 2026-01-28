{
  description = "Development environment flake for Starknet";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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

        ## Packages to install.
        ##
        #@ [Package]
        packages = with pkgs; [
          ## Scarb toolchain.
          ## See: https://github.com/software-mansion/scarb
          (stdenv.mkDerivation rec {
            pname = "scarb";
            version = "2.15.2";

            src = fetchurl {
              url = "https://github.com/software-mansion/scarb/releases/download/v${version}/scarb-v${version}-x86_64-unknown-linux-gnu.tar.gz";
              sha256 = "sha256-r+DBYJy2ls5V56tAhY9BoGvpqTZ/iVq3iu/zGck1Isg=";
            };

            buildInputs = [
              stdenv.cc.cc.lib
            ];

            nativeBuildInputs = [
              autoPatchelfHook
            ];

            sourceRoot = "scarb-v${version}-x86_64-unknown-linux-gnu";

            installPhase = ''
              install -Dm755 bin/scarb $out/bin/scarb
            '';
          })

          ## Universal Sierra Compiler.
          ## See: https://github.com/software-mansion/universal-sierra-compiler
          (stdenv.mkDerivation rec {
            pname = "universal-sierra-compiler";
            version = "2.7.0";

            src = fetchurl {
              url = "https://github.com/software-mansion/universal-sierra-compiler/releases/download/v${version}/universal-sierra-compiler-v${version}-x86_64-unknown-linux-gnu.tar.gz";
              sha256 = "sha256-iPFA/HnVpHPsFVDiNqP+Ud7vt3iPBxK+iAdqFP5N4p4=";
            };

            buildInputs = [
              stdenv.cc.cc.lib
            ];

            nativeBuildInputs = [
              autoPatchelfHook
            ];

            sourceRoot = "universal-sierra-compiler-v${version}-x86_64-unknown-linux-gnu";

            installPhase = ''
              install -Dm755 bin/universal-sierra-compiler $out/bin/universal-sierra-compiler
            '';
          })

          ## Starknet foundry toolkit.
          ## See: https://github.com/foundry-rs/starknet-foundry
          (stdenv.mkDerivation rec {
            pname = "starknet-foundry";
            version = "0.57.0";

            src = fetchurl {
              url = "https://github.com/foundry-rs/starknet-foundry/releases/download/v${version}/starknet-foundry-v${version}-x86_64-unknown-linux-gnu.tar.gz";
              sha256 = "sha256-hg0PbFOKFbwjVgDRTQFzAYD1cHa7BVA0k7CiFVWIrTU=";
            };

            buildInputs = [
              stdenv.cc.cc.lib
            ];

            nativeBuildInputs = [
              autoPatchelfHook
            ];

            installPhase = ''
              install -Dm755 bin/snforge $out/bin/snforge
              install -Dm755 bin/sncast $out/bin/sncast
            '';
          })

        ];
      in
      {
        devShells.default = ext_lib.mkDevShell {
          name = "starknet";
          inherit packages;
          shellHook = name: ''
            export NIX_FLAKE_NAME="''${NIX_FLAKE_NAME:+$NIX_FLAKE_NAME }tools:${name}"
          '';
        };
      }
    );
}
