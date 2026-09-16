{
  description = "NixOS configuration for nixos";

  inputs = {
    # 跟随 nixos-unstable。
    # 注：登录界面键盘失灵与 Qt/SDDM 无关（曾误判为 Qt 6.11.2），真因是内核
    # 6.18.52 的 hid-asus 回归，见 devices/nixos/hardware-tweaks.nix 里的说明。
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
    };
  };

  outputs = { self, nixpkgs, home-manager, noctalia, zen-browser, ... }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit noctalia zen-browser; };
        modules = [
          home-manager.nixosModules.home-manager
          ./devices/nixos/configuration.nix
          ./devices/nixos/fonts.nix
          ./home/cloudygirl
        ];
      };
    };
}
