{
  description = "Development environment flake for node";

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

        ## Node.js LTS version.
        ##
        #@ Package
        node = pkgs.nodejs_22;

        ## TypeScript compiler and language server.
        ##
        #@ [Package]
        ts = with pkgs; [
          typescript
          typescript-language-server
        ];
      in
      {
        devShell = pkgs.mkShell {
          shellHook = ''
            echo "Entering the 'github:52/nix-flakes#node' development environment"
            echo "node:       $(${node}/bin/node --version)"
            echo "npm:        $(${node}/bin/npm --version)" 
            echo "typescript: $(${pkgs.typescript}/bin/tsc --version)"
          '';

          packages = [ node ] ++ ts;
        };
      }
    );
}
