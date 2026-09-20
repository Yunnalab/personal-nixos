{ pkgs, ... }:

{
  imports = [
    ./shell.nix
    ./apps.nix
    ./mime.nix
    ./desktop.nix
    ./packages.nix
  ];

  home.stateVersion = "26.05";

  # npm / cargo 全局安装目录加入 PATH。
  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.cargo/bin"
  ];

  home.sessionVariables = {
    # pi 的 pi-markdown-preview 扩展靠 Chromium 做终端内联预览与 PNG 导出。
    # 该扩展只探测 /usr/bin/{google-chrome,chromium,...}，NixOS 上不存在这些路径，
    # 因此显式指向 Chrome；否则报 "No Chromium-based browser was found"。
    PUPPETEER_EXECUTABLE_PATH = "${pkgs.google-chrome}/bin/google-chrome-stable";

    # 同上：PDF 导出需要 mermaid-cli，才能把 ```mermaid 代码块渲染成矢量图；
    # 否则扩展会给出警告并把 Mermaid 保留为代码块。
    MERMAID_CLI_PATH = "${pkgs.mermaid-cli}/bin/mmdc";
  };
}
