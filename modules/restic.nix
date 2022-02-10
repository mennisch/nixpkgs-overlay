{ config, lib, pkgs, ... }: let
  cfg = config.services;
  defaults = {
    environmentFile = "/var/lib/restic/environment";
    passwordFile = "/var/lib/restic/repository-passphrase";
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--keep-yearly 75"
    ];
    repository = "s3:s3.amazonaws.com/mennisch-restic";
    timerConfig.OnCalendar = "hourly";
  };
in lib.mkMerge [
  {
    environment.systemPackages = [ pkgs.restic ];
    users.groups.restic.gid = 994;
  }
  (lib.mkIf cfg.postgresql.enable
    {
      services.restic.backups.postgresql = defaults // {
        paths = [ "/var/backup/postgresql" ];
        user = "postgres";
      };
      users.groups.restic.members = [ "postgres" ];
    })
  (lib.mkIf cfg.vaultwarden.enable
    {
      services.restic.backups.vaultwarden = defaults // {
        extraBackupArgs = [
          "--exclude=/var/lib/bitwarden_rs/icon_cache"
          "--exclude=/var/lib/bitwarden_rs/sends"
        ];
        paths = [ "/var/lib/bitwarden_rs" ];
        user = "vaultwarden";
      };
      users.groups.restic.members = [ "vaultwarden" ];
    })
]
