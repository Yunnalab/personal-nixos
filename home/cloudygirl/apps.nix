{ pkgs, ... }:

{
  programs.google-chrome = {
    enable = true;
    commandLineArgs = [
      "--enable-experimental-web-platform-features"
      "--enable-features=AcceleratedVideoDecodeLinuxGL"
      # Chrome 固定走 clash 混合代理端口（socks5）
      "--proxy-server=socks5://127.0.0.1:7897"
    ];
  };

  programs.firefox = {
    enable = true;
    profiles.main = {
      id = 0;
      isDefault = true;
      settings = {
        "sidebar.verticalTabs" = true;
        "browser.search.openintab" = true;
        "browser.urlbar.openintab" = true;
      };
    };
  };

  # Rime 输入法配置
  xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
    source = ./config/fcitx5/rime/default.custom.yaml;
    force = true;
  };
  xdg.dataFile."fcitx5/rime/luna_pinyin.custom.yaml" = {
    source = ./config/fcitx5/rime/luna_pinyin.custom.yaml;
    force = true;
  };
  xdg.dataFile."fcitx5/rime/luna_pinyin.custom.dict.yaml" = {
    source = ./config/fcitx5/rime/luna_pinyin.custom.dict.yaml;
    force = true;
  };
  xdg.dataFile."fcitx5/rime/fcitx5.custom.yaml" = {
    source = ./config/fcitx5/rime/fcitx5.custom.yaml;
    force = true;
  };
  xdg.dataFile."fcitx5/rime/emoji.schema.yaml" = {
    source = ./config/fcitx5/rime/emoji.schema.yaml;
    force = true;
  };
  xdg.dataFile."fcitx5/rime/emoji.dict.yaml" = {
    source = ./config/fcitx5/rime/emoji.dict.yaml;
    force = true;
  };

  xdg.dataFile."applications/wps-office-wps.desktop".source = ./config/wps-desktop/wps-office-wps.desktop;
  xdg.dataFile."applications/wps-office-et.desktop".source = ./config/wps-desktop/wps-office-et.desktop;
  xdg.dataFile."applications/wps-office-wpp.desktop".source = ./config/wps-desktop/wps-office-wpp.desktop;

  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
      <icon>utilities-terminal</icon>
      <name>Open Terminal Here</name>
      <submenu></submenu>
      <unique-id>1783058739735464-1</unique-id>
      <command>${pkgs.kitty}/bin/kitty --working-directory %f</command>
      <description>Open kitty in this directory</description>
      <range></range>
      <patterns>*</patterns>
      <startup-notify/>
      <directories/>
    </action>
    <action>
      <icon>system-file-manager</icon>
      <name>Open as Administrator</name>
      <submenu></submenu>
      <unique-id>1783067653000000-1</unique-id>
      <command>${pkgs.thunar}/bin/thunar admin://%f</command>
      <description>Open this directory with administrator permissions</description>
      <range></range>
      <patterns>*</patterns>
      <startup-notify/>
      <directories/>
    </action>
    </actions>
  '';
}
