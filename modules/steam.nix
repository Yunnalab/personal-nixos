{ pkgs, ... }:

let
  # Steam 走 clash 代理的端口：clash-verge 的混合端口（Clash Verge Rev 设置 → 端口），
  # 与 apps.nix 的 Chrome、shell.nix 的 proxy 函数、docker-setting.nix 保持一致。
  proxyHost = "127.0.0.1";
  proxyPort = 7897;
  httpProxy = "http://${proxyHost}:${toString proxyPort}";
  socksProxy = "socks5://${proxyHost}:${toString proxyPort}";
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
    # 不受 *_proxy 影响，需要 clash 的 TUN 模式兜底（见 modules/proxy.nix）。
    package = pkgs.steam.override {
      extraEnv = {
        http_proxy = httpProxy;
        https_proxy = httpProxy;
        all_proxy = socksProxy;
        no_proxy = "localhost,127.0.0.1,::1";
      };
    };
  };
}
