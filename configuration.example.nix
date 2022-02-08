# This is an example of how to use these nixpkgs and modules on a server.
{ ... } :
let
  override = import (builtins.fetchGit {
    url = "git@github.com:mennisch/nixpkgs.git";
    ref = "main";
  });
  mennisch = override {};
in {
  imports = [ (mennisch.modules.init override "<HOST>") ];
}
