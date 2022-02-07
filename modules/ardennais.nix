{ config, lib, pkgs, ... }: {
  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
      kernelModules = [ "dm-snapshot" ];
      luks.devices.secure = {
        device = "/dev/sda";
        preLVM = true;
      };
      network = {
        enable = true;
        ssh = {
          authorizedKeys = config.users.users.thinkerer.openssh.authorizedKeys.keys;
          enable = true;
          hostKeys = [
            /etc/secrets/initrd_ssh_host_ed25519_key
            /etc/secrets/initrd_ssh_host_rsa_key
          ];
          port = 222;
        };
      };
    };
    kernelPackages = pkgs.linuxPackages_rpi4;
    kernelParams = [ "console=tty1" ];
    loader = {
      generic-extlinux-compatible.enable = true;
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 4;
      };
    };
    tmpOnTmpfs = true;
  };
  environment.systemPackages = with pkgs; [
    restic
  ];
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/b90ba330-3baa-4d08-88a4-3b461bb63667";
      fsType = "ext4";
      options = [ "noatime" "nodiratime" "discard" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/e2c43ccf-a1f3-4687-ae13-de3000a11ed5";
      fsType = "ext4";
      options = [ "noatime" "nodiratime" ];
    };
    "/boot/firmware" = {
      device = "/dev/disk/by-uuid/2178-694E";
      fsType = "vfat";
      options = [ "noatime" "nodiratime" ];
    };
  };
  hardware = {
    enableRedistributableFirmware = true;
    # high-resolution display
    video.hidpi.enable = lib.mkDefault true;
  };
  import = [ ./user-root.nix ];
  networking = {
    domain = "mennish.net";
    firewall.allowedTCPPorts = [
      8000 # vaultwarden
    ];
    hostName = "ardennais";
    interfaces = {
      eth0.useDHCP = true;
      wlan0.useDHCP = true;
    };
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
  };
  nixpkgs.config.allowUnfree = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  programs = {
    bash.interactiveShellInit = ''
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
    git = {
      config.init.defaultBranch = "main";
      enable = true;
    };
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
  services = {
    avahi = {
      enable = true;
      nssmdns = true;
      interfaces = [ "eth0" "ztuze32mv7" ];
      publish = {
        addresses = true;
        domain = true;
        enable = true;
      };
    };
    openssh = {
      enable = true;
      passwordAuthentication = false;
    };
    postgresql = {
      enable = true;
      ensureDatabases = [ "vaultwarden" ];
      ensureUsers = [
        {
          name = "vaultwarden";
          ensurePermissions = {
            "DATABASE vaultwarden" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    postgresqlBackup = {
      databases = [ "vaultwarden" ];
      enable = true;
      startAt = "*-*-* *:00:00";
    };
    restic.backups = {
      postgresql = {
        environmentFile = "/var/lib/restic/environment";
        passwordFile = "/var/lib/restic/repository-passphrase";
        paths = [ "/var/backup/postgresql" ];
        repository = "s3:s3.amazonaws.com/mennisch-restic";
        timerConfig = {
          OnCalendar = "hourly";
        };
        user = "postgres";
      };
      vaultwarden = {
        environmentFile = "/var/lib/restic/environment";
        extraBackupArgs = [
          "--exclude=/var/lib/bitwarden_rs/icon_cache"
          "--exclude=/var/lib/bitwarden_rs/sends"
        ];
        passwordFile = "/var/lib/restic/repository-passphrase";
        paths = [ "/var/lib/bitwarden_rs" ];
        repository = "s3:s3.amazonaws.com/mennisch-restic";
        timerConfig = {
          OnCalendar = "hourly";
        };
        user = "vaultwarden";
      };
    };
    vaultwarden = {
      config = {
        DATABASE_URL = "postgresql:///vaultwarden";
        DOMAIN = "https://bw.mennisch.net";
        INVITATION_ORG_NAME = "mennisch";
        REQUIRE_DEVICE_EMAIL = false;
        ROCKET_ADDRESS = "172.27.1.2";
        ROCKET_PORT = 8000;
        SIGNUPS_ALLOWED = false;
        SIGNUPS_VERIFY = true;
        SMTP_FROM = "thinkerer@mennisch.net";
        SMTP_FROM_NAME = "thinkerer";
        SMTP_HOST = "email-smtp.us-east-1.amazonaws.com";
        SMTP_PORT = 587;
        SMTP_SSL = true;
        SMTP_USERNAME = "AKIATT5PUYZJCTPX5VVZ";
      };
      dbBackend = "postgresql";
      enable = true;
      environmentFile = "/var/lib/bitwarden_rs/environment";
    };
    zerotierone = {
      enable = true;
      joinNetworks = [ "9f77fc393e410b81" ];
    };
  };
  swapDevices = [
    { device = "/dev/disk/by-uuid/9b597be9-73ea-4adb-9e0f-b29e134a60a9"; }
  ];
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
  # There's a bug in 21.11 where nscd does not start on boot causing avahi name
  # resolution to fail.  This is the fix from the PR
  # (https://github.com/NixOS/nixpkgs/pull/154620).  It should get released
  # around 2021-01-25.
  systemd.services.ncsd = {
    before = [ "nss-lookup.target" "nss-user-lookup.target" ];
    wants = [ "nss-lookup.target" "nss-user-lookup.target" ];
    wantedBy = [ "multi-user.target" ];
  };
  users = {
    mutableUsers = false;
    groups = {
      restic = {
        gid = 994;
        members = [
          "postgres"
          "vaultwarden"
        ];
      };
      vaultwarden = {
        gid = 995;
      };
    };
    users = {
      thinkerer = {
        extraGroups = [ "wheel" ];
        group = "users";
        hashedPassword = "$6$V.wyLwsIRXgOnfOn$P/.IxvGts/LkW6VtGazZyK1nfXPyt8slpvSBSoWBwKpqh8a7vSbdZMuO3p4S3h3SZFLV.PFHESXejWuV.MqzG0";
        isNormalUser = true;
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlMoUDAszgQS6UX5jGi+ON0gtxwbwM6gb4nkFEwchJF thinkerer@mennisch.net" ];
        uid = 1000;
      };
      vaultwarden = {
        uid = 997;
      };
    };
  };
}
