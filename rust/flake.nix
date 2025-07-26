{
  description = "Development environment flake for rust";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
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

        ## Rust binaries from the rust-overlay.
        ##
        #@ AttrSet
        rust = pkgs.rust-bin;

        ## Finds a toolchain file in the current directory.
        ##
        #@ Path | null
        findToolchainFile = lib.findFirst builtins.pathExists null [
          "${builtins.getEnv "PWD"}/rust-toolchain.toml"
          "${builtins.getEnv "PWD"}/rust-toolchain"
        ];

        ## Extensions to include in all toolchains.
        ##
        #@ [String]
        defaultExtensions = [
          "rust-analyzer"
          "rust-src"
          "clippy"
        ];

        ## Build a toolchain configuration from a file.
        ##
        ## ```nix
        ## mkToolchain {
        ##   file = ./rust-toolchain.toml;
        ##   extensions = [ "rust-src" ];
        ## }
        ## ```
        ##
        #@ AttrSet -> Derivation
        mkToolchain =
          {
            ## Path to the toolchain file.
            ##
            #@ Path | null
            file,

            ## Additional extensions to include.
            ##
            #@ [String]
            extensions ? [ ],
          }:
          let
            ## Base toolchain configuration, uses stable as fallback.
            ##
            #@ Derivation
            base = if file != null then rust.fromRustupToolchainFile file else rust.stable.latest.minimal;

            ## Merged list of all required extensions.
            ##
            #@ [String]
            mergedExtensions = lib.unique (defaultExtensions ++ extensions ++ (base.extensions or [ ]));
          in
          base.override { extensions = mergedExtensions; };

        ## Toolchain derivation built from the configuration file.
        ##
        #@ Derivation
        toolchain = mkToolchain {
          file = findToolchainFile;
          extensions = [ ];
        };

        ## Additional cargo extensions to include.
        ##
        #@ [Package]
        cargo = with pkgs; [
          cargo-flamegraph
          cargo-criterion
          cargo-show-asm
          cargo-nextest
          cargo-expand
          cargo-hack
          cargo-fuzz
        ];
      in
      {
        devShell = pkgs.mkShell {
          shellHook = ''
            echo "Entering the 'github:52/nix-flakes#rust development environment'"
            echo "rustc:         $(${toolchain}/bin/rustc --version)"
            echo "cargo:         $(${toolchain}/bin/cargo --version)"
            echo "rust-analyzer: $(${toolchain}/bin/rust-analyzer --version)"
          '';

          packages = [
            toolchain
          ]
          ++ lib.optional (!builtins.elem "rustfmt" (toolchain.extensions or [ ])) (
            rust.selectLatestNightlyWith (toolchain: toolchain.rustfmt)
          )
          ++ cargo;
        };
      }
    );
}
