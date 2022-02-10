{ config, lib, pkgs, ... }: let
  zt = config.services.zerotierone;
in {
  services = {
    avahi = {
      enable = true;
      nssmdns = true;
      interfaces =
        if zt.enable then
          [ "ztuze32mv7" ]
        else
          [];
      publish = {
        addresses = true;
        domain = true;
        enable = true;
      };
    };
  };
}
