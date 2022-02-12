{ lib, modulesPath, pkgs, ... }: {
  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };
  nixpkgs.config.allowUnfree = true;
  system.autoUpgrade = {
    allowReboot = true;
    enable = true;
  };
}
