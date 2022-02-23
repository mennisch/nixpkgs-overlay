{ pkgs, ... } : {
  environment.systemPackages = with pkgs; [
    # needed for database migrations
    php
  ];
  networking = {
    firewall.allowedTCPPorts = [ 80 ];
  };
  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [ "tt_rss" ];
      ensureUsers = [
        {
          name = "tt_rss";
          ensurePermissions = {
            "DATABASE tt_rss" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    postgresqlBackup = {
      databases = [ "tt_rss" ];
      enable = true;
      startAt = "*-*-* *:00:00";
    };
    tt-rss = {
      database = {
        createLocally = false;
      };
      email = {
        fromAddress = "thinkerer@mennisch.net";
        fromName = "thinkerer";
      };
      extraConfig = ''
        putenv('TTRSS_LOG_SENT_MAIL=true');
      '';
      enable = true;
      registration = {
        enable = true;
      };
      selfUrlPath = "https://reader.mennisch.net";
    };
  };
  users.users.tt_rss = {
    extraGroups = [ "ssmtp" ];
  };
}
