{ ... }:

# Home Manager 侧的逐应用适配入口，由 home/cloudygirl/home.nix 导入。
# 选项空间是 Home Manager，不能导入 apps/nixos/ 里的模块。
{
  imports = [
    ./chrome.nix
    ./chatgpt-proxy.nix
  ];
}
