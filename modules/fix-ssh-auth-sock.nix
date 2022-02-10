{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    mennisch.fix-ssh-auth-sock
  ];
  programs = {
    bash.interactiveShellInit = ''
      . fix-ssh-auth-sock
    '';
  };
}
