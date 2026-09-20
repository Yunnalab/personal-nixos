# MACHINE-SPECIFIC: ASUS keyboard LED paths are not portable.
{ pkgs, lib, ... }:
let
  # resume 后背光兜底：本机面板背光由 EC 经 WMI 控制
  # （/sys/class/backlight/nvidia_wmi_ec_backlight 位于 PNP0C14:00 下，
  #  i915 启动时日志写着 "Skipping intel_backlight registration"）。
  # 若 resume 时 EC 的 ACPI 方法超时（dmesg 里的
  #   ACPI Error: Aborting method \_SB.PC00.LPCB.ECLV (AE_AML_LOOP_TIMEOUT)
  #   ACPI Error: AE_AML_LOOP_TIMEOUT, while evaluating GPE method [_L14]
  # ），亮度就下不去，表现为「合盖后再打开屏幕全黑，但系统其实活着」
  # （锁屏、输密码解锁、网络都能正常工作）。
  # 只在检测到本次确实发生过 EC 超时时才重下发一次，避免正常 resume 被闪屏。
  backlightRestore = pkgs.writeShellApplication {
    name = "backlight-restore-after-resume";
    runtimeInputs = [
      pkgs.util-linux
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      dev=/sys/class/backlight/nvidia_wmi_ec_backlight
      [ -w "$dev/brightness" ] || exit 0

      # ⚠️ 不要用 journalctl 查：实测它每次唤醒读 51MB 日志、耗 2.2s，
      # 正好碰在用户输密码的时候。dmesg 读的是内核环形缓冲区，代价极低，
      # 正常唤醒几十毫秒就退出。
      if ! dmesg | grep -qE "ECLV|AE_AML_LOOP_TIMEOUT"; then
        exit 0
      fi

      # 确认是 EC 挂了，才等一下让 EC 缓过来
      sleep 1
      cur="$(cat "$dev/brightness")"
      # 内核 backlight 核心对相同数值会提前返回、不下发给 EC，
      # 所以先写一个不同的值强制触发一次写入，再恢复原值。
      # 此刻屏幕本来就是黑的，因此不会造成可见闪烁。
      echo 0 > "$dev/brightness"
      echo "$cur" > "$dev/brightness"

      new="$(cat "$dev/brightness")"
      if [ "$new" = "$cur" ]; then
        echo "检测到 EC 超时，背光已重下发（亮度 $cur）"
      else
        echo "背光重下发失败：期望 $cur，实际读回 $new" >&2
      fi
    '';
  };
in
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

  # ── resume 时 ASUS EC 挂死导致屏幕黑：改用 S3 ──
  # 实测 2026-09-20 11:43:49 那次 s2idle resume 出现
  #   ACPI Error: Aborting method \_SB.PC00.LPCB.ECLV (AE_AML_LOOP_TIMEOUT)
  #   ACPI Error: AE_AML_LOOP_TIMEOUT, while evaluating GPE method [_L14]
  # 而 10:00:32 / 11:37:55 两次正常 resume 没这条。EC 没响应 → 背光下不去
  # → 屏幕全黑。
  # s2idle 不经过固件的挂起/恢复路径，EC 不会被重新初始化；deep（S3）会，
  # 这向来是华硕 ROG 机器上修 EC resume 问题的首选办法。
  # 本机 /sys/power/mem_sleep 为 "[s2idle] deep"，两者都支持。
  boot.kernelParams = [ "mem_sleep_default=deep" ];

  # 上一条若仍偶发失败时的兜底（只在真正检测到 EC 超时时动作）
  systemd.services.backlight-restore-after-resume = {
    description = "resume 后重新下发 EC 面板背光";
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe backlightRestore;
    };
  };

  # 蓝牙
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
