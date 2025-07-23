{
  description = "A collection of nix development enviroments";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
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
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        # Shell used by 'nix develop', see: https://nix.dev/manual/nix/2.17/command-ref/new-cli/nix3-develop
        devShell = pkgs.mkShell {
          buildInputs = builtins.attrValues {
            inherit (pkgs)
              nixfmt-rfc-style
              deadnix
              statix
              nixd
              ;
          };
          shellHook = ''
            echo "Entering the 'github:52/nix-flakes development environment'"
          '';
        };
      }
    );
}
