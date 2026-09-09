{ ... }:

{
  imports = [
    ./shell.nix
    ./apps.nix
    ./mime.nix
    ./desktop.nix
    ./packages.nix
  ];

  home.stateVersion = "26.05";

  # npm / cargo 全局安装目录加入 PATH。
  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.cargo/bin"
  ];
}
