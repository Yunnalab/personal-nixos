# NixOS 工作站配置

本仓库声明主机 `nixos` 的 NixOS 和 Home Manager 配置。重构目录或模块时，默认保持系统行为不变；依赖升级、服务调整和结构重构分开进行。

## 配置分层

```text
flake.nix                         输入版本与系统组装
├── devices/nixos/                本机模块选择、硬件与主机策略
│   ├── configuration.nix          swap、安全策略、系统兼容版本
│   ├── hardware-configuration.nix 硬件扫描结果
│   ├── fonts.nix                  系统字体与回退顺序
│   ├── boot.nix                   EFI/Windows 启动项（本机专属）
│   ├── nvidia.nix                 NVIDIA PRIME 总线号（本机专属）
│   ├── hardware-tweaks.nix        华硕键盘 LED（本机专属）
│   ├── power.nix                  Intel 电源调优（本机专属）
│   └── sddm-theme.nix             登录主题与背景打包
├── home/cloudygirl/default.nix    NixOS 与 Home Manager 的接入层
└── home/cloudygirl/home.nix       用户配置入口、会话 PATH、用户兼容版本
    ├── shell.nix                   Fish、Starship、终端工具集成
    ├── apps.nix                    浏览器、Rime、WPS、Thunar
    ├── mime.nix                    默认打开方式及桌面兼容映射
    ├── desktop.nix                 Noctalia、Niri、Kitty、锁屏与用户服务
    └── packages.nix                用户软件包与自定义启动器桌面入口

packages/                         自定义包构建函数，不直接设置系统选项
home/cloudygirl/config/           被模块引用的配置源文件及未接管快照
assets/                           登录背景等静态资源
notes/                            笔记与 Pandoc/XeLaTeX 模板
scripts/、anki/、download/、watt/、windows/
                                  辅助资料或独立工作流，不自动导入系统
```

`flake.lock` 锁定 `nixpkgs`、Home Manager、Noctalia、Zen Browser 及其依赖。设备入口位于 `devices/nixos/`，用户入口位于 `home/cloudygirl/`。

## 系统模块索引

| 文件 | 职责 |
| --- | --- |
| `devices/nixos/boot.nix` | GRUB/EFI 和 Windows 启动项，本机专属 |
| `devices/nixos/hardware-tweaks.nix` | 华硕键盘背光、蓝牙和硬件调整，本机专属 |
| `devices/nixos/nvidia.nix` | NVIDIA 驱动与 PRIME，本机专属 |
| `devices/nixos/power.nix` | TLP、CPU 与电源策略，本机专属 |
| `modules/locale.nix` | 中文区域、时区与 Fcitx5 |
| `modules/networking.nix` | 主机名、NetworkManager、SSH 与网络设置 |
| `modules/desktop.nix` | 桌面会话、音频、Flatpak、图形提权与文件管理器服务 |
| `modules/nix-settings.nix` | Nix 功能、缓存、unfree 策略与垃圾回收 |
| `modules/packages.nix` | 系统软件包清单，调用 `packages/` 中的构建函数 |
| `modules/qq-fix.nix`、`modules/anki-fix.nix` | 应用兼容性包装器及安装 |
| `modules/proxy.nix` | Clash Verge、权限包装与激活清理 |
| `modules/docker-setting.nix` | Docker 服务、用户组和代理 |
| `modules/users.nix` | 本地用户定义 |
| `modules/shell.nix` | 系统编辑器环境变量与别名模块接入 |
| `modules/shell-aliases.nix` | 系统 shell 别名配置 |
| `modules/shell-aliases-data.nix` | 系统 shell 与用户 Fish 共享的纯数据，不是模块 |
| `modules/steam.nix` | Steam 启用与字体 |
| `modules/security/` | AIDE、审计和加固的选项定义与实现 |

`devices/nixos/configuration.nix` 选择本机安全策略；`modules/security/` 实现这些策略。`modules/deepseek-harness-security.nix` 当前未导入，仅放入目录不会启用它。

`devices/nixos/` 下除通用资源外的配置默认视为本机专属。迁移到其他电脑时，至少重新生成 `hardware-configuration.nix`，并审查 `boot.nix`、`nvidia.nix`、`hardware-tweaks.nix`、`power.nix` 和 `networking.nix` 中的硬件、磁盘 UUID、主机名与端口设置；不要直接复用旧的磁盘或 PRIME 参数。

## 放在哪里

- 设备特定的文件系统、硬件和主机策略放在 `devices/<name>/`；可复用的系统服务、驱动、权限或全局环境变量放在 `modules/`。
- 系统通用软件包加到 `modules/packages.nix`；仅当前用户需要的软件包加到 `home/cloudygirl/packages.nix`。应用模块自动安装的包通常不需要重复添加。
- 自定义命令或运行环境放在 `packages/<name>.nix`，显式声明构建依赖，再通过 `pkgs.callPackage` 安装。`mdpdf` 的模板仍位于 `notes/template/`。
- 用户应用选项放在 `home/cloudygirl/apps.nix`；桌面与用户服务放在 `home/cloudygirl/desktop.nix`；默认打开方式只在 `home/cloudygirl/mime.nix` 维护。
- 应用原生配置文件放在 `home/cloudygirl/config/<app>/`，在负责该应用的模块中显式声明 `xdg.configFile` 或 `xdg.dataFile` 映射。
- 新模块需要加入相应入口的 `imports`。不按目录自动导入，避免启用草稿、备份或把纯数据当成模块。

保持一文件一类职责，但不为每个选项创建一个文件。只有独立变化、复用或明显过长的功能才继续拆分；当前单主机配置不需要额外的主机框架或自定义开关体系。

NixOS 模块与 Home Manager 模块使用不同的选项空间，不要互相直接导入。外部 flake 输入通过 `home/cloudygirl/default.nix` 的 `home-manager.extraSpecialArgs` 传给用户模块，避免依赖外层函数的隐式作用域。


## 隐私与生成物

`.gitignore` 排除本地凭据、环境文件、工具缓存、构建结果、笔记 PDF、Anki 导出、下载目录以及含个人状态的桌面快照。`windows/` 下的个人目录链接也不纳入版本控制。本地文件可以继续使用，但不会进入新的普通 `git add`
