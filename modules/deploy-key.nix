{ config, pkgs, ... }: {
  programs.ssh.extraConfig = ''
    Host deploy.github.com
      Hostname github.com
      IdentityFile "/etc/nixos/deploy-key"
  '';
}
