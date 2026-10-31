{ noctalia, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit noctalia; };
    users.cloudygirl = import ./home.nix;
    backupFileExtension = ".bak";
  };
}
