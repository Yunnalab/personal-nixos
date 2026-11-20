{ pkgs, ... }:

let
  # 端口只在这里定义：apps/clash-proxy-data.nix
  clash = import ../clash-proxy-data.nix;
in
{
  programs.steam = {
    enable = true;
    fontPackages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
    ];

    # Steam 客户端（登录、商店、创意工坊、游戏下载）读 *_proxy 环境变量，
    # 用 extraEnv 注入到 bubblewrap 包装脚本里，让客户端流量固定走 clash。
    # 注意：HTTP 代理只覆盖客户端的 TCP 流量；游戏本体与联机的 UDP
    # 不受 *_proxy 影响，需要 clash 的 TUN 模式兜底（见 apps/nixos/clash-verge.nix）。
    package = pkgs.steam.override {
      extraEnv = {
        http_proxy = clash.http;
        https_proxy = clash.http;
        all_proxy = clash.socks;
        no_proxy = clash.noProxy;
      };
    };
  };
}
