{ pkgs, ... }:

let
  # Clash Verge Rev 的混合代理端口（同时接受 HTTP 与 SOCKS5）
  proxyHost = "127.0.0.1";
  proxyPort = 7897;
  httpProxy = "http://${proxyHost}:${toString proxyPort}";
  socksProxy = "socks5://${proxyHost}:${toString proxyPort}";

  # ChatGPT 桌面版是 Electron 应用，代理要分两路喂：
  #   * Chromium 只认 --proxy-server 启动开关，不读 http_proxy 环境变量；
  #   * 它内置的 codex CLI（Rust/reqwest）认 HTTPS_PROXY / ALL_PROXY。
  # wrapper 命名为 chatgpt 以遮蔽系统同名命令（~/.nix-profile/bin 排在
  # /run/current-system/sw/bin 之前），因此启动器里原有的 Exec=chatgpt 也走代理。
  chatgptProxy = pkgs.writeShellScriptBin "chatgpt" ''
    export HTTP_PROXY=${httpProxy}
    export HTTPS_PROXY=${httpProxy}
    export ALL_PROXY=${socksProxy}
    export NO_PROXY=localhost,127.0.0.1,::1
    exec ${pkgs.chatgpt}/bin/chatgpt --proxy-server=${socksProxy} "$@"
  '';
in
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

  # ChatGPT 桌面版：命令与启动器都固定走 clash 代理
  home.packages = [ chatgptProxy ];

  # 启动器条目用绝对路径指向 wrapper，不依赖 PATH 顺序；
  # MimeType 与原系统条目保持一致，避免丢掉 codex:// 与文件类型的关联。
  xdg.desktopEntries.chatgpt = {
    name = "ChatGPT";
    genericName = "AI assistant";
    comment = "ChatGPT by OpenAI（固定走 clash ${socksProxy}）";
    exec = "${chatgptProxy}/bin/chatgpt %U";
    icon = "chatgpt";
    terminal = false;
    type = "Application";
    categories = [ "Utility" "Development" ];
    startupNotify = true;
    mimeType = [
      "x-scheme-handler/codex"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "text/csv"
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      "text/tab-separated-values"
      "application/vnd.ms-excel"
      "application/vnd.ms-excel.sheet.macroEnabled.12"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ];
  };
}
