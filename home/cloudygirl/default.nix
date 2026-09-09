{ noctalia, zen-browser, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit noctalia zen-browser; };
    users.cloudygirl = import ./home.nix;
    backupFileExtension = ".bak";
  };
}
