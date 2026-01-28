{
  description = "Development environment flake for Claude";

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

        ## Additional plugins to install.
        ##
        #@ [Package]
        plugins = [
          (pkgs.fetchFromGitHub {
            owner = "JoranHonig";
            repo = "grimoire";
            rev = "4c07be52ff12142a519159b968c0f8776bfe315c";
            sha256 = "sha256-oPgDsXolVCDA4Fv4l58xoM+l08/xNfoQa3U8XkUF3J4=";
          })

          (pkgs.fetchFromGitHub {
            owner = "Archethect";
            repo = "sc-auditor";
            rev = "942cc13111cf5b0617d9de8fa4fe9bc20f1d8cc8";
            sha256 = "sha256-eYTIfnvfbutk+p20aaJos3Cabi6kGnLP2rRTs0ZdXk8=";
          })
        ];

        ## The Claude derivation.
        ##
        #@ Package
        claude = pkgs.writeShellApplication {
          name = "claude";

          text = ''
            exec ${pkgs.bubblewrap}/bin/bwrap \
              --ro-bind /nix /nix \
              --ro-bind /run /run \
              --ro-bind /etc /etc \
              --proc /proc \
              --dev /dev \
              --tmpfs /tmp \
              --tmpfs "$HOME" \
              --bind "$PWD" "$PWD" \
              --symlink /run/current-system/sw/bin /bin \
              --symlink /run/current-system/sw/bin /usr/bin \
              --symlink /run/current-system/sw/lib /usr/lib \
              --symlink /run/current-system/sw/share /usr/share \
              --setenv TMPDIR /tmp \
              --die-with-parent \
              --chdir "$PWD" \
              ${llm-agents.packages.${system}.claude-code}/bin/claude \
              ${toString (map (p: "--plugin-dir ${p}") plugins)} \
              --dangerously-skip-permissions "$@"
          '';
        };
      in
      {
        devShells.default = ext_lib.mkDevShell {
          name = "claude";
          packages = [ claude ] ++ extraPackages;
          shellHook = name: ''
            export NIX_FLAKE_NAME="''${NIX_FLAKE_NAME:+$NIX_FLAKE_NAME }agent:${name}"
          '';
        };
      }
    );
}
