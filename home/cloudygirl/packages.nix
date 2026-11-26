{ lib, pkgs, ... }:

{
  # 保持这些显式安装的包位于程序模块自动添加的包之后。
  home.packages = lib.mkAfter (with pkgs; [
    # niri 会话的 XWayland 由它提供（config/niri/config.kdl 里有 xwayland-satellite 段）；
    # Umbriel 自带 Xwayland，不用它，但两个会话并存，所以保留。
    xwayland-satellite
    btop
    kitty
    swaylock-effects # 备用锁屏：平时由 Noctalia 锁屏，仅在需要时手动调用
    libnotify       # notify-send：opencode ding 插件弹系统通知用
    cmatrix
    eza         # 现代 ls（别名 ll/la/lt，不覆盖 ls 本身）
    bat         # 现代 cat（别名 bcat，不覆盖 cat 本身）
    mermaid-cli     # pi-markdown-preview 导出 PDF 时把 mermaid 图渲染为矢量图（否则降级为代码块）
    gh              # GitHub CLI：给 noctalia community-palettes 等仓库提 PR 用（gh pr create）
    universal-android-debloater # UAD-ng（Next Generation）：免 root 精简安卓设备自带应用，命令 uad-ng
    # element-desktop 由 apps/home/element.nix 提供（带 --password-store 的 wrapper，见该文件）
  ]);
}
