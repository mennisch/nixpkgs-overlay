override: host:
{ pkgs, ... }: {
  imports = [ (./. + "/${host}.nix") ];
  nix.extraOptions = ''
    tarball-ttl = 0
  '';
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      mennisch = override { inherit pkgs; };
    };
  };
}
