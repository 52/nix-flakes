{
  description = "Development environment flake for zig";

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

        ## Zig compiler and build system.
        ##
        #@ Package
        zig = pkgs.zig;

        ## Zig language server.
        ##
        #@ Package
        zls = pkgs.zls;

        ## LLVM debugger.
        ##
        #@ Package
        lldb = pkgs.lldb;
      in
      {
        devShell = pkgs.mkShell {
          shellHook = ''
            echo "Entering the 'github:52/nix-flakes#zig' development environment"
            echo "zig: $(${zig}/bin/zig version)"
            echo "zls: $(${zls}/bin/zls --version)"
          '';

          buildInputs = [
            zig
            zls
            lldb
          ];
        };
      }
    );
}
