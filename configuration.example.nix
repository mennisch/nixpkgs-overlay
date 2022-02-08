# This is an example of how to use these nixpkgs and modules on a server.
{ ... } :
let
  branch = "main";
  url = "https://github.com/mennisch/nixpkgs/archive/${branch}.tar.gz";
  override = import (builtins.fetchTarball url);
  mennisch = override {};
in {
  imports = [ (mennisch.modules.init override "bastion") ];
}
