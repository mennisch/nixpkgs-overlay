{ ... } : {
  services.ssmtp = {
    authUser = "AKIATT5PUYZJGUQEGJEE";
    authPassFile = "/var/lib/ssmtp/password";
    enable = true;
    domain = "mennisch.net";
    hostName = "email-smtp.us-east-1.amazonaws.com:587";
    root = "thinkerer@mennisch.net";
    useTLS = true;
    useSTARTTLS = true;
  };
  users.groups.ssmtp = {};
}
