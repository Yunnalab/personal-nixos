{ pkgs, ... }:
{
  fonts = {
    # when set to true, causes some "basic" fonts to be installed for reasonable
    # Unicode coverage. Set to true if you are unsure about what languages
    # you might end up reading.
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
      # Sans serif fonts: prefer Western fonts, then CJK variants, fallback to HanaMin
      sansSerif = [
        "Noto Sans"
        "Noto Sans CJK SC"
        "Noto Sans CJK TC"
        "Noto Sans CJK JP"
        "Noto Sans CJK KR"
        "Noto Color Emoji"
      ];

      # Serif fonts: prefer Western fonts, then CJK variants, fallback to HanaMin
      serif = [
        "Noto Serif"
        "Noto Serif CJK SC"
        "Noto Serif CJK TC"
        "Noto Serif CJK JP"
        "Noto Serif CJK KR"
        "Noto Color Emoji"
      ];

      # Monospace fonts: Maple Mono for programming, fallback to Noto Sans Mono
      monospace = [
        "Maple Mono NF CN"
        "Noto Sans Mono"
        "Noto Color Emoji"
      ];

      # Emoji font
      emoji = [
        "Noto Color Emoji"
      ];
    };
  };
}
