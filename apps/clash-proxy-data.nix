# Clash Verge Rev 本地混合端口（HTTP 与 SOCKS5 共用）的纯数据，不是模块。
#
# 谁在用（改端口时只需要改这里，然后 rebuild）：
#   apps/nixos/steam.nix                  Steam 客户端的 *_proxy
#   apps/nixos/docker.nix                 Docker daemon 的 proxies
#   apps/home/chrome.nix                  Chrome 的 --proxy-server
#   apps/home/chatgpt-proxy.nix           ChatGPT 代理入口
#   home/cloudygirl/shell.nix             Fish 的 proxy 函数
#
# 放在 apps/ 根目录而不是 apps/nixos/：NixOS 侧和 Home Manager 侧都用它。
#
# 端口本身在 Clash Verge Rev 面板「设置 → 端口」里配（混合端口），
# 这里必须与面板里的值一致，否则上面这几个消费方会连不上。
let
  host = "127.0.0.1";
  port = 7897;
in
{
  inherit host port;
  http = "http://${host}:${toString port}";
  socks = "socks5://${host}:${toString port}";
  # 本机回环不走代理（ChatGPT 的本地 app-server IPC、Docker daemon 等）
  noProxy = "localhost,127.0.0.1,::1";
}
