mennisch-override: host:
{ pkgs, ... }: {
  imports = [ (./. + "/${host}.nix") ];
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      mennisch = mennisch-override { inherit pkgs; };
    };
  };
}
