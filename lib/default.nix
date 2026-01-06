{
  lib,
  pkgs,
}:
{
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

      ## Set of variants to gernerate shells for.
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
      ## Creates a development shell.
      ##
      #@ String -> Package -> Derivation
      mkShell = name: variant: pkgs.mkShell {
        packages = [variant] ++ packages;
        shellHook = shellHook name;
      };

      ## Set of generated shells.
      ## This does not include the default alias.
      ##
      #@ AttrSet
      shells = lib.mapAttrs mkShell variants;
    in
    shells // { default = shells.${default}; };
}
