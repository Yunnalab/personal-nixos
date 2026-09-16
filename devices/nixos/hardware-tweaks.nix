# MACHINE-SPECIFIC: ASUS keyboard LED paths are not portable.
{ ... }:

{
  # 内核和底层设备调整

  # ⚠️ 下面两组背光配置当前是空转的：hid_asus 被拉黑后，
  # asus::kbd_backlight 这个 LED 节点不再注册（原因见文件末尾）。
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

  # ── 内核 6.18.52 的 hid-asus 回归：临时规避 ──
  # 本机内置键盘不是 PS/2（i8042 中断计数几乎为 0），而是 USB N-KEY 设备
  # 0B05:19B6，正常由 hid_asus 接管。
  #
  # stable 回移 d0754db7883c（upstream 56d1b33e64，"HID: asus: simplify RGB
  # init sequence"）把 asus_kbd_get_functions() 从 QUIRK_ROG_NKEY_KEYBOARD 的
  # else 分支提到公共路径，于是 ROG N-KEY 键盘也收到了此前从不发送的 0x5a
  # 配置命令。本机在该命令上返回
  #   asus ...: Asus failed to request functions: -75   (EOVERFLOW)
  # 之后内置键盘不再产生任何输入事件（6.18.44 无此问题，v7.2.6 仍未修）。
  #
  # 黑名单后由 hid-generic 以普通 USB HID 键盘接管，输入恢复正常。
  # 副作用：asus::kbd_backlight 不再注册，上面两组背光配置因此空转。
  # 上游修好那个提交后即可删除本行。
  boot.blacklistedKernelModules = [ "hid_asus" ];

  # 蓝牙
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
