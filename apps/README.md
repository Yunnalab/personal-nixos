# apps/ — 逐应用适配（软件联网设置 + 上游未修 bug 的本地处理）

这里只放**单个软件**层面的适配，系统级服务、策略、环境变量留在 `modules/`。
判断标准：如果一条配置去掉之后只影响某一个应用，就属于这里。

## 两类内容

1. **软件的网络设置**：代理客户端本体、某个应用怎么走 Clash。
   共同来源是 `clash-proxy-data.nix`（纯数据，两侧共用，**不要**加进任何 `imports`）。
2. **上游未修 bug 的本地处理**：`*-fix.nix` wrapper 与 `nixpkgs-overrides.nix` 里的 overlay，
   每处都写了原因和"上游修好后怎么删"。

不属于这里：应用本体的一般配置（Firefox、Rime、Thunar 动作 → `home/cloudygirl/apps.nix`），
系统软件包清单 → `modules/packages.nix`，网络身份/防火墙 → `devices/nixos/configuration.nix`
与 `modules/networking.nix`。

## 目录

```text
apps/
├── clash-proxy-data.nix     纯数据：Clash 主机/端口/URL 的唯一定义处，两侧共用
├── nixos/default.nix        NixOS 侧入口（configuration.nix 导入它）
│   ├── clash-verge.nix      Clash Verge Rev：serviceMode + TUN、内核 capabilities、残留清理
│   ├── steam.nix            Steam 本体 + 客户端流量钉到 Clash（extraEnv）
│   ├── docker.nix           Docker 服务 + daemon 拉镜像走 Clash
│   ├── qq-fix.nix           QQ：Wayland 原生模式剪贴板不通 → 强制 XWayland
│   ├── anki-fix.nix         Anki：QtWebEngine 拼音被提交两次 → QT_QPA_PLATFORM=xcb
│   ├── kazumi-fix.nix       Kazumi：libmpv 要求 LC_NUMERIC=C，否则所有源解析失败
│   └── nixpkgs-overrides.nix 对上游 nixpkgs 包的最小 overlay 修补
└── home/default.nix         Home Manager 侧入口（home/cloudygirl/home.nix 导入它）
    ├── chrome.nix           Chrome：固定走 Clash 混合端口
    └── chatgpt-proxy.nix    ChatGPT 的第二个（代理）启动入口
```

`nixos/` 与 `home/` 的选项空间不同，互相不能导入（NixOS 模块用 `virtualisation.*`
这类选项，Home Manager 模块用 `programs.*`/`xdg.*`）。
