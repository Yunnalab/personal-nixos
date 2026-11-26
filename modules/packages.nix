{ pkgs, ... }:

let
  mdpdf = pkgs.callPackage ../packages/mdpdf.nix { };
  autosub = pkgs.callPackage ../packages/autosub.nix { };
  bili-notes-python = pkgs.callPackage ../packages/bili-notes-python.nix { };
in

{
  environment.systemPackages = with pkgs; [
    # ── 终端工具 ──
    zoxide
    nh
    fd
    fzf
    ripgrep
    direnv
    fish
    starship
    tree
    file
    jq
    wget
    procps
    fastfetch
    android-tools
    pnpm
    actionlint

    # ── 版本控制 ──
    git
    gnumake
    tmux
    git-lfs

    # ── 自定义脚本 ──
    mdpdf
    autosub

    # ── 梯子 ──
    # Clash Verge Rev（见 apps/nixos/clash-verge.nix）

    # ── Python ──
    bili-notes-python
    uv
    ruff
    pyright

    # ── C/C++ ──
    gcc
    clang
    clang-tools
    cmake
    ninja
    gdb
    lldb

    # ── Rust ──
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy

    # ── 文件管理 ──
    thunar
    thunar-volman
    gvfs
    lxqt.lxqt-policykit

    # ── 蓝牙 ──
    bluez
    bluez-tools
    # bluedevil / gwenview / ark / polkit-kde-agent-1 都是 plasma6 模块也会带的包，
    # 这里仍显式列出：mime.nix 按 desktop id 指向 gwenview/ark/okular，
    # home/cloudygirl/desktop.nix 的 polkit-kde-agent 用户服务也依赖它，
    # 显式声明后改 plasma6 或加 excludePackages 时不会静默消失。
    kdePackages.bluedevil

    # ── 桌面应用 ──
    # google-chrome 不在这里列：由 home/cloudygirl/apps.nix 的 programs.google-chrome
    # 提供（带 --proxy-server 等参数的 wrapper）。系统包再列一份会遮蔽/重复安装。
    kdePackages.polkit-kde-agent-1
    home-manager
    nodejs_22
    vscode
    # LibreOffice：Qt/KDE 集成版（原生 KDE 文件对话框 + Wayland）
    libreoffice-qt
    helix
    telegram-desktop

    # ── 多媒体 ──
    ffmpeg
    kdePackages.gwenview
    go-musicfox
    # 截图改走 Noctalia（`noctalia msg screenshot-region/fullscreen/window`，
    # 截图键位在 home/cloudygirl/config/umbriel/config.toml），不再安装 flameshot。

    # ── 阅读/文档 ──
    marktext
    # PDF 主力阅读器。plasma6 模块本来就会带上它，这里显式声明以免日后被
    # excludePackages 波及而悄悄消失（mime.nix 把 application/pdf 指向它）
    kdePackages.okular
    pandoc
    texliveFull
    # pdftotext：lecture-to-notes skill 的 verify_notes.py 用它做脚注同页检查
    poppler-utils
    calibre
    # anki 已移至 apps/nixos/anki-fix.nix（XWayland wrapper，修复 Wayland 下输入法重复）

    # ── 视频播放 ──
    mpv
    # kazumi 由 apps/nixos/kazumi-fix.nix 安装（wrapper 强制 LC_NUMERIC=C）

    # ── AI ──
    chatgpt
    pi-coding-agent
    mcp-nixos
    github-mcp-server

    # ── 安全工具 ──
    # AIDE / auditd / fail2ban 的服务与规则在 modules/security/；
    # 这里只列策略模块不装的命令行工具。audit 包由 nixpkgs 的
    # security.audit 模块自己装，不重复列出；策略模块也不重复列工具。
    aide
    lynis
    nmap
    clamav

    # ── 工具 ──
    ttyd
    lunar-client
    wl-clipboard
    cliphist
    goldendict-ng
    kdePackages.ark
    p7zip
    unzip
    zip
    unrar
  ];
}
