{ pkgs, stdenv }:
stdenv.mkDerivation {
  name = "fix-ssh-auth-sock-1.0.0";
  src = ./fix-ssh-auth-sock;
  builder = pkgs.writeScript "builder.sh" ''
    source $stdenv/setup
    mkdir -p $out/bin
    cp $src $out/bin/fix-ssh-auth-sock
  '';
}
