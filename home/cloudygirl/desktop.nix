{ pkgs, lib, noctalia, ... }:

{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
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
