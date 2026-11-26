# NixOS 系统配置

本仓库声明主机 `nixos` 的 NixOS 和 Home Manager 配置。重构目录或模块时，默认保持系统行为不变；依赖升级、服务调整和结构重构分开进行。

**文件名必须是 `AGENTS.md`**：pi / codex 这类 agent 只自动读取 `AGENTS.md`，单数的 `AGENT.md` 不会被当作指令加载。2026-11-17 已由 `AGENT.md` 改名，不要再改回去。

## 配置分层

```text
flake.nix                          输入版本与系统组装（nixpkgs / home-manager / noctalia）
├── devices/nixos/                 本机模块选择、硬件与主机策略
│   ├── configuration.nix
│   ├── hardware-configuration.nix
│   ├── fonts.nix
│   ├── boot.nix
│   ├── nvidia.nix
│   ├── hardware-tweaks.nix
│   ├── power.nix
│   ├── fan-mode.nix
│   └── README.md                  迁移检查清单
├── modules/                       系统层面的可复用模块（不含硬件细节、不含单个软件的适配）
│   ├── desktop.nix
│   ├── locale.nix
│   ├── networking.nix
│   ├── nix-settings.nix
│   ├── packages.nix
│   ├── users.nix
│   ├── shell.nix
│   ├── shell-aliases-data.nix     纯数据，不是模块
│   └── security/                  default.nix 聚合 aide / audit / hardening
├── apps/                          应用设置：软件联网设置 + 上游未修 bug 的本地处理
│   ├── README.md                  归类规则与本目录清单
│   ├── clash-proxy-data.nix       纯数据，不是模块；两侧共用的 Clash 端口
│   ├── nixos/                     default.nix 聚合（configuration.nix 导入它）
│   │   ├── clash-verge.nix        Clash Verge Rev 本体 + capabilities + 残留清理
│   │   ├── steam.nix              Steam + 客户端走 Clash 的 extraEnv
│   │   ├── docker.nix             Docker 服务 + daemon 代理
│   │   ├── qq-fix.nix、anki-fix.nix、kazumi-fix.nix
│   │   └── nixpkgs-overrides.nix  上游未修 bug 的 overlay 修补
│   └── home/                      default.nix 聚合（home.nix 导入它）
│       ├── chrome.nix             Chrome 固定走 Clash
│       └── chatgpt-proxy.nix      ChatGPT 的第二个（代理）启动入口
├── home/cloudygirl/default.nix    NixOS 与 Home Manager 的接入层
├── home/cloudygirl/home.nix       用户配置入口、会话 PATH、会话变量
│   ├── shell.nix
│   ├── apps.nix
│   ├── mime.nix
│   ├── desktop.nix
│   ├── tmux.nix
│   ├── pi-agents.nix
│   └── packages.nix
├── packages/                      自定义包构建函数（mdpdf、autosub、bili-notes-python、agent-farm）
├── home/cloudygirl/config/        被模块引用的配置源文件及未接管快照（见该目录 README.md）
├── notes/                         笔记与 Pandoc/XeLaTeX 模板（mdpdf 的模板在这里）
└── scripts/、anki/、download/、windows/
                                   辅助资料或独立工作流，不自动导入系统
```

导入关系只有两条链，没有目录自动导入：

- 系统侧：`flake.nix` → `devices/nixos/configuration.nix` 的 `imports` → `modules/*.nix` 与 `apps/nixos`（两者各自都有 `default.nix` 聚合；`modules/security/default.nix` 聚合三个子文件）。
- 用户侧：`flake.nix` → `home/cloudygirl/default.nix`（`home-manager.users.cloudygirl = import ./home.nix`）→ `home/cloudygirl/home.nix` 的 `imports` → `apps/home`。

`flake.lock` 锁定 `nixpkgs`、Home Manager 和 Noctalia 及其依赖。

## 系统模块索引

| 文件 | 职责 |
| --- | --- |
| `devices/nixos/configuration.nix` | 模块 `imports`、swap、主机名与额外开放端口、安全策略的选项值、`system.stateVersion` |
| `devices/nixos/fonts.nix` | 系统字体清单与 fontconfig 回退顺序 |
| `devices/nixos/boot.nix` | GRUB/EFI 与手动 Windows 启动项，本机专属 |
| `devices/nixos/nvidia.nix` | NVIDIA 驱动、`services.xserver.videoDrivers`、PRIME 总线号与 offload，本机专属 |
| `devices/nixos/hardware-tweaks.nix` | 华硕键盘背光、`hid-asus` 回归的内核处理，本机专属 |
| `devices/nixos/power.nix` | TLP、CPU 调速与电源策略，本机专属 |
| `devices/nixos/fan-mode.nix` | `fan-mode` 命令（四档 `powersave`/`quiet`/`balanced`/`performance`）、platform_profile 与开机恢复服务，本机专属 |
| `modules/desktop.nix` | Plasma/Umbriel 会话（Umbriel 主桌面，Plasma 备用）、greetd + noctalia-greeter、PipeWire、polkit（含 pkexec wrapper 与登录界面免密同步规则）、文件管理器服务、合成器退出超时 |
| `modules/locale.nix` | 中文区域、时区、Fcitx5 与输入法环境变量 |
| `modules/networking.nix` | NetworkManager、nm-applet 与 OpenSSH（主机名、开放端口在 `devices/nixos/configuration.nix`） |
| `modules/nix-settings.nix` | Nix 功能、substituters 顺序、unfree 策略与每周 GC |
| `modules/packages.nix` | 系统软件包清单，调用 `packages/` 里的构建函数；系统包只在这里定义 |
| `modules/users.nix` | 本地用户与基础组 |
| `modules/shell.nix` | 系统编辑器变量（`EDITOR`/`VISUAL`）与 `environment.shellAliases` |
| `modules/shell-aliases-data.nix` | 纯数据，不是模块；别名表与 eza 参数的唯一定义处（系统别名、`ll`/`la`/`lt` 与 Fish 自动列目录 hook 共用） |
| `modules/security/` | AIDE、auditd 与加固的选项定义和实现（`default.nix` 聚合） |

## 逐应用适配索引（`apps/`）

`apps/` 只收两类东西，系统级服务与主机策略不进这个目录：

1. **单个软件的联网设置**（代理客户端本体、某个应用怎么走 Clash）；
2. **上游还没修的 bug 的本地处理**（`*-fix.nix` wrapper、`nixpkgs.overlays` 修补）。

| 文件 | 职责 |
| --- | --- |
| `apps/clash-proxy-data.nix` | 纯数据，不是模块；Clash 主机/端口/URL 的唯一定义处 |
| `apps/nixos/clash-verge.nix` | Clash Verge Rev（serviceMode + TUN）、内核 capabilities、残留文件清理 |
| `apps/nixos/steam.nix` | Steam 启用、字体，以及把客户端流量钉到 Clash 的 `extraEnv` |
| `apps/nixos/docker.nix` | Docker 服务、用户组、daemon 代理与每周 autoPrune |
| `apps/nixos/qq-fix.nix`、`anki-fix.nix`、`kazumi-fix.nix` | 应用兼容性 wrapper 及安装，见「应用兼容性 wrapper」 |
| `apps/nixos/nixpkgs-overrides.nix` | 对上游包的最小 overlay 修补（pyopenjtalk-plus 测试、calibre 的 speechd 安装检查），每条都写了原因与回退条件 |
| `apps/home/chrome.nix` | Chrome 固定走 Clash 混合端口（含视频解码参数） |
| `apps/home/chatgpt-proxy.nix` | ChatGPT 的第二个（代理）启动入口，见下节 |
| `apps/home/element.nix` | Element Desktop 的 wrapper：补 `--password-store=gnome-libsecret`（否则 Niri 下白屏）+ 固定走 Clash 代理，见下节 |

`apps/nixos/` 是 NixOS 模块，`apps/home/` 是 Home Manager 模块，两边不能互相导入。

## 用户模块索引（Home Manager）

| 文件 | 职责 |
| --- | --- |
| `home/cloudygirl/home.nix` | `imports`、`sessionPath`（npm/cargo）、`PUPPETEER_EXECUTABLE_PATH` 与 `MERMAID_CLI_PATH` 两个会话变量 |
| `home/cloudygirl/shell.nix` | Fish、Starship、direnv/zoxide/fzf 集成、`restart`/`proxy` 函数、eza 自动列目录 hook |
| `home/cloudygirl/apps.nix` | 应用本体的一般配置：Firefox、Rime 数据文件、Thunar 自定义动作（Chrome 与其代理参数在 `apps/home/chrome.nix`） |
| `home/cloudygirl/mime.nix` | 全部默认打开方式，以及 KDE/Umbriel 的 `*-mimeapps.list` 兼容映射 |
| `home/cloudygirl/desktop.nix` | Noctalia Shell、umbriel/kitty/swaylock/eza 配置映射、polkit-kde-agent 用户服务 |
| `home/cloudygirl/tmux.nix` | tmux：prefix `C-a`、extended-keys（pi 换行必需）、resurrect/continuum、多 agent 工作台键位 |
| `home/cloudygirl/pi-agents.nix` | 把 `config/pi/agents/*.md` 部署成子 agent 定义，并安装 `agent-farm` |
| `home/cloudygirl/packages.nix` | 仅当前用户需要的软件包（`lib.mkAfter`，排在程序模块的包之后） |

## 纯数据文件

`modules/shell-aliases-data.nix` 与 `apps/clash-proxy-data.nix` 都**不是模块**，不要加进任何 `imports`：它们只被 `import` 取属性，NixOS 侧和 Home Manager 侧共用同一份定义。

- 别名、`ll`/`la`/`lt`、eza 自动列目录 hook 的 flag 只在 `shell-aliases-data.nix` 里改。
- Clash 的主机/端口只在 `clash-proxy-data.nix` 里改（端口要同时和 Clash Verge Rev 面板「设置 → 端口」一致）。它放在 `apps/` 根目录而不是 `apps/nixos/`，因为两侧都 import 它。当前消费方：`apps/nixos/steam.nix`、`apps/nixos/docker.nix`、`apps/home/chrome.nix`、`apps/home/chatgpt-proxy.nix`、`home/cloudygirl/shell.nix`。

## 放在哪里

- 设备特定的文件系统、硬件和主机策略放在 `devices/<name>/`；可复用的系统服务、驱动、权限或全局环境变量放在 `modules/`。显卡驱动列表（`services.xserver.videoDrivers`）、主机名、开放端口这类硬件/主机参数只在 `devices/` 里声明：NixOS 的列表选项会合并，两个模块各写一遍会得到重复项。
- **只影响单个软件的适配放 `apps/`，不要放 `modules/`**：软件的网络/代理设置、上游未修 bug 的 wrapper 与 overlay 修补都属于这一类（判据：去掉它只影响一个应用）。反过来，`apps/` 里不要写系统级服务、防火墙、全局环境变量。
- 系统通用软件包加到 `modules/packages.nix`；仅当前用户需要的软件包加到 `home/cloudygirl/packages.nix`。应用模块自动安装的包通常不需要重复添加；确实要重复列出（例如 `mime.nix` 按 desktop id 引用的 gwenview/ark/okular、`desktop.nix` 用户服务用的 polkit-kde-agent）就在旁边写清原因。反过来，`modules/security/*`、`apps/nixos/qq-fix.nix` 这类策略/包装模块也不再自己列 `environment.systemPackages`（工具统一在 `modules/packages.nix`）。Chrome 由 `apps/home/chrome.nix` 的 `programs.google-chrome` 提供，系统包不重复安装。
- 自定义命令或运行环境放在 `packages/<name>.nix`，显式声明构建依赖，再通过 `pkgs.callPackage` 安装。`mdpdf` 的模板仍位于 `notes/template/`。
- 用户应用选项放在 `home/cloudygirl/apps.nix`；桌面与用户服务放在 `home/cloudygirl/desktop.nix`；默认打开方式只在 `home/cloudygirl/mime.nix` 维护。音频与视频默认打开方式都是 `mpv`；原先的 `elisa`（音频）和 `haruna`（视频，从未安装）已不再使用。
- 应用原生配置文件放在 `home/cloudygirl/config/<app>/`，在负责该应用的模块中显式声明 `xdg.configFile` 或 `xdg.dataFile` 映射。
- 新模块需要加入相应入口的 `imports`：系统侧的 `apps/` 文件加到 `apps/nixos/default.nix`，用户侧的加到 `apps/home/default.nix`。不按目录自动导入，避免启用草稿、备份或把纯数据当成模块。

保持一文件一类职责，但不为每个选项创建一个文件。只有独立变化、复用或明显过长的功能才继续拆分；当前单主机配置不需要额外的主机框架或自定义开关体系。

## 安全策略

`devices/nixos/configuration.nix` 只写**选项值**（`security.aide`、`security.auditRules`、`security.hardening`），实现全在 `modules/security/`：

| 子模块 | 内容 |
| --- | --- |
| `aide.nix` | 生成 `/etc/aide.conf`、`aide-init`（首次建库）与 `aide-check`（按 `checkInterval` 定时检查，日志留 `logRetentionDays` 天） |
| `audit.nix` | 自定义 audit 规则写入 `/etc/audit/rules.d/nixos.rules`，并同时启用 `security.auditd`（守护进程）与 `security.audit`（规则加载） |
| `hardening.nix` | 防火墙、fail2ban、sshd 加固、sysctl、登录横幅、PAM 限制、禁用 USB 存储 |

拆包原则：**服务与策略在 `security/`，命令行工具（`aide`、`lynis`、`nmap`、`clamav`）在 `modules/packages.nix`**。`audit` 包由 nixpkgs 的 `security.audit` 模块自己安装，不要再列一遍。改完可以用下面这条确认没有重复：

```bash
nix eval --json .#nixosConfigurations.nixos.config.environment.systemPackages \
  --apply 'ps: map (p: p.name) ps' | tr ',' '\n' | sort | uniq -d
```

## 网络、端口与代理

- Clash Verge Rev 跑在 serviceMode + TUN 模式，本地混合端口 `7897`（HTTP 与 SOCKS5 共用），定义在 `apps/clash-proxy-data.nix`。
- 走代理的消费者：Chrome（`apps/home/chrome.nix`）、Steam 客户端（`apps/nixos/steam.nix` 的 `extraEnv`，只覆盖客户端 TCP；游戏 UDP 靠 TUN）、Docker daemon（`apps/nixos/docker.nix`，注意它只认小写的 `http-proxy`/`https-proxy`，且 `no-proxy` 不能写 `::1`）、Fish 的 `proxy on/off` 函数、`chatgpt-proxy`。
- 终端不读 KDE 系统代理，需要手动 `proxy on`。
- 防火墙：`22`（SSH，由 `security.hardening.allowedTCPPorts` 放行）与 `7681`（ttyd 网页终端，写在 `devices/nixos/configuration.nix`）。ttyd 只装了命令，**没有**对应的 systemd 服务，需要时自己跑 `ttyd -p 7681 <命令>`。
- `services.openssh.settings` 分两处写：`networking.nix` 负责 `PasswordAuthentication`，`security/hardening.nix` 负责其余加固项，两边合并生效。

## 应用兼容性 wrapper

`apps/nixos/` 下三个 `*-fix.nix` 都是 `symlinkJoin` + `makeWrapper`，用来遮住上游包在本机环境下的具体故障；同类但发生在包构建阶段的修补写在 `apps/nixos/nixpkgs-overrides.nix` 的 overlay 里。它们自己安装替换包，`modules/packages.nix` 里**不要**再列原包（`bin/` 冲突会让 buildEnv 直接失败）。

| 文件 | 问题 | 处理 |
| --- | --- | --- |
| `qq-fix.nix` | Wayland 原生模式下剪贴板不通 | 强制 XWayland（`--unset NIXOS_OZONE_WL`）+ 输入法变量，并改写 desktop 的 `Exec` |
| `anki-fix.nix` | QtWebEngine 编辑器走两条输入路径，拼音被提交两次 | `QT_QPA_PLATFORM=xcb`；desktop 的 `Exec=anki %f` 走 PATH，无需改写 |
| `kazumi-fix.nix` | 内置 libmpv 的 `mp_create()` 要求 `LC_NUMERIC` 是 C/POSIX，中文 locale 下返回 NULL，表现为「所有番剧源都解析失败 / 一直转圈」 | wrapper 里 `--set LC_NUMERIC C`，不动 `LC_ALL`/`LANG`，界面仍是中文 |

## 已移除的组件（勿回加）

以下是 2026-10-31 按“长期未使用”清理掉的，不要因为看到旧文档或旧缓存就重新引入（`chatgpt` 当时也在表内，2026-11-04 已重新安装，见下节「ChatGPT 的两个启动入口」）：

| 组件 | 原因 |
| --- | --- |
| Flatpak（含 `/var/lib/flatpak`、Flathub 加源 unit） | 三个 flatpak 应用与 nix 里的 `git`/`gh`/`qalculate-qt` 重复，runtime 占 2.1G |
| Zen Browser（flake input） | 一个月未启动，日常用 Chrome |
| `geary` | 邮件客户端，3 个月未打开 |
| `elisa`、`qalculate-qt`、`bitwarden-cli` | 从未启动或 3.5 个月未用 |
| `assets/login-bg.jpg` | SDDM 时代的登录背景，改用 greetd + noctalia-greeter 后无引用 |
| `sioyek` + `modules/sioyek-fix.nix`（2026-11-01） | 本机 PRIME offload + NVIDIA 环境下 Qt6/QtQuick 的 GL 上下文反复创建失败（`QOpenGLWidget: Failed to create context` / `QEGLPlatformContext: Failed to create context: 3009`），窗口能创建但从不提交缓冲区；xcb/wayland 两种后端只能交替幸存，无法长期保持。PDF 默认改为 Okular（`kdePackages.okular`），次选 calibre-ebook-viewer |

NixOS 模块与 Home Manager 模块使用不同的选项空间，不要互相直接导入。外部 flake 输入通过 `home/cloudygirl/default.nix` 的 `home-manager.extraSpecialArgs` 传给用户模块，避免依赖外层函数的隐式作用域。

## ChatGPT 的两个启动入口（2026-11-04）

`chatgpt` 本体装在 `modules/packages.nix`，由 `apps/home/chatgpt-proxy.nix` 额外提供一个**独立**的代理入口，两个条目在应用面板并存：

| 面板条目 | 来源 | 网络 |
| --- | --- | --- |
| `ChatGPT` | 包自带 `chatgpt.desktop` | 直连 |
| `ChatGPT（Clash 代理）` | `xdg.desktopEntries."chatgpt-proxy"` → `~/.local/share/applications/chatgpt-proxy.desktop` | `127.0.0.1:7897` |

旧的 `apps.nix` `chatgptProxy` wrapper 用同名 `chatgpt` 命令**遮蔽**系统命令，导致所有入口（含 MIME 关联、终端调用）都强制走代理，已不再使用。现在直连路径保持原样，代理只由新条目显式选择。

两个必须知道的实现约束，改这个模块前先看：

1. **单实例锁**：ChatGPT 是 Electron 单实例应用（`requestSingleInstanceLock`），已有实例在跑时新进程只把旧窗口唤到前台就退出，`--proxy-server` 不会生效。所以 `chatgpt-proxy` 先判断旧实例是否走代理，没走就 `systemctl --user stop` 对应 scope + `pkill`，等锁释放后再带代理启动。
2. **environ 会被清零**：ChatGPT 起来后把自身 `/proc/<pid>/environ` 全部写成 NUL，**不能**用环境变量判断“是否已走代理”。改为读主进程 cmdline（主进程 = cmdline 不含 `--type=` 的那个）里有没有 `--proxy-server=http://127.0.0.1:7897`。

代理入口刻意不声明 `MimeType`，否则会和 `chatgpt.desktop` 抢 `mime.nix` 里的 http/https/codex 默认处理程序。

## Element Desktop 的两个修补（2026-11-26）

`element-desktop` 在 `apps/home/element.nix` 里被 `symlinkJoin` 包了一层，追加两组参数：
`--password-store=gnome-libsecret` 和 Clash 代理（`--proxy-server` + `*_proxy` 环境变量）。

### ① 白屏 = keyring，不是显卡

Electron 的 `safeStorage` 只按 `XDG_CURRENT_DESKTOP` 猜后端（`*KDE*`→kwallet，
`*GNOME*`→gnome-libsecret，其余一律退化到 `basic_text`），而 Umbriel 的
`XDG_CURRENT_DESKTOP=umbriel`（niri 时代是 `niri`）落到「其余」分支，于是即使
gnome-keyring 已占着 `org.freedesktop.secrets` 也不会被用，Element 只弹「System unsupported」模态框，
看起来就是白屏（登录页其实已经渲染好，被模态框盖住）。

排错要点，别走回头路：

- 不是显卡/PRIME offload/Wayland 问题。`--ozone-platform=wayland' is not compatible with Vulkan`
  只是日志噪音，加 `--disable-gpu` 没用。
- **不要**为了这个改全局 `XDG_CURRENT_DESKTOP=GNOME`，会连带影响所有 GTK/Qt 应用。
- **不要**点对话框里的「Use weaker encryption」，token 会以 `basic_text` 落盘。
- 诊断命令：`element-desktop --enable-logging=stderr 2>&1 | grep -i safeStorage`，
  正常时应当**没有**输出；再确认后端用 `busctl --user list | grep secrets`（应为 gnome-keyring）。
  会看到一次 `Starting safeStorage migration to gnome_libsecret` + `Relaunching app...`，属正常。
- 复查实例时用 `--user-data-dir=/tmp/el-test-N` 另开一个，避免单实例锁干扰。
- 刚 `pkill` 完立刻重启可能撞上 `GPU process launch failed: error_code=1002` /
  `GPU process isn't usable. Goodbye.`，等 2~3 秒再启就没事，不是配置问题。

### ② 必须走代理

`matrix-client.matrix.org` 直连超时（Element 里的表现是 `Invalid /versions response`），
走 Clash 混合端口 200/0.3s。所以这里**只保留一个固定走代理的入口**，没做像 ChatGPT 那样的
「直连 + 代理」双条目：Element 也是单实例应用，两条目得配一套停旧实例再重启的逻辑，
而直连条目在本机根本用不了。要直连就把 `element.nix` 里的 `--proxy-server` 和 `--set *_proxy` 去掉。

验证是否真的走了代理：启动后 `ss -tnp | grep 7897` 应能看到 Element 的连接。

## 桌面合成器：Umbriel 取代 niri（2026-11-26）

主桌面从 niri 换成了 [Umbriel](https://docs.noctalia.dev/umbriel/)（noctalia-dev 的
wlroots + SceneFX 合成器）。配置抄自 `github:Lhcfl/nixos-cfg` 的 Umbriel 部分，
但**没有引入它的 `tessera` 声明式合成器模块**：本机仍是手写配置文件 + Home Manager
映射，和 niri 时代一致。

| 位置 | 变化 |
| --- | --- |
| `modules/desktop.nix` | `programs.niri.enable` → `programs.umbriel.enable`（该模块自带 umbriel、`xdg-desktop-portal-umbriel`、wayland-session 条目与 `umbriel.service`）；`defaultSession` 与 greeter 的 `session.default` 都改成 `umbriel`（greeter 按 `.desktop` 的 Name 字段**大小写不敏感**匹配，`niri`/`Niri` 时代已验证）；关机超时从 `niri.service` 挪到 `umbriel.service` |
| `home/cloudygirl/config/umbriel/config.toml` | 新的合成器配置（TOML），逐项由原来的 `config/niri/config.kdl` 翻译 |
| `home/cloudygirl/desktop.nix` | 部署 `umbriel/config.toml`；Noctalia 模板 `builtin_ids` 从 `niri` 换成 `umbriel`；激活时预先 `touch ~/.config/umbriel/noctalia.toml` |
| `home/cloudygirl/mime.nix` | `niri-mimeapps.list` → `umbriel-mimeapps.list`（Umbriel 设 `XDG_CURRENT_DESKTOP=umbriel`） |
| `home/cloudygirl/packages.nix` | 去掉 `xwayland-satellite`：Umbriel 自带 Xwayland（`general.xwayland`） |
| `config/noctalia/noctalia-base-settings-v4.json` | `customLaunchPrefix` / `launch_apps_custom_command` 改为 `umbriel msg spawn ...`，模板 id 换成 `umbriel` |

### 翻译时踩到的几处不对等

- **配置语言不同**：niri 是 KDL，Umbriel 是 TOML，没有自动迁移工具。改完用
  `umbriel config validate` 校验（会报未知 action、越界值、非法键，比 niri 的
  静默忽略友好）。`umbriel msg config-reload` 热重载，但 `general.xwayland`、
  `general.autostart`、`xwayland_*` 仍要重启会话。
- **边框不能渐变**：niri 的 `active-gradient` 无对应项，`[colors.border]` 只接受单色，
  现在用渐变中点 `#ddaa77ee` 近似。Noctalia 主题模板会覆盖成主题色。
- **截图移到 Noctalia**：`noctalia msg screenshot-region/fullscreen/window`，niri 自带的
  截图 UI（Space 保存复制、Ctrl+C 只复制）随之消失，换成 Noctalia 的截图窗口
  （保存/复制行为由 Noctalia 的截图设置决定）。
- **工作区清单**：Umbriel 的 `[output.<连接器>] workspaces` 可以是动态清单或固定数量。
  动态清单下 `workspace-switch 5` 在工作区不足 5 个时会落到最后一个，和 niri 的
  「按编号按需新建」不同；所以内屏 `eDP-1` 写死 `workspaces = 9` 保住 Mod+1..9，
  外接显示器仍是动态清单。原 niri 里的 `Mod+Shift+N { move-window-to-workspace 255; }`
  没有等价物，已去掉。
- **`[keybinds]` 是整份替换**：写了这张表就不再继承内置绑定，所以常用绑定都要列全。
  内置默认里有 `Mod+O` 开 overview、`Mod+Shift+Escape` 切快捷键直通，本机已显式保留。
- **合成器自启动列表**：`[general] autostart` 走 `/bin/sh -c`（或有 systemd 时走
  `systemd-run` scope）。不再需要 niri 里的 `systemctl --user import-environment`，
  `start-umbriel` 自己会把登录环境导入用户会话。

### 回滚

`config/niri/config.kdl` 仍然留在仓库里（`~/niri-config/config.kdl` 软链指向它），
但**不再被部署**。要回 niri：`modules/desktop.nix` 恢复 `programs.niri.enable`、把
`defaultSession`/`session.default` 改回 `niri`，`home/cloudygirl/desktop.nix` 重新映射
`niri/config.kdl` 并把 `builtin_ids` 里的 `umbriel` 换回 `niri`。

## 多 agent 工作台

- `home/cloudygirl/pi-agents.nix` 把 `home/cloudygirl/config/pi/agents/{scout,builder,reviewer}.md` 部署成 `~/.pi/agent/agents/*.md`。这些是**只读软链**，pi 的 `/subagents` 面板按 Space 写 `enabled` 会失败——要启停 agent，改源文件后 rebuild。
- `packages/agent-farm.nix` 提供 `agent-farm <仓库> <agent>...`：按 agent 拆 git worktree（分支 `agent/<名字>`），在 tmux session `agents-<仓库名>` 里各开一个窗口。agent 名只允许字母、数字、`_`、`-`。
- `home/cloudygirl/tmux.nix` 是它的后端：`extended-keys on` + `csi-u` 让 pi 能区分 Enter / Shift+Enter（否则「想换行却提交」），`allow-passthrough` 让 pi-markdown-preview 的内联图片穿过 tmux。

## 验证

改完先求值，再切换：

```bash
sudo nixos-rebuild dry-build --flake /home/cloudygirl/nixos   # 只求值、不切换
sudo nixos-rebuild switch --flake /home/cloudygirl/nixos
```

只想确认能求值（不构建、不 sudo）：

```bash
nix eval --raw .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
```

flake 只认已 tracked 的文件：新增文件必须先 `git add`（或走 `nixrs` 别名，它先 `git add -A`），
否则 dry-build 报 `Path ... is not tracked by Git`。

不切换系统、直接看 Home Manager 会生成什么，从 dry-build 输出里取那行 `home-manager-files.drv`：

```bash
nix-store --realise /nix/store/<hash>-home-manager-files.drv
# 返回真实目录，里面就是会被链接到 $HOME 的文件
```

用户侧两项配置的自检：

```bash
readlink ~/.config/eza/theme.yml     # 应指向 /nix/store/...-hm_theme.yml

# Fish 自动列目录 hook：布局是 --long --grid 的多列网格（紧凑，且带 git 标记列 -M/-N）。
# 期望 a、b 各列一次，重复 cd 到同一目录不再打印。
# 超过 50 项的目录只列前 50 项（按条目截断，不是按行），并打印「… 已省略 N 项（共 M 项，只列前 50）」。
# 必须用真实 TTY：fish -c 里 status is-interactive 为假，hook 会静默跳过。
mkdir -p /tmp/eza-hook-check/{a,b} && cd /tmp/eza-hook-check/a \
  && script -qec "fish -i -c 'cd /tmp/eza-hook-check/b; cd /tmp/eza-hook-check/b'" /dev/null
```

`--icons=auto` 由 eza 按终端宽度探测决定是否画图标，不是 `isatty`；`script` 的 pty 没有窗口尺寸时
不会画图标，这和配置无关，用 `--icons=always` 可确认图标本身正常。

## 隐私与生成物

`.gitignore` 排除本地凭据、环境文件、工具缓存、构建结果、笔记 PDF、Anki 导出、下载目录以及含个人状态的桌面快照。`windows/` 下的个人目录链接也不纳入版本控制。本地文件可以继续使用，但不会进入新的普通 `git add`
