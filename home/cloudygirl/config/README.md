# 用户软件配置资源

这里同时保存 Home Manager 部署的源文件和未接管的应用配置快照。是否生效由 `home/cloudygirl/` 中的显式文件映射决定，而不是文件是否出现在本目录。

## 已声明管理

| 源文件或目录 | 所属模块 | 部署位置 |
| --- | --- | --- |
| `niri/config.kdl` | `home/cloudygirl/desktop.nix` | `~/.config/niri/config.kdl` |
| `kitty/kitty.conf` | `home/cloudygirl/desktop.nix` | `~/.config/kitty/kitty.conf` |
| `noctalia/noctalia-base-settings-v4.json` | `home/cloudygirl/desktop.nix` | `~/.config/noctalia/config.json` |
| `swaylock/config` | `home/cloudygirl/desktop.nix` | `~/.config/swaylock/config` |
| `eza/theme.yml` | `home/cloudygirl/desktop.nix` | `~/.config/eza/theme.yml` |
| `pi/agents/` 中的 scout、builder、reviewer | `home/cloudygirl/pi-agents.nix` | `~/.pi/agent/agents/` |
| `fcitx5/rime/` 中显式列出的六个文件 | `home/cloudygirl/apps.nix` | `~/.local/share/fcitx5/rime/` |

Thunar 自定义动作由 `home/cloudygirl/apps.nix` 生成；默认打开方式与 KDE/Niri 兼容文件由 `home/cloudygirl/mime.nix` 生成，不使用此目录中的 `mimeapps.list` 快照。DeepSeek 桌面入口由 `home/cloudygirl/packages.nix` 生成。

`eza/theme.yml` 是从上游 [eza-themes](https://github.com/eza-community/eza-themes) 原样拷贝的第三方主题，不是本地原创：合并冲突时以上游为准，改配色应换主题而不是手改正文。它把颜色写死成 hex，Noctalia 换调色板时 eza 不会跟随——这是已知限制，原因和重新生成命令都写在文件头注释里。

`pi/agents/` 下的子 agent 定义是只读软链。pi 的 `/subagents` 面板切换 `enabled` 时会直接写回文件，对这些链接会失败；要启停 agent 请改源文件后 rebuild，不要指望面板里的开关能持久化。

## 未接管快照

未被模块显式引用的 Noctalia、Fcitx5、KDE/Qt、GTK、Fontconfig、XSettings、Glow、Sioyek 等配置仅作为快照保存，不自动部署。Noctalia 当前使用 JSON 源文件，不存在按状态栏、Dock 等拆分的 Nix 子模块。

含文件选择历史、设备或活动标识、本机路径的 Qt、蓝牙、KWin、Plasma 和旧 Noctalia TOML 快照已列入 `.gitignore`，仅保留本地副本。正在部署的 Noctalia JSON、Niri 等源配置仍被保留；它们含有本机设置，不代表已经匿名化。

新增管理项时，将源文件放在 `<app>/` 下，并在负责该应用的模块中添加单独映射。保留必要的相邻资源依赖，例如 GTK 配置引用的 `colors.css`。应用频繁写入的配置应先确认能否只读管理，不要默认设置 `force = true`。

## 排除内容

- 浏览器配置目录、即时通讯和 Electron 应用状态目录。
- Cookie、数据库、缓存、锁文件、会话历史与同步状态。
- API key 和其他凭据，包括可能带有凭据的编辑器设置。

修改流程、验证命令与模块职责见仓库根目录的 `README.md`。
