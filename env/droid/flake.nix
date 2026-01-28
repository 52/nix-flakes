{
  description = "Development environment flake for Droid";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    llm-agents.url = "github:numtide/llm-agents.nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      llm-agents,
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

        ## Additional packages to install.
        ##
        #@ [Package]
        extraPackages = with pkgs; [
          ollama
        ];

        ## The Droid derivation.
        ##
        #@ Package
        droid = pkgs.writeShellApplication {
          name = "droid";
          text = ''
            exec ${pkgs.bubblewrap}/bin/bwrap \
              --ro-bind /nix /nix \
              --ro-bind /run /run \
              --ro-bind /etc /etc \
              --proc /proc \
              --dev /dev \
              --tmpfs /tmp \
              --tmpfs "$HOME" \
              --bind-try "$HOME/.factory" "$HOME/.factory" \
              --bind "$PWD" "$PWD" \
              --symlink /run/current-system/sw/bin /bin \
              --symlink /run/current-system/sw/bin /usr/bin \
              --symlink /run/current-system/sw/lib /usr/lib \
              --symlink /run/current-system/sw/share /usr/share \
              --setenv TMPDIR /tmp \
              --die-with-parent \
              --chdir "$PWD" \
              ${llm-agents.packages.${system}.droid}/bin/droid "$@"
          '';
        };
      in
      {
        devShells.default = ext_lib.mkDevShell {
          name = "droid";
          packages = [ droid ] ++ extraPackages;
          shellHook = name: ''
            export NIX_FLAKE_NAME="''${NIX_FLAKE_NAME:+$NIX_FLAKE_NAME }agent:${name}"
          '';
        };
      }
    );
}
