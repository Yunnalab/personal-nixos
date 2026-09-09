{
  description = "NixOS configuration for nixos";

  inputs = {
    # 固定到 Qt 6.11.1 的 commit（避免 Qt 6.11.2 导致 SDDM Wayland greeter 键盘失灵的回归）。
    # 待 Qt 6.11.3 / nixpkgs 修复后可恢复为 nixos-unstable。
    nixpkgs.url = "github:NixOS/nixpkgs/0e251e24a4f24e036a084b6b4b2d2491af4167f4";

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
