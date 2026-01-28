{
  description = "Development environment flake for Codex";

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

        ## The Codex derivation.
        ##
        #@ Package
        codex = pkgs.writeShellApplication {
          name = "codex";
          text = ''
            exec ${pkgs.bubblewrap}/bin/bwrap \
              --ro-bind /nix /nix \
              --ro-bind /run /run \
              --ro-bind /etc /etc \
              --proc /proc \
              --dev /dev \
              --tmpfs /tmp \
              --tmpfs "$HOME" \
              --bind-try "$HOME/.codex" "$HOME/.codex" \
              --bind "$PWD" "$PWD" \
              --symlink /run/current-system/sw/bin /bin \
              --symlink /run/current-system/sw/bin /usr/bin \
              --symlink /run/current-system/sw/lib /usr/lib \
              --symlink /run/current-system/sw/share /usr/share \
              --setenv TMPDIR /tmp \
              --die-with-parent \
              --chdir "$PWD" \
              ${llm-agents.packages.${system}.codex}/bin/codex \
              --dangerously-bypass-approvals-and-sandbox "$@"
          '';
        };
      in
      {
        devShells.default = ext_lib.mkDevShell {
          name = "codex";
          packages = [ codex ] ++ extraPackages;
          shellHook = name: ''
            export NIX_FLAKE_NAME="''${NIX_FLAKE_NAME:+$NIX_FLAKE_NAME }agent:${name}"
          '';
        };
      }
    );
}
