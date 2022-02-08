override: host:
{ pkgs, ... }: {
  imports = [ (./. + "/${host}.nix") ];
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      mennisch = override { inherit pkgs; };
    };
  };
}
