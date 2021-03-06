# Return a set of nix derivations and optionally the special attributes `lib`, `modules`
# and `overlays`.
#
# Do NOT import <nixpkgs>. Instead, take pkgs as an argument.
#
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short commands such
# as:
#   nix-build -A mypackage
{ pkgs ? import <nixpkgs> {} }:
{
  # The `lib`, `modules`, and `overlay` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  fix-ssh-auth-sock = pkgs.callPackage ./pkgs/fix-ssh-auth-sock {};
}
