{ lib, modulesPath, ... }: {
  boot.cleanTmpDir = true;
  documentation.nixos.enable = false;
  ec2.hvm = true;
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    ./avahi.nix
    ./deploy-key.nix
    ./fix-ssh-auth-sock.nix
    ./git.nix
    ./nix.nix
    ./starship.nix
    ./system-packages.nix
    ./tmux.nix
  ];
  networking = {
    domain = "mennisch.net";
    firewall.allowedTCPPorts = [ 80 443 ];
    hostName = "bastion";
    hosts = {
      "172.27.1.1" = [ "bastion.local" ];
      "172.27.1.2" = [ "ardennais.local" ];
    };
  };
  programs.ssh.extraConfig = ''
    Host *.local
      ForwardAgent yes
  '';
  security.acme = {
    acceptTerms = true;
    certs."mennisch.net".extraDomainNames = [
      "books.mennisch.net"
      "books2.mennisch.net"
      "bw.mennisch.net"
    ];
    email = "thinkerer@mennisch.net";
  };
  services = {
    avahi.interfaces = [ "ztuze32mv7" ];
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
            proxyPass = "http://ardennais.local:2000";
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
      listenAddresses = [ { addr = "172.27.1.1"; port = 22; } ];
      # this is mkForce, because this is also set in amazon-image.nix
      permitRootLogin = lib.mkForce "no";
    };
    zerotierone = {
      enable = true;
      joinNetworks = [ "9f77fc393e410b81" ];
    };
  };
  swapDevices = [ { device = "/swapfile"; size = 1024; } ];
  system.stateVersion = "21.11";
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
