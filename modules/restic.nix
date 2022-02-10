{ config, lib, pkgs, ... }: let
  cfg = config.services;
in lib.mkMerge [
  {
    environment.systemPackages = [ pkgs.restic ];
    users.groups.restic.gid = 994;
  }
  (lib.mkIf cfg.postgresql.enable
    {
      services.restic.backups.postgresql = {
        environmentFile = "/var/lib/restic/environment";
        passwordFile = "/var/lib/restic/repository-passphrase";
        paths = [ "/var/backup/postgresql" ];
        repository = "s3:s3.amazonaws.com/mennisch-restic";
        timerConfig.OnCalendar = "hourly";
        user = "postgres";
      };
      users.groups.restic.members = [ "postgres" ];
    })
  (lib.mkIf cfg.vaultwarden.enable
    {
      services.restic.backups.vaultwarden = {
        environmentFile = "/var/lib/restic/environment";
        extraBackupArgs = [
          "--exclude=/var/lib/bitwarden_rs/icon_cache"
          "--exclude=/var/lib/bitwarden_rs/sends"
        ];
        passwordFile = "/var/lib/restic/repository-passphrase";
        paths = [ "/var/lib/bitwarden_rs" ];
        repository = "s3:s3.amazonaws.com/mennisch-restic";
        timerConfig.OnCalendar = "hourly";
        user = "vaultwarden";
      };
      users.groups.restic.members = [ "vaultwarden" ];
    })
]
