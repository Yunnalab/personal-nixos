{ pkgs, ... }:
{
  fonts = {
    # 设为 true 时会额外装一批「基础」字体，保证常见 Unicode 覆盖面。
    # 不确定要读哪些语言时保持 true。
    enableDefaultPackages = true;

    packages = with pkgs; [
      nerd-fonts.liberation
      nerd-fonts.jetbrains-mono
      maple-mono.NF-CN-unhinted
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      lxgw-wenkai-screen
      source-han-sans
      source-han-serif
    ];

    fontconfig.defaultFonts = {
      # 无衬线：西文字体优先，其次 CJK，最后回退到 HanaMin
      sansSerif = [
        "Noto Sans"
        "Noto Sans CJK SC"
        "Noto Sans CJK TC"
        "Noto Sans CJK JP"
        "Noto Sans CJK KR"
        "Noto Color Emoji"
      ];

      # 衬线：西文字体优先，其次 CJK，最后回退到 HanaMin
      serif = [
        "Noto Serif"
        "Noto Serif CJK SC"
        "Noto Serif CJK TC"
        "Noto Serif CJK JP"
        "Noto Serif CJK KR"
        "Noto Color Emoji"
      ];

      # 等宽：编程用 Maple Mono，回退 Noto Sans Mono
      monospace = [
        "Maple Mono NF CN"
        "Noto Sans Mono"
        "Noto Color Emoji"
      ];

      # Emoji 字体
      emoji = [
        "Noto Color Emoji"
      ];
    };
  };
}
