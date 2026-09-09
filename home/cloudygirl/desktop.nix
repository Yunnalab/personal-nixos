{ pkgs, noctalia, ... }:

{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
  };

  xdg.configFile = {
    "noctalia/config.json".source = ./config/noctalia/noctalia-base-settings-v4.json;
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

  systemd.user.services.swayidle = {
    Unit = {
      Description = "Swayidle (idle management for Niri)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 300 'swaylock -f' timeout 301 'niri msg action power-off-monitors' before-sleep 'swaylock -f'";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
