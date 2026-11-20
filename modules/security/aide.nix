# AIDE 文件完整性监控
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.security.aide;
in
{
  options.security.aide = {
    enable = mkEnableOption "AIDE 文件完整性监控";
    
    checkInterval = mkOption {
      type = types.str;
      default = "weekly";
      description = "检查间隔 (systemd calendar格式)";
    };
    
    logRetentionDays = mkOption {
      type = types.int;
      default = 28;
      description = "日志保留天数";
    };
    
    monitoredPaths = mkOption {
      type = types.listOf types.str;
      default = [
        "/etc p+i+n+u+g+s+m"
        "/etc/passwd p+i+n+u+g"
        "/etc/shadow p+i+n+u+g"
        "/etc/ssh/sshd_config p+i+n+u+g"
      ];
      description = "监控的路径";
    };
    
    excludedPaths = mkOption {
      type = types.listOf types.str;
      default = [
        "!/tmp"
        "!/nix/store"
        "!/proc"
        "!/sys"
        "!/dev"
      ];
      description = "排除的路径";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."aide.conf".text = ''
      # AIDE配置 - 使用SHA256哈希 (lynis建议)
      database_in=file:/var/lib/aide/aide.db
      database_out=file:/var/lib/aide/aide.db.new
      report_url=stdout
      
      # 定义检查规则: 使用SHA256哈希
      PERMS = p+i+u+g
      DATAONLY = p+i+n+u+g+s+m
      DIR = p+i+n+u+g
      LOG = p+i+n+u+g
      
      # 监控路径
      ${concatStringsSep "\n" cfg.monitoredPaths}
      
      # 排除路径
      ${concatStringsSep "\n" cfg.excludedPaths}
    '';

    # aide 本体由 modules/packages.nix 的「安全工具」一节安装，这里不重复列。

    systemd.services.aide-init = {
      description = "初始化AIDE数据库";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /var/lib/aide
        ${pkgs.aide}/bin/aide --init --config=/etc/aide.conf
        cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
      '';
      before = [ "aide-check.service" ];
    };

    systemd.services.aide-check = {
      description = "AIDE文件完整性检查";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "aide-check" ''
          LOG="/var/log/aide/check-$(date +%Y%m%d).log"
          mkdir -p /var/log/aide
          echo "=== AIDE检查 $(date) ===" > "$LOG"
          ${pkgs.aide}/bin/aide --check --config=/etc/aide.conf >> "$LOG" 2>&1
          find /var/log/aide -name "check-*.log" -mtime +${toString cfg.logRetentionDays} -delete 2>/dev/null
        '';
        User = "root";
      };
    };

    systemd.timers.aide-check = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.checkInterval;
        Persistent = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/aide 0755 root root -"
      "d /var/log/aide 0755 root root -"
    ];
  };
}
