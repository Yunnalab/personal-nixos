{ pkgs, ... }:

let
  loginBackground = ../../assets/login-bg.jpg;

  animeSddmTheme = (pkgs.sddm-astronaut.override {
    embeddedTheme = "japanese_aesthetic";
    themeConfig = {
      # ======================
      # 字体
      # ======================
      Font = "Noto Sans";
      FontSize = "10";

      # ======================
      # ❌ 完全无遮罩关键
      # ======================
      DimBackground = "0";

      PartialBlur = "false";
      Blur = "0";
      BlurMax = "0";

      # ======================
      # ❌ 移除 login 卡片
      # ======================
      HaveFormBackground = "false";
      FormBackgroundColor = "#00000000";

      # ======================
      # 背景
      # ======================
      Background = "Backgrounds/login-bg.jpg";

      CropBackground = "true";

      # ======================
      # ✔ 输入框完全浮动
      # ======================
      LoginFieldBackgroundColor = "#FFFFFF10";
      PasswordFieldBackgroundColor = "#FFFFFF10";

      LoginFieldTextColor = "#dff6ff";
      PasswordFieldTextColor = "#dff6ff";

      PlaceholderTextColor = "#9db5d6";

      # ======================
      # UI 布局
      # ======================
      FormPosition = "center";

      # ======================
      # 时间（视觉中心点）
      # ======================
      TimeTextSize = "26";
      DateTextSize = "12";
      TimeTextColor = "#c7e6ff";

      # ======================
      # 行为
      # ======================
      ForceLastUser = "true";
      PasswordFocus = "true";

      HideVirtualKeyboard = "true";
    };
  }).overrideAttrs (oldAttrs: {
    installPhase = oldAttrs.installPhase + ''
      chmod u+w $out/share/sddm/themes/sddm-astronaut-theme/Backgrounds
      cp ${loginBackground} $out/share/sddm/themes/sddm-astronaut-theme/Backgrounds/login-bg.jpg
    '';
  });

in
{
  services.displayManager.sddm = {
    enable = true;

    extraPackages = with pkgs.kdePackages; [
      qtmultimedia
      qtsvg
      qtvirtualkeyboard
    ];

    theme = "sddm-astronaut-theme";
  };

  environment.systemPackages = [
    animeSddmTheme
  ];
}
