{ pkgs, lib, config, noctalia, ... }:

{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    # Noctalia 的「应用主题模板」：换配色时把颜色写进各个应用的配置文件。
    # ⚠️ 这里写的是“默认值”（部署到 ~/.config/noctalia/config.toml）。
    #    Noctalia 运行时的 ~/.local/state/noctalia/settings.toml 是**最终覆盖层**，
    #    优先级更高；改这里之后记得把 settings.toml 里同名的键一起改（或用 GUI）。
    settings.theme.templates = {
      # niri：内置模板只写 ~/.config/niri/noctalia.kdl，完全不碰 config.kdl
      #       （那份已 include 了它），干净无噪音。
      # helix：内置模板正常工作。
      builtin_ids = [ "helix" "niri" ];

      # kitty：**故意不参与 Noctalia 主题**（builtin_ids 里没有 kitty，也不再加
      # user.kitty 模板）。kitty 固定使用 config/kitty/kitty.conf 里写死的
      # Catppuccin Mocha 配色，换壁纸/换配色时完全不动。
      #
      # 历史：曾经配过 user.kitty 模板（写 themes/noctalia.conf + pkill -USR1）。
      # 它有两个问题：内置模板的 apply.sh 会无条件 `touch` store 里的只读
      # kitty.conf 从而 exit 1；自定义模板虽绕开了这点，但换配色时 kitty 的配色
      # 会跟着 Noctalia 一起变，不符合“终端保持固定配色”的用法。
      #
      # 注意：Noctalia 的 user 模板只从**主 config**（本文件生成的 config.toml）
      # 读取，运行时的 ~/.local/state/noctalia/settings.toml 覆盖不了它，
      # 所以必须在这里删掉，不能只在 GUI/settings.toml 里关。
      # builtin_ids 保持 [ "helix" "niri" ]，不要加 "kitty"。
    };

    # 登录界面（greetd + noctalia-greeter）同步：换壁纸/配色时由 Shell 调
    # noctalia-greeter-apply-appearance 推送到 /var/lib/noctalia-greeter/sync.toml。
    # 免密的 polkit 规则在 nixos/modules/desktop.nix 的 security.polkit.extraConfig。
    # 没安装 greeter 或 helper 不在 PATH 时这个开关会被忽略。
    settings.shell.greeter_sync.auto_sync = true;
  };

  xdg.configFile = {
    "noctalia/config.json".source = ./config/noctalia/noctalia-base-settings-v4.json;
    # 锁屏统一交给 Noctalia（空闲 / 挂起 / Mod+L），这里只保留一份供手动调用的备用配置。
    # 不要再把 swaylock 挂到 swayidle 的 timeout / before-sleep 上：两套锁屏抢锁时，
    # niri 会拒绝后到的那个，而 Noctalia 遇到 ext-session-lock 协议错误会直接崩溃。
    "swaylock/config".source = ./config/swaylock/config;
    "niri/config.kdl" = {
      source = ./config/niri/config.kdl;
      force = true;
    };
    "kitty/kitty.conf" = {
      source = ./config/kitty/kitty.conf;
      force = true;
    };
    # eza 主题：文件必须叫 theme.yml，eza 只从这个固定路径读取。
    # 注意 LS_COLORS / EZA_COLORS 优先级高于 theme.yml；当前 shell 两者都为空，
    # 所以这份主题会直接生效。换主题 = 换 config/eza/theme.yml 的内容。
    "eza/theme.yml".source = ./config/eza/theme.yml;
  };

  # niri 的 config.kdl 末尾有一句 `include "noctalia.kdl"`，而 noctalia.kdl 是
  # Noctalia 在运行时生成/覆盖的（用户可写）。niri 对 include 缺失是硬报错，
  # 整个会话起不来，所以首次激活时先放一个空占位文件。
  #
  # 反过来，config.kdl 本身是 store 里的只读文件：Noctalia 的 niri 模板
  # （apply.sh）发现 include 已存在就会直接返回，不会再去改 config.kdl。
  home.activation.ensureNoctaliaNiriKdl = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/niri"
    if [ ! -e "$HOME/.config/niri/noctalia.kdl" ]; then
      run touch "$HOME/.config/niri/noctalia.kdl"
    fi
  '';

  systemd.user.services.polkit-kde-agent = {
    Unit = {
      Description = "KDE PolicyKit Authentication Agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
