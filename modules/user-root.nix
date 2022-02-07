{ ... }: {
  services.openssh.permitRootLogin = "prohibit-password";
  users.users.root = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlMoUDAszgQS6UX5jGi+ON0gtxwbwM6gb4nkFEwchJF thinkerer@mennisch.net" ];
  };
}
