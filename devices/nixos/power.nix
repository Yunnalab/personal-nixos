# MACHINE-SPECIFIC: tuned for this Intel laptop's power and thermal behavior.
{ pkgs, lib, ... }:
let
  # 交流在线判定：Mains / USB-C 供电源的 .../online 为 1 即视为外接供电。
  # 本机是 ADP0，这里用通配符匹配，避免换机或内核重命名后失效。
  acOnline = ''
    ac_online() {
      for p in /sys/class/power_supply/*/online; do
        [ -r "$p" ] || continue
        if [ "$(cat "$p")" = 1 ]; then return 0; fi
      done
      return 1
    }
  '';

  # 交流供电期间常驻，持有 logind 的 block 模式 sleep 抑制锁。
  # 只要它活着，任何来源的挂起请求都会被拒绝：手动 systemctl suspend、
  # Noctalia 空闲 lock-and-suspend（该行为会先锁屏再挂起，挂起被拒即达成
  # 「只锁屏 + 后台继续低功耗运行」）、其他程序发起的挂起。
  # 掉电后进程自然退出，抑制锁释放，电池模式恢复挂起。
  acPowerInhibit = pkgs.writeShellApplication {
    name = "ac-power-inhibit";
    runtimeInputs = [
      pkgs.systemd
      pkgs.coreutils
    ];
    text = ''
      ${acOnline}
      if ! ac_online; then
        echo "电池供电：不持有抑制锁"
        exit 0
      fi
      echo "交流供电：持有 sleep 抑制锁，挂起请求将被拒绝"
      exec systemd-inhibit \
        --what=sleep \
        --who=ac-power-inhibit \
        --why="交流供电，按策略不挂起" \
        --mode=block \
        sleep infinity
    '';
  };
in
{
  # 电源方案
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  services.power-profiles-daemon.enable = false;

  # TLP 电池和温控调校
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # ── 以下参数故意设为空字符串，交给 ./fan-mode.nix 的 `fan-mode` 命令接管 ──
      # 空值 = TLP 不碰这个参数（见 share/tlp/func.d/10-tlp-func-cpu 里
      # set_platform_profile / set_cpu_perf_policy / set_intel_cpu_perf_pct /
      # set_cpu_boost_all 的判空分支）。
      #
      # ⚠️ 必须是「设为空」，不能删掉这一行：TLP 未设置的参数会回落到
      # share/tlp/defaults.conf，那里写着
      #     PLATFORM_PROFILE_ON_AC=performance
      #     PLATFORM_PROFILE_ON_BAT=balanced
      #     CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
      #     CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
      # 删掉就会回落到这些值，TLP 继续在每次插拔电源时覆盖 fan-mode。
      #
      # 必须接管的理由：TLP 的 udev 规则（85-tlp.rules）在电源变化时跑
      # `tlp auto` 重读配置并重设这些 knob，会把手动切换的结果冲掉。
      PLATFORM_PROFILE_ON_AC = "";
      PLATFORM_PROFILE_ON_BAT = "";
      CPU_ENERGY_PERF_POLICY_ON_AC = "";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "";
      CPU_BOOST_ON_AC = "";
      CPU_BOOST_ON_BAT = "";
      CPU_MAX_PERF_ON_AC = "";
      CPU_MAX_PERF_ON_BAT = "";
      # _ON_SAV 是 TLP 的第三档（SAV）用的；本机 TLP_PROFILE_AC=PRF、
      # TLP_PROFILE_BAT=BAL，SAV 用不到，但一并设空更保险
      # （例如将来启用 power-profiles-daemon 时会走 SAV 档）。
      PLATFORM_PROFILE_ON_SAV = "";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "";
      CPU_BOOST_ON_SAV = "";
      CPU_MAX_PERF_ON_SAV = "";

      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      SATA_LINKPWR_ON_AC = "med_power_with_dipm";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
      USB_AUTOSUSPEND = 1;
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      SOUND_POWER_SAVE_ON_AC = 1;
      SOUND_POWER_SAVE_ON_BAT = 1;
      NMI_WATCHDOG = 0;
    };
  };

  # 电池模式下的 CPU 限速原先由 v:quiet-cpu-profile 服务处理，现已并入
  # ./fan-mode.nix：`fan-mode` 的策略表同时包含交流和电池两列。

  # ── 挂起策略：按供电状态分流 ─────────────────────────────────────────
  #
  #   交流供电 → 只锁屏，后台低功耗继续运行，永不挂起
  #   电池供电 → 锁屏并挂起
  #
  # 手段一：合盖交给 logind 原生分流。判定优先级见 logind.conf(5)：
  #     已接 dock / 外接屏 → HandleLidSwitchDocked
  #     否则交流供电       → HandleLidSwitchExternalPower
  #     否则（电池）       → HandleLidSwitch
  # ⚠️ logind 出于向后兼容「完全忽略」HandleLidSwitchExternalPower，
  #    不显式赋值它就不会生效，合盖在交流下仍会按 HandleLidSwitch 挂起。
  # 电池合盖时，Noctalia 会通过 PrepareForSleep 的 sleep-delay 抑制锁先锁屏
  # 再放行挂起，所以「锁屏 + 挂起」是自动成立的。
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
    HandleLidSwitchDocked = "lock";
  };

  # 手段二：交流供电时用抑制锁兜底，覆盖合盖、空闲、手动在内的全部挂起来源。
  # 挂起失败在 Noctalia 侧只记一条 warning，不会弹错误通知。
  systemd.services.ac-power-inhibit = {
    description = "交流供电期间持有 logind sleep 抑制锁";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = lib.getExe acPowerInhibit;
      Restart = "no";
    };
  };

  # 供电状态变化时重评估：插电 → 起服务加锁；拔电 → 服务退出解锁。
  # 开机时 power_supply 的 add 事件同样会触发，因此不依赖轮询。
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="add|change", RUN+="${lib.getExe' pkgs.systemd "systemctl"} --no-block restart ac-power-inhibit.service"
  '';
}
