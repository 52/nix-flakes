{
  description = "Development environment flake for Java";

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

        ## Available JDK versions.
        ##
        #@ [String]
        defaultVersions = [
          "8"
          "17"
          "21"
          "25"
        ];

        ## Additional packages to install.
        ##
        #@ [Package]
        extraPackages = with pkgs; [
          jdt-language-server
          gradle
        ];

        ## JDK package for each version.
        ##
        #@ AttrSet
        runtimes = lib.genAttrs defaultVersions (version: pkgs."jdk${version}");
      in
      {
        devShells = ext_lib.mkDevShells {
          default = "25";
          variants = runtimes;
          packages = extraPackages;
          shellHook = variant: ''
            export JAVA_HOME="${runtimes.${variant}}/lib/openjdk"
            export NIX_FLAKE_NAME="''${NIX_FLAKE_NAME:+$NIX_FLAKE_NAME }java:${variant}"
          '';
        };
      }
    );
}
