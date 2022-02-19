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
        REQUIRE_DEVICE_EMAIL = false;
        ROCKET_PORT = 8000;
        SIGNUPS_ALLOWED = false;
        SIGNUPS_VERIFY = true;
        SMTP_HOST = "email-smtp.us-east-1.amazonaws.com";
        SMTP_PORT = 587;
        SMTP_SSL = true;
      };
      dbBackend = "postgresql";
      enable = true;
      environmentFile = "/var/lib/bitwarden_rs/config";
    };
  };
}
