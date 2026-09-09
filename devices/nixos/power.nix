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
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_BOOST_ON_AC = 0;
      CPU_BOOST_ON_BAT = 0;
      CPU_MAX_PERF_ON_AC = 65;
      CPU_MAX_PERF_ON_BAT = 45;
      PLATFORM_PROFILE_ON_AC = "quiet";
      PLATFORM_PROFILE_ON_BAT = "quiet";
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

  # 不插电时触发安静配置，会有额外电池模式 CPU 限速
  systemd.services.quiet-cpu-profile = {
    description = "Keep CPU in a quiet low-power profile";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ "$(cat /sys/class/power_supply/ADP0/online 2>/dev/null || echo 1)" = "1" ]; then
        exit 0
      fi

      if [ -w /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
        echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
      fi

      if [ -w /sys/devices/system/cpu/intel_pstate/max_perf_pct ]; then
        echo 45 > /sys/devices/system/cpu/intel_pstate/max_perf_pct
      fi

      for pref in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        [ -w "$pref" ] && echo power > "$pref"
      done
    '';
  };
}
