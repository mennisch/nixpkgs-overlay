{ config, lib, pkgs, ... }: {
  environment.systemPackages = [ pkgs.execline ];
}
