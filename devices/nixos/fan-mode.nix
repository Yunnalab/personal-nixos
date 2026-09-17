# MACHINE-SPECIFIC: platform_profile 的取值、intel_pstate 和 HWP/EPP 都是本机硬件接口。
{ config, lib, pkgs, ... }:

let
  # ASUS 通过 ACPI platform_profile 暴露风扇/散热策略
  profileFile = "/sys/firmware/acpi/platform_profile";

  # intel_pstate 的睿频开关和频率上限（需要 status=active）
  intelPstate = "/sys/devices/system/cpu/intel_pstate";

  # 记录用户的选择，重启后由 fan-mode-restore.service 恢复
  stateDir = "/var/lib/fan-mode";
  stateFile = "${stateDir}/mode";

  fanMode = pkgs.writeShellApplication {
    name = "fan-mode";
    runtimeInputs = with pkgs; [
      coreutils
      sudo
    ];
    text = ''
      # 一条命令管理本机的散热策略：ASUS 风扇曲线 + Intel CPU 调频。
      #
      #   fan-mode              在 quiet 与 balanced 之间来回切换
      #   fan-mode quiet        安静：关睿频、CPU 上限低
      #   fan-mode balanced     平衡：开睿频，插电不限速
      #   fan-mode performance  性能：睿频、上限、EPP 全部放开
      #   fan-mode status       查看实际生效的值（只读，无需 root）
      #
      # 选择记录在 ${stateFile}，重启后自动恢复；
      # 插拔电源时按下面的策略表重新套用对应那一列。
      #
      # ── 策略表（mode:电源，1=交流电 0=电池）──────────────────────────────
      #   mode:ac        platform_profile   睿频   max_perf_pct   EPP
      #   quiet:1        quiet              关     65             balance_power
      #   quiet:0        quiet              关     45             power
      #   balanced:1     balanced           开     100            balance_power
      #   balanced:0     balanced           开     65             power
      #   performance:1  performance        开     100            performance
      #   performance:0  performance        开     100            performance
      #
      # quiet 一列刻意与改造前 TLP 的配置逐项对齐
      # （AC: 关睿频/65/balance_power，BAT: 关睿频/45/power），
      # 所以换过来之后默认模式行为完全不变，不会莫名变慢或变吵。
      # 注意 max_perf_pct 是「关睿频后」的百分比，和「开睿频」时不是同一把尺子。

      PROFILE_FILE=${lib.escapeShellArg profileFile}
      STATE_FILE=${lib.escapeShellArg stateFile}
      STATE_DIR=${lib.escapeShellArg stateDir}
      STATE_CHOICES=''${PROFILE_FILE}_choices
      INTEL_PSTATE=${lib.escapeShellArg intelPstate}

      DEFAULT_MODE=quiet
      MODES=(quiet balanced performance)

      die() {
        printf 'fan-mode: %s\n' "$*" >&2
        exit 1
      }

      valid_mode() {
        local m
        for m in "''${MODES[@]}"; do
          [ "$m" = "$1" ] && return 0
        done
        return 1
      }

      read_sysf() {
        cat "$1" 2>/dev/null || printf '?'
      }

      # 读 sysfs，去掉尾部换行
      current_mode() {
        [ -e "$PROFILE_FILE" ] || die "找不到 $PROFILE_FILE（本机不支持 platform_profile？）"
        tr -d '[:space:]' < "$PROFILE_FILE"
      }

      saved_mode() {
        if [ -r "$STATE_FILE" ]; then
          tr -d '[:space:]' < "$STATE_FILE"
        else
          printf '%s' "$DEFAULT_MODE"
        fi
      }

      # 只要任一交流/USB 电源报告 online=1 就算插电。
      # 不写死 ADP0：本机还可能有 USB-C PD 供电。
      on_ac() {
        local f
        for f in /sys/class/power_supply/*/online; do
          if [ -r "$f" ] && [ "$(cat "$f")" = 1 ]; then
            return 0
          fi
        done
        return 1
      }

      # 查策略表，结果放进 NO_TURBO / MAX_PERF / EPP
      cpu_policy() {
        case "$1:$2" in
          quiet:1)        NO_TURBO=1; MAX_PERF=65;  EPP=balance_power ;;
          quiet:0)        NO_TURBO=1; MAX_PERF=45;  EPP=power ;;
          balanced:1)     NO_TURBO=0; MAX_PERF=100; EPP=balance_power ;;
          balanced:0)     NO_TURBO=0; MAX_PERF=65;  EPP=power ;;
          performance:1)  NO_TURBO=0; MAX_PERF=100; EPP=performance ;;
          performance:0)  NO_TURBO=0; MAX_PERF=100; EPP=performance ;;
          *)              NO_TURBO=""; MAX_PERF=""; EPP="" ;;
        esac
      }

      # 文件不存在或不可写就跳过：非 intel_pstate、无 HWP 的机器上优雅降级
      write_if_exists() {
        if [ -w "$1" ]; then
          printf '%s\n' "$2" > "$1" || die "写入 $1 失败"
        fi
      }

      apply_cpu() {
        local mode=$1 ac=$2 f
        NO_TURBO=""; MAX_PERF=""; EPP=""
        cpu_policy "$mode" "$ac"
        [ -n "$EPP" ] || return 0

        write_if_exists "$INTEL_PSTATE/no_turbo" "$NO_TURBO"
        write_if_exists "$INTEL_PSTATE/max_perf_pct" "$MAX_PERF"
        for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
          write_if_exists "$f" "$EPP"
        done
      }

      apply_mode() {
        local mode=$1

        valid_mode "$mode" || die "未知模式 '$mode'（可选：''${MODES[*]}）"

        # 固件只接受 platform_profile_choices 里列出的值，这里再核对一次
        if [ -r "$STATE_CHOICES" ]; then
          local choices
          choices=$(tr -s '[:space:]' ' ' < "$STATE_CHOICES")
          case "$choices" in
            *"$mode"*) ;;
            *) die "固件不支持模式 '$mode'（支持：$choices）" ;;
          esac
        fi

        # 先建状态目录，避免写成功 sysfs 却记不下选择
        install -d -m 0755 "$STATE_DIR"

        printf '%s\n' "$mode" > "$PROFILE_FILE" || die "写入 $PROFILE_FILE 失败"
        printf '%s\n' "$mode" > "$STATE_FILE"

        if on_ac; then
          apply_cpu "$mode" 1
        else
          apply_cpu "$mode" 0
        fi

        printf '风扇模式 → %s（已记录，重启后自动恢复）\n' "$mode"
      }

      turbo_state() {
        case "$(read_sysf "$INTEL_PSTATE/no_turbo")" in
          0) printf '开' ;;
          1) printf '关' ;;
          *) printf '未知' ;;
        esac
      }

      perf_state() {
        local v
        v=$(read_sysf "$INTEL_PSTATE/max_perf_pct")
        case "$v" in
          [0-9]*) printf '%s%%' "$v" ;;
          *) printf '未知' ;;
        esac
      }

      action=''${1:-toggle}

      # 只读操作不需要 root
      if [ "$action" = status ]; then
        # 单独赋值：否则 current_mode 里的 die 只退出命令替换的子 shell
        cur=$(current_mode)
        printf '当前生效   : %s\n' "$cur"
        printf '重启后恢复 : %s\n' "$(saved_mode)"
        if on_ac; then
          printf '电源       : 交流电\n'
        else
          printf '电源       : 电池\n'
        fi
        printf 'CPU 睿频   : %s\n' "$(turbo_state)"
        printf 'CPU 上限   : %s\n' "$(perf_state)"
        printf 'CPU EPP    : %s\n' "$(read_sysf /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)"
        printf '可选模式   : %s\n' "$(cat "$STATE_CHOICES" 2>/dev/null || printf '%s' "''${MODES[*]}")"
        exit 0
      fi

      # 写 sysfs 和 $STATE_DIR 需要 root；sudoers 已为本脚本配置 NOPASSWD。
      # 提权后 $0 仍是同一个 /nix/store 路径，因此不会递归。
      if [ "$(id -u)" -ne 0 ]; then
        exec sudo -- "$0" "$@"
      fi

      case "$action" in
        toggle)
          if [ "$(current_mode)" = quiet ]; then
            apply_mode balanced
          else
            apply_mode quiet
          fi
          ;;
        restore)
          # 供 fan-mode-restore.service 调用：套用上次记录的值
          apply_mode "$(saved_mode)"
          ;;
        *)
          apply_mode "$action"
          ;;
      esac
    '';
  };
in
{
  # ── 风扇 + CPU 调频策略切换 ──
  # 接管了 TLP 的 PLATFORM_PROFILE_*、CPU_BOOST_*、CPU_MAX_PERF_*、
  # CPU_ENERGY_PERF_POLICY_*（这些在 power.nix 里被设为空字符串），原因：
  #   1. TLP 1.10.2 每次插拔电源都会经由 85-tlp.rules 跑 `tlp auto` 重设这些
  #      knob，会覆盖手动切换的结果；
  #   2. TLP 1.10.2 实际是*先*读 /etc/tlp.d/*.conf、*后*读 /etc/tlp.conf，
  #      而后者优先（见 share/tlp/.tlp-readconfs-wrapped），drop-in 覆盖不掉它；
  #   3. 未设置的参数会回落到 share/tlp/defaults.conf（那里的
  #      PLATFORM_PROFILE_ON_AC=performance 等），所以必须显式设空而不是删掉。
  environment.systemPackages = [ fanMode ];

  # 脚本在 /nix/store 里（root 所有、只读、内容固定），所以 NOPASSWD 是安全的：
  # 用户只能免密执行这一个脚本，无法借此跑任意命令。
  # mkAfter 保证这条规则排在 wheel 的通用规则之后（sudo 取最后一条匹配的规则）。
  security.sudo.extraRules = lib.mkAfter [
    {
      users = [ "cloudygirl" ];
      commands = [
        {
          command = "${fanMode}/bin/fan-mode";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # 保存用户选择的目录
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0755 root root -"
  ];

  # 电源切换后按策略表重新套用电池/交流那一列（TLP 已不碰这些 knob，得自己触发）。
  # 只匹配交流适配器和 USB-C 电源，不匹配 Battery：否则电池容量每次更新
  # 都会触发一次服务。
  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", TAG+="systemd", ENV{SYSTEMD_WANTS}+="fan-mode-restore.service"
    ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="USB", TAG+="systemd", ENV{SYSTEMD_WANTS}+="fan-mode-restore.service"
  '';

  systemd.services.fan-mode-restore = {
    description = "套用记录的风扇/CPU 策略（platform_profile + intel_pstate）";
    wantedBy = [ "multi-user.target" ];
    wants = [ "systemd-udev-settle.service" ];
    after = [ "systemd-udev-settle.service" "tlp.service" ];
    serviceConfig = {
      Type = "oneshot";
      # 故意不设 RemainAfterExit：电源变化时 udev 需要能再次拉起它
      ExecStart = "${fanMode}/bin/fan-mode restore";
    };
  };
}
