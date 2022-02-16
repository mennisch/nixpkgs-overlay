{ config, lib, pkgs, ... }: {
  programs.git = {
    config = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
    enable = true;
  };
}
