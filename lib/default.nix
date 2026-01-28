{
  lib,
  pkgs,
}:
rec {
  ## Create a development shell.
  ##
  ## ```nix
  ## mkDevShell {
  ##   name = "claude";
  ##   packages = [ claude-sandboxed ];
  ##   shellHook = name: "echo 'Hello from ${name}'";
  ## }
  ## ```
  ##
  #@ AttrSet -> Derivation
  mkDevShell =
    {
      ## Name of the shell.
      ##
      #@ String
      name,

      ## List of packages to include.
      ##
      #@ [Package]
      packages ? [ ],

      ## Function to generate a shell hook.
      ##
      #@ String -> String
      shellHook ? (_: ""),
    }:
    pkgs.mkShell {
      inherit name packages;
      shellHook = shellHook name;
    };

  ## Create a set of shells for different variants.
  ##
  ## ```nix
  ## mkDevShells {
  ##   default = "stable";
  ##   variants = { stable = pkgs.rust-stable; };
  ##   packages = [ pkgs.openssl ];
  ##   shellHook = variant: "echo 'Hello from ${variant}'";
  ## }
  ## ```
  ##
  #@ AttrSet -> AttrSet
  mkDevShells =
    {
      ## Name of the variant to use by default.
      ##
      #@ String
      default,

      ## Set of variants to generate shells for.
      ## Each attribute maps a variant name to its package.
      ##
      #@ AttrSet
      variants,

      ## List of packages to include in all variants.
      ## These are installed alongside the variant-specific package.
      ##
      #@ [Package]
      packages ? [ ],

      ## Function to generate a shell hook.
      ##
      #@ String -> String
      shellHook ? (_: ""),
    }:
    let
      ## Creates a development shell for a variant.
      ##
      #@ String -> Package -> Derivation
      mkShell =
        name: variant:
        mkDevShell {
          inherit name shellHook;
          packages = [ variant ] ++ packages;
        };

      ## Set of generated shells.
      ## This does not include the default alias.
      ##
      #@ AttrSet
      shells = lib.mapAttrs mkShell variants;
    in
    shells // { default = shells.${default}; };
}
