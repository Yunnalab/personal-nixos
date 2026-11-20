{ pkgs, ... }:

# ChatGPT 桌面应用（Electron）默认直连。本模块额外提供一个「走 clash 代理」的
# 启动入口，与系统原有的 chatgpt.desktop 并存于应用面板，互不覆盖。
#
# 为什么不能只在 desktop 文件里写 env 变量：
#   ChatGPT 是单实例应用（requestSingleInstanceLock），已有实例在跑时，新进程只会
#   把旧窗口唤到前台然后自己退出，代理参数完全不会生效。所以 wrapper 必须先检查
#   旧实例是否走了代理，没走就先关掉，再带代理启动。
#
# 本入口刻意不声明 MimeType：否则会和 chatgpt.desktop 抢 http/https/codex 的默认
# 处理程序（mime.nix 里的设置）。它只用于「手动点开、这次要走代理」的场景。

let
  # 端口只在这里定义：apps/clash-proxy-data.nix
  clash = import ../clash-proxy-data.nix;
  proxyHttp = clash.http;
  proxySocks = clash.socks;
  noProxy = clash.noProxy;

  chatgpt-proxy = pkgs.writeShellApplication {
    name = "chatgpt-proxy";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      procps
      systemd
    ];
    text = ''
      # 主进程 + 渲染进程的 cmdline 都带 lib/chatgpt/ChatGPT 路径
      chatgpt_pids() {
        pgrep -f 'lib/chatgpt/ChatGPT' || true
      }

      # 主进程是唯一 cmdline 里没有 --type= 参数的那个
      main_pid() {
        for pid in $(chatgpt_pids); do
          if ! tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null | grep -q '^--type='; then
            echo "$pid"
            return 0
          fi
        done
      }

      # ChatGPT 起来后会把自身 environ 清零（安全措施），所以不能靠环境变量判断；
      # 改为看主进程命令行里有没有我们注入的 --proxy-server。
      is_proxied() {
        tr '\0' '\n' < "/proc/$1/cmdline" 2>/dev/null \
          | grep -q -- '--proxy-server=${proxyHttp}'
      }

      needs_restart=0
      pid=$(main_pid)
      if [ -n "$pid" ] && ! is_proxied "$pid"; then
        needs_restart=1
      fi

      if [ "$needs_restart" -eq 1 ]; then
        # 从应用面板正常启动的实例跑在 systemd user scope 内，按 scope 停更干净
        for pid in $(chatgpt_pids); do
          systemctl --user stop "app-org.chromium.Chromium-$pid.scope" >/dev/null 2>&1 || true
          systemctl --user stop "app-org.chromium.ChatGPT-$pid.scope" >/dev/null 2>&1 || true
        done
        pkill -f 'lib/chatgpt/ChatGPT' >/dev/null 2>&1 || true
        # 等单实例锁释放，最多 10 秒
        for _ in $(seq 1 40); do
          if [ -z "$(chatgpt_pids)" ]; then
            break
          fi
          sleep 0.25
        done
      fi

      # --proxy-server 给 Chromium 本体；环境变量给应用内部 spawn 的 node / codex CLI
      # 子进程。no_proxy 保住 localhost，否则本地 app-server 的 IPC 也会被塞进代理。
      exec env \
        http_proxy="${proxyHttp}" \
        https_proxy="${proxyHttp}" \
        all_proxy="${proxySocks}" \
        HTTP_PROXY="${proxyHttp}" \
        HTTPS_PROXY="${proxyHttp}" \
        ALL_PROXY="${proxySocks}" \
        no_proxy="${noProxy}" \
        NO_PROXY="${noProxy}" \
        ${pkgs.chatgpt}/bin/chatgpt \
        --proxy-server="${proxyHttp}" \
        --proxy-bypass-list='localhost;127.0.0.1;[::1]' \
        "$@"
    '';
  };
in
{
  home.packages = [ chatgpt-proxy ];

  xdg.desktopEntries."chatgpt-proxy" = {
    name = "ChatGPT（Clash 代理）";
    genericName = "AI assistant";
    comment = "通过 clash 端口 ${toString clash.port} 启动；会先关掉未走代理的实例";
    exec = "${chatgpt-proxy}/bin/chatgpt-proxy %U";
    icon = "chatgpt";
    terminal = false;
    categories = [
      "Utility"
      "Development"
    ];
    settings = {
      StartupNotify = "true";
      StartupWMClass = "org.chromium.Chromium";
    };
  };
}
