# This is an example of how to use these nixpkgs and modules on a server.
{ ... } :
let
  mennisch-override = import (builtins.fetchTarball {
    url = "https://github.com/mennisch/nixpkgs/archive/main.tar.gz";
    sha256 = "1rbgzzhcv42yrngkxlcx8z6sdv65sy4qk3xz6ls04x9s7ghrhm5d";
  });
  mennisch = mennisch-override {};
in {
  imports = [ (mennisch.modules.init mennisch-override "HOST") ];
}
