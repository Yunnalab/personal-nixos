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

      # kitty：**不用内置模板**（builtin_ids 里没有 kitty），换成下面这个自定义模板。
      #
      # 原因：内置模板的 apply.sh 第一步是无条件 `touch ~/.config/kitty/kitty.conf`，
      # 而该文件是 store 里的只读软链，于是整个 hook 以 exit 1 失败：
      #   1) 每次换配色都在日志里刷一条“权限不够”；
      #   2) 失败得太早，后面的 `pkill -USR1 kitty` 根本执行不到，
      #      已经开着的 kitty 窗口不会重载新配色。
      #
      # 自定义模板只保留内置模板真正有用的部分（渲染颜色到 themes/noctalia.conf
      # + 通知 kitty 重载）。include 那一行已经写死在 config/kitty/kitty.conf 里，
      # 不需要任何 hook 去改 kitty.conf。
      #
      # 字段对照 ~/.config/noctalia 文档与 Noctalia 自带的 builtin.toml：
      #   [templates.kitty]
      #   input_path  = "./kitty/kitty.conf"
      #   output_path = "$XDG_CONFIG_HOME/kitty/themes/noctalia.conf"
      #   post_hook   = "bash '{{ config_dir }}/kitty/apply.sh'"
      user.kitty = {
        input_path = "${config.programs.noctalia.package}/share/noctalia/assets/templates/kitty/kitty.conf";
        output_path = "$XDG_CONFIG_HOME/kitty/themes/noctalia.conf";
        post_hook = "pkill -USR1 -x kitty || true";
      };
    };
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
