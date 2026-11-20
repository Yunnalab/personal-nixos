# 系统安全加固
{ config, lib, ... }:

with lib;

let
  cfg = config.security.hardening;
in
{
  options.security.hardening = {
    enable = mkEnableOption "系统安全加固";
    
    enableFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "启用防火墙";
    };
    
    allowedTCPPorts = mkOption {
      type = types.listOf types.int;
      default = [ 22 ];
      description = "允许的TCP端口";
    };
    
    enableFail2ban = mkOption {
      type = types.bool;
      default = true;
      description = "启用fail2ban防暴力破解";
    };
  };

  config = mkIf cfg.enable {
    # 防火墙
    networking.firewall = mkIf cfg.enableFirewall {
      enable = true;
      allowedTCPPorts = cfg.allowedTCPPorts;
    };

    # SSH 加固
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        X11Forwarding = false;
        MaxAuthTries = 3;
        LoginGraceTime = 60;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        AllowAgentForwarding = false;
        AllowTcpForwarding = false;
        PermitTunnel = false;
        Protocol = 2;
      };
    };

    # fail2ban
    services.fail2ban = mkIf cfg.enableFail2ban {
      enable = true;
      maxretry = 3;
      bantime = "1h";
    };

    # 内核安全参数 (修复lynis发现的DIFFERENT项)
    boot.kernel.sysctl = {
      # 防止SYN洪水攻击
      "net.ipv4.tcp_syncookies" = true;
      
      # 禁止IP源路由
      "net.ipv4.conf.all.accept_source_route" = false;
      "net.ipv4.conf.default.accept_source_route" = false;
      
      # 禁止ICMP重定向
      "net.ipv4.conf.all.accept_redirects" = false;
      "net.ipv4.conf.default.accept_redirects" = false;
      "net.ipv6.conf.all.accept_redirects" = false;
      "net.ipv6.conf.default.accept_redirects" = false;
      
      # 启用反向路径过滤
      "net.ipv4.conf.all.rp_filter" = true;
      "net.ipv4.conf.default.rp_filter" = true;
      
      # 忽略ICMP广播
      "net.ipv4.icmp_echo_ignore_broadcasts" = true;
      
      # 记录异常数据包
      "net.ipv4.conf.all.log_martians" = true;
      "net.ipv4.conf.default.log_martians" = true;
      
      # 禁止发送ICMP重定向
      "net.ipv4.conf.all.send_redirects" = false;
      "net.ipv4.conf.default.send_redirects" = false;
      
      # 保护符号链接和硬链接
      "fs.protected_symlinks" = true;
      "fs.protected_hardlinks" = true;
      
      # 限制core dump
      "fs.suid_dumpable" = false;
      
      # 限制ptrace
      "kernel.yama.ptrace_scope" = 1;
      
      # 限制内核指针泄露
      "kernel.kptr_restrict" = 2;
      
      # 限制dmesg访问
      "kernel.dmesg_restrict" = true;
      
      # BPF限制
      "kernel.unprivileged_bpf_disabled" = true;
      "net.core.bpf_jit_harden" = 2;
      
      # 禁用SysRq
      "kernel.sysrq" = false;
    };

    # 安全工具统一装在 modules/packages.nix 的「安全工具」一节，
    # 这里只负责服务、sysctl、PAM 等策略，不再重复列包。

    # 登录横幅 (lynis建议BANN-7126)
    environment.etc."issue".text = ''
      Authorized users only. All activity may be monitored.
    '';

    # 密码策略 (lynis建议AUTH-9229/9230/9286)
    security.pam.loginLimits = [
      { domain = "*"; type = "hard"; item = "maxlogins"; value = "3"; }
    ];

    # USB存储限制 (lynis建议USB-1000)
    boot.blacklistedKernelModules = [
      "usb-storage"  # 禁用USB存储，需要时可移除
    ];
  };
}
