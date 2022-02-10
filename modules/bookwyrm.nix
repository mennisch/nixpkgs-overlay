{ config, lib, pkgs, ... }: {
  networking = {
    firewall.allowedTCPPorts = [ 2000 ];
  };
  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [
        "bookwyrm"
      ];
      ensureUsers = [
        {
          name = "bookwyrm";
          ensurePermissions = {
            "DATABASE bookwyrm" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    postgresqlBackup = {
      databases = [ "bookwyrm" ];
      enable = true;
    };
    redis = {
      appendOnly = true;
      enable = true;
      unixSocket = "/run/redis/redis.sock";
      unixSocketPerm = 770;
    };
  };
  systemd.services = {
    bookwyrm = {
      after = [ "networking.target" "postgresql.service" "redis.service" ];
      path = [ pkgs.docker pkgs.git ];
      script = ''
        git checkout mennisch && docker compose up --remove-orphans
      '';
      serviceConfig = {
        Group = "users";
        Type = "simple";
        User = "bookwyrm";
        WorkingDirectory = "/var/lib/bookwyrm";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
  users = {
    mutableUsers = false;
    users = {
      bookwyrm = {
        extraGroups = [ "docker" "redis" ];
        group = "users";
        hashedPassword = null;
        home = "/var/lib/bookwyrm";
        isNormalUser = true;
        openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
        uid = 2000;
      };
    };
  };
  virtualisation.docker.enable = true;
}
