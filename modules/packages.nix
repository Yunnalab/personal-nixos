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
    bitwarden-cli
    android-tools
    pnpm

    # ── 版本控制 ──
    git
    gnumake
    tmux

    # ── 自定义脚本 ──
    mdpdf
    autosub

    # ── 梯子 ──
    # Clash Verge Rev（见 modules/proxy.nix）

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
    kdePackages.bluedevil

    # ── 桌面应用 ──
    kdePackages.polkit-kde-agent-1
    google-chrome
    home-manager
    nodejs_22
    vscode
    wpsoffice-cn
    helix
    telegram-desktop

    # ── 多媒体 ──
    ffmpeg
    kdePackages.gwenview
    kdePackages.elisa
    go-musicfox
    flameshot

    # ── 阅读/文档 ──
    marktext
    sioyek
    pandoc
    texliveFull
    calibre
    # anki 已移至 modules/anki-fix.nix（XWayland wrapper，修复 Wayland 下输入法重复）

    # ── 视频播放 ──
    mpv

    # ── AI ──
    codex
    opencode
    pi-coding-agent
    opencode-desktop
    mcp-nixos
    github-mcp-server

    # ── 安全工具 ──
    audit
    aide
    lynis
    nmap

    # ── 工具 ──
    ttyd
    lunar-client
    wl-clipboard
    cliphist
    qalculate-qt
    geary
    goldendict-ng
    kdePackages.ark
    p7zip
    unzip
    zip
    unrar
  ];
}
