{ pkgs, noctalia, ... }:

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
