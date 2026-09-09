{ lib, pkgs, zen-browser, ... }:

let
  dsh-web-launch = pkgs.callPackage ../../packages/dsh-web-launch.nix { };
in
{
  # 保持这些显式安装的包位于程序模块自动添加的包之后。
  home.packages = lib.mkAfter (with pkgs; [
    xwayland-satellite
    btop
    kitty
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    dsh-web-launch
    swaylock-effects
    swayidle
    cmatrix
  ]);

  xdg.dataFile."applications/dsh-web.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=DeepSeek Harness
    Comment=DeepSeek Harness Web UI
    Comment[zh_CN]=DeepSeek Harness 网页界面
    Exec=${dsh-web-launch}/bin/dsh-web-launch
    Icon=browser
    Terminal=false
    Categories=Development;
    StartupNotify=false
  '';
}
