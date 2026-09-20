# MACHINE-SPECIFIC: tuned for this Intel laptop's power and thermal behavior.
{ ... }:

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
}
