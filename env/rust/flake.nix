{
  description = "Development environment flake for Rust";

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

        ## Additional cargo packages.
        ##
        #@ [Package]
        cargoPackages = with pkgs; [
          cargo-flamegraph
          cargo-criterion
          cargo-show-asm
          cargo-nextest
          cargo-expand
          cargo-hack
          cargo-fuzz
        ];

        ## Additional system packages.
        ##
        #@ [Package]
        systemPackages = with pkgs; [
          pkg-config
          libclang
          openssl
          cmake
        ];

        ## List of packages to install.
        ##
        #@ [Package]
        packages = cargoPackages ++ systemPackages;

        ## Path to a local toolchain file.
        ##
        #@ Path | null
        toolchainFile = lib.findFirst builtins.pathExists null [
          "${builtins.getEnv "PWD"}/rust-toolchain.toml"
          "${builtins.getEnv "PWD"}/rust-toolchain"
        ];

        ## Available release channels.
        ##
        #@ [String]
        variants = [
          "stable"
          "nightly"
          "beta"
        ]
        ++ lib.optionals (toolchainFile != null) [
          "file"
        ];

        ## Apply extensions to a toolchain.
        ##
        #@ Derivation -> Derivation
        withExtensions = toolchain: toolchain.override { extensions = defaultExtensions; };

        ## Build a toolchain from a variant name.
        ##
        #@ String -> Derivation
        mkToolchain =
          name:
          if name == "file" then
            rust.fromRustupToolchainFile toolchainFile
          else
            withExtensions rust.${name}.latest.minimal;
      in
      {
        devShells = ext_lib.mkDevShells {
          default = "stable";
          variants = lib.genAttrs variants mkToolchain;
          packages = [ (rust.selectLatestNightlyWith (toolchain: toolchain.rustfmt)) ] ++ packages;
          shellHook = variant: ''
            export NIX_FLAKE_NAME="''${NIX_FLAKE_NAME:+$NIX_FLAKE_NAME }rust:${variant}"
            export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"
          '';
        };
      }
    );
}
