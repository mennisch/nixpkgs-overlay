{ config, lib, pkgs, ... }: {
  networking = {
    firewall.allowedTCPPorts = [ 8000 ];
  };
  services = {
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
    vaultwarden = {
      config = {
        DATABASE_URL = "postgresql:///vaultwarden";
        ROCKET_PORT = 8000;
      };
      dbBackend = "postgresql";
      enable = true;
    };
  };
}
