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
    swaylock-effects # 备用锁屏：平时由 Noctalia 锁屏，仅在需要时手动调用
    libnotify       # notify-send：opencode ding 插件弹系统通知用
    cmatrix
    eza         # 现代 ls（别名 ll/la/lt，不覆盖 ls 本身）
    bat         # 现代 cat（别名 bcat，不覆盖 cat 本身）
    mermaid-cli     # pi-markdown-preview 导出 PDF 时把 mermaid 图渲染为矢量图（否则降级为代码块）
    gh              # GitHub CLI：给 noctalia community-palettes 等仓库提 PR 用（gh pr create）
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
