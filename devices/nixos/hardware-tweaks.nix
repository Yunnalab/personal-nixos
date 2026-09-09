# MACHINE-SPECIFIC: ASUS keyboard LED paths are not portable.
{ ... }:

{
  # 内核和底层设备调整

  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="leds", KERNEL=="asus::kbd_backlight", ATTR{brightness}="3"
  '';

  # 华硕键盘背光：启动时以及 LED 设备出现时强制打开
  systemd.services.keyboard-backlight-on = {
    description = "Keep keyboard backlight on";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      led=/sys/class/leds/asus::kbd_backlight
      if [ -w "$led/brightness" ]; then
        cat "$led/max_brightness" > "$led/brightness"
      fi
    '';
  };

  # 蓝牙
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
