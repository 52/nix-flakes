{
  description = "Development environment flake for node";

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

        ## Available Node.js versions.
        ##
        #@ [String]
        defaultVersions = [
          "20"
          "22"
          "24"
        ];

        ## Additional packages to install.
        ##
        #@ [Package]
        extraPackages = with pkgs; [
          typescript
          typescript-language-server
        ];

        ## Node.js package for each version.
        ##
        #@ AttrSet
        runtimes = lib.genAttrs defaultVersions (version: pkgs."nodejs_${version}");
      in
      {
        devShells = ext_lib.mkDevShells {
          default = "24";
          variants = runtimes;
          packages = extraPackages;
          shellHook = version: ''
            export NIX_FLAKE_NAME="node:${version}"
            echo "node: $(node --version)"
            echo "npm:  $(npm --version)"
            echo "tsc:  $(tsc --version)"
          '';
        };
      }
    );
}
