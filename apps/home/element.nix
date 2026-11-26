{ pkgs, ... }:

# Element Desktop（Electron）在本机（Umbriel/niri 这类非 KDE/GNOME 合成器）下的两个必需修补，
# 都在这个 wrapper 里。
#
# ① 白屏：Electron 的 safeStorage 只按 XDG_CURRENT_DESKTOP 猜后端——
#    `*KDE*` → kwallet，`*GNOME*` → gnome-libsecret，其它一律退化成 basic_text
#    （弱加密）。Umbriel 的 XDG_CURRENT_DESKTOP=umbriel（niri 时代是 niri）正好命中「其它」
#    分支，所以即使
#    gnome-keyring 已经在跑并占着 org.freedesktop.secrets（见
#    `busctl --user list | grep secrets`），Electron 也不会用它，Element 只弹一个
#    「System unsupported」模态框，看起来就是白屏（登录页其实已经渲染好了）。
#    解决：显式 --password-store=gnome-libsecret。
#    三个都不能选：
#      * 改 XDG_CURRENT_DESKTOP=GNOME —— 会污染整个会话，让所有 GTK/Qt 应用走 GNOME 分支；
#      * 点对话框里的「Use weaker encryption」—— token 会用 basic_text 落盘；
#      * 加 --disable-gpu —— 与本问题无关（日志里 Vulkan/Wayland 那条只是噪音）。
#
# ② 连不上 homeserver：matrix.org 直连不通（表现为 `Invalid /versions response`）。
#    本入口固定走 Clash 混合端口。
#
# 为什么不做成「直连」+「代理」两个面板条目（像 ChatGPT 那样）：
#   Element 同样是单实例应用（已有实例时新进程只把旧窗口唤到前台就退出），
#   两个条目必须配一套「先停旧实例、等锁释放、再带参数启动」的 shell 逻辑。
#   而 Element 在本机直连根本用不了，直连条目没有存在意义，所以这里只保留
#   一个固定走代理的入口。真需要直连时把下面的 --proxy-server 和 env 去掉即可。
let
  # 端口只在这里定义：apps/clash-proxy-data.nix
  clash = import ../clash-proxy-data.nix;

  element = pkgs.symlinkJoin {
    name = "element-desktop";
    paths = [ pkgs.element-desktop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/element-desktop"
      makeWrapper "${pkgs.element-desktop}/bin/element-desktop" "$out/bin/element-desktop" \
        --add-flags "--password-store=gnome-libsecret" \
        --add-flags "--proxy-server=${clash.http}" \
        --add-flags "--proxy-bypass-list=localhost;127.0.0.1;[::1]" \
        --set http_proxy "${clash.http}" \
        --set https_proxy "${clash.http}" \
        --set all_proxy "${clash.socks}" \
        --set HTTP_PROXY "${clash.http}" \
        --set HTTPS_PROXY "${clash.http}" \
        --set ALL_PROXY "${clash.socks}" \
        --set no_proxy "${clash.noProxy}" \
        --set NO_PROXY "${clash.noProxy}"
    '';
  };
in
{
  home.packages = [ element ];
}
