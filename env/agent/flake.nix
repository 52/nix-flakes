{
  description = "Development environment flake for AI agents";

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
          config.allowUnfree = true;
        };

        ext_lib = import ../../lib {
          inherit lib pkgs;
        };

        ## Available AI Agents.
        ##
        #@ [String]
        defaultAgents = [
          "opencode"
        ];

        ## Additional packages to install.
        ##
        #@ [Package]
        extraPackages = with pkgs; [ ];

        ## Package for each agent.
        ##
        #@ AttrSet
        agents = lib.genAttrs defaultAgents (agent: pkgs.${agent});
      in
      {
        devShells = ext_lib.mkDevShells {
          default = "opencode";
          variants = agents;
          packages = extraPackages;
          shellHook = agent: ''
            echo "Agent: ${agent}"
          '';
        };
      }
    );
}
