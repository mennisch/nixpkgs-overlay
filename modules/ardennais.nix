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
  imports = [
    ./avahi.nix
    ./bookwyrm.nix
    ./fix-ssh-auth-sock.nix
    ./restic.nix
    ./tmux.nix
    ./user-root.nix
    ((import ./vaultwarden.nix) {
      addr = "172.27.1.2";
      domain = "https://bw.mennisch.net";
      orgName = "mennisch";
      smtpFrom = "thinkerer@mennisch.net";
      smtpName = "thinkerer";
    })
  ];
  networking = {
    domain = "mennish.net";
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
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  programs = {
    git = {
      config.init.defaultBranch = "main";
      enable = true;
    };
  };
  services = {
    avahi = {
      interfaces = [ "eth0" ];
    };
    openssh = {
      enable = true;
      passwordAuthentication = false;
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
    users = {
      thinkerer = {
        extraGroups = [ "wheel" ];
        group = "users";
        hashedPassword = "$6$V.wyLwsIRXgOnfOn$P/.IxvGts/LkW6VtGazZyK1nfXPyt8slpvSBSoWBwKpqh8a7vSbdZMuO3p4S3h3SZFLV.PFHESXejWuV.MqzG0";
        isNormalUser = true;
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlMoUDAszgQS6UX5jGi+ON0gtxwbwM6gb4nkFEwchJF thinkerer@mennisch.net" ];
        uid = 1000;
      };
    };
  };
}
