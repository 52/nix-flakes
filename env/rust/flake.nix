{
  description = "Development environment flake for rust";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit (nixpkgs) lib;

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        ext_lib = import ../../lib {
          inherit lib pkgs;
        };

        ## Rust binaries from the rust-overlay.
        ##
        #@ AttrSet
        rust = pkgs.rust-bin;

        ## Toolchain extensions to include.
        ##
        #@ [String]
        defaultExtensions = [
          "rust-analyzer"
          "rust-src"
          "clippy"
        ];

        ## Available release channels.
        ##
        #@ [String]
        defaultChannels = [
          "stable"
          "nightly"
          "beta"
        ];

        ## Additional packages to install.
        ##
        #@ [Package]
        extraPackages = with pkgs; [
          cargo-flamegraph
          cargo-criterion
          cargo-show-asm
          cargo-nextest
          cargo-expand
          cargo-hack
          cargo-fuzz
        ];

        ## Toolchains for each release channel.
        ##
        #@ AttrSet
        toolchains = lib.genAttrs defaultChannels (channel: rust.${channel}.latest.minimal);

        ## Apply extensions to a toolchain.
        ##
        #@ Derivation -> Derivation
        withExtensions = toolchain: toolchain.override { extensions = defaultExtensions; };
      in
      {
        devShells = ext_lib.mkDevShells {
          default = "stable";
          variants = lib.mapAttrs (_: withExtensions) toolchains;
          packages = [ (rust.selectLatestNightlyWith (toolchain: toolchain.rustfmt)) ] ++ extraPackages;
          shellHook = version: ''
            export NIX_FLAKE_NAME="rust:${version}"
            PKGS=(rustc cargo rust-analyzer rustfmt)
            echo "Environment:"
            for pkg in "''${PKGS[@]}"; do
              printf "  %-12s →  %s\n" "$pkg" "$($pkg --version)"
            done
          '';
        };
      }
    );
}
