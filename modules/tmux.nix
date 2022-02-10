{ config, lib, pkgs, ... }: {
  programs = {
    tmux = {
      baseIndex = 1;
      enable = true;
      escapeTime = 0;
      historyLimit = 10000;
      keyMode = "emacs";
      newSession = true;
      terminal = "screen-256color";
      extraConfig = ''
        # bindings
        unbind C-b
        bind r source-file ~/.tmux.conf
        bind 'C-\' send-prefix
        # session
        set -g prefix 'C-\'
        set -g set-titles on
        set -g update-environment "DISPLAY WINDOWID"
        # window
        setw -g xterm-keys on
        setw -g monitor-activity on
      '';
    };
  };
}
