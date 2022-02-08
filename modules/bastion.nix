{ lib, modulesPath, pkgs, ... }: let
  fixSshAuthSock = ''
      function check-ssh-auth-sock() {
        timeout 1 ssh-add -l >& /dev/null
      }

      function find-ssh-auth-sock() {
        for sock in $(find /tmp -wholename '/tmp/ssh-*/agent.*' -user $USER 2>/dev/null); do
          if SSH_AUTH_SOCK="$sock" check-ssh-auth-sock; then
            echo $sock
            return 0
          fi
        done
      }

      function fix-ssh-auth-sock() {
        if ! check-ssh-auth-sock; then
          new_sock=$(find-ssh-auth-sock)
          if [ ! -z $new_sock ]; then
            export SSH_AUTH_SOCK="$new_sock"
          fi
        fi
      }
    '';
in {
  boot.cleanTmpDir = true;
  documentation.nixos.enable = false;
  ec2.hvm = true;
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
  networking = {
    domain = "mennisch.net";
    firewall.allowedTCPPorts = [ 80 443 ];
    hostName = "bastion";
    hosts = {
      "172.27.1.1" = [ "bastion.local" ];
      "172.27.1.2" = [ "ardennais.local" ];
      "172.27.1.3" = [ "aurochs.local" ];
    };
  };
  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };
  nixpkgs.config.allowUnfree = true;
  programs = {
    bash = {
      interactiveShellInit = fixSshAuthSock;
    };
    git = {
      enable = true;
      config.init.defaultBranch = "main";
    };
    ssh.extraConfig = ''
      Host *.local
        ForwardAgent yes
    '';
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
    zsh = {
      enable = true;
      interactiveShellInit = fixSshAuthSock;
    };
  };
  security = {
    acme = {
      acceptTerms = true;
      certs."mennisch.net".extraDomainNames = [
        "books.mennisch.net"
        "bw.mennisch.net"
      ];
      email = "thinkerer@mennisch.net";
    };
  };
  services = {
    avahi = {
      enable = true;
      interfaces = [ "ztuze32mv7" ];
      nssmdns = true;
      publish = {
        addresses = true;
        domain = true;
        enable = true;
      };
    };
    nginx = {
      appendHttpConfig = ''
        # blocked IPs:
        # deny 73.177.192.154;
        allow all;

        # rate limiting: https://www.nginx.com/blog/rate-limiting-nginx/
        # allow list IPs subject to relaxed rate limit
        # map allow list IPs to 0, others to 1
        geo $limit {
          default 1;
          # allow list IPs:
          # 73.177.192.154/32 0;
        }

        # $limit_key is "" for allow list IPs, remote address for others
        map $limit $limit_key {
          0 "";
          1 $binary_remote_addr;
        }

        # allow list will match only the relaxed rate; others will match both,
        # and the more restrictive limit will apply
        limit_req_zone $limit_key          zone=limit_strict:1m  rate=20r/s;
        limit_req_zone $binary_remote_addr zone=limit_relaxed:1m rate=1000r/s;

        # Most websites have no more than 12 resources per load
        limit_req zone=limit_strict  burst=40   delay=20;
        limit_req zone=limit_relaxed burst=2000 nodelay;
        limit_req_status 429;
      '';
      enable = true;
      recommendedProxySettings = true;
      virtualHosts = {
        "books.mennisch.net" = {
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://aurochs.local:8001";
          };
          useACMEHost = "mennisch.net";
        };
        "bw.mennisch.net" = {
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://ardennais.local:8000";
          };
          useACMEHost = "mennisch.net";
        };
        "mennisch.net" = {
          enableACME = true;
          forceSSL = true;
        };
      };
    };
    openssh = {
      enable = true;
      listenAddresses = [
        {
          addr = "172.27.1.1";
          port = 22;
        }
      ];
      # this is mkForce, because this is also set in amazon-image.nix
      permitRootLogin = lib.mkForce "no";
    };
    zerotierone = {
      enable = true;
      joinNetworks = [ "9f77fc393e410b81" ];
    };
  };
  swapDevices = [
    {
      device = "/swapfile";
      size = 1024;
    }
  ];
  system = {
    autoUpgrade = {
      allowReboot = true;
      enable = true;
    };
    stateVersion = "21.11";
  };
  # There's a bug in 21.11 where nscd does not start on boot causing avahi name
  # resolution to fail.  This is the fix from the PR
  # (https://github.com/NixOS/nixpkgs/pull/154620).  It should get released
  # around 2021-01-25.
  systemd.services.nscd = {
    before = [ "nss-lookup.target" "nss-user-lookup.target" ];
    wants = [ "nss-lookup.target" "nss-user-lookup.target" ];
    wantedBy = [ "multi-user.target" ];
  };
  users = {
    mutableUsers = false;
    users = {
      root.hashedPassword = null;
      thinkerer = {
        extraGroups = [ "wheel" ];
        group = "users";
        hashedPassword = "$6$Cc3sJ4gCutlUhdZ.$5uuQLPaHm.qWY6YeSYA3tOp46ug/.pvsmFFyv4bRegStACCKonkzJU2CZBCgRjia7znJaAWnl9ZXDn3UaaqZM1";
        isNormalUser = true;
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlMoUDAszgQS6UX5jGi+ON0gtxwbwM6gb4nkFEwchJF thinkerer@mennisch.net" ];
        uid = 1000;
      };
    };
  };
  virtualisation.amazon-init.enable = false;
}
