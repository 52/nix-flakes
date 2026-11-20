{
  description = "Development environment flake for Lean";

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
          lean4

          ## Formatter and linter.
          ## See: https://github.com/jcreinhold/lean-fmt
          (stdenv.mkDerivation rec {
            pname = "lean-fmt";
            inherit (lean4) version;

            src = fetchFromGitHub {
              owner = "jcreinhold";
              repo = pname;
              tag = "v${version}";
              hash = "sha256-jIgeAE5km36uFre/EPymroFNSt2ixM7v7qrM13QBD7g=";
            };

            nativeBuildInputs = [
              lean4
            ];

            buildPhase = ''
              lake build lean-fmt
            '';

            installPhase = ''
              install -Dm755 .lake/build/bin/lean-fmt $out/bin/lean-fmt
            '';
          })
        ];
      in
      {
        devShells.default = ext_lib.mkDevShell {
          name = "lean";
          inherit packages;
          shellHook = name: ''
            export NIX_FLAKE_NAME="''${NIX_FLAKE_NAME:+$NIX_FLAKE_NAME }${name}:${pkgs.lean4.version}"
          '';
        };
      }
    );
}
