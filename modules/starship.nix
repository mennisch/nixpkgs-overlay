{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [ starship ];
  programs = {
    bash.interactiveShellInit = ''eval "$(starship init bash)"'';
    zsh.shellInit = ''eval "$(starship init zsh)"'';
  };
}
