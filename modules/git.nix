{ ... }: {
  programs.git = {
    config = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
    enable = true;
  };
}
