{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules/desktop.nix
    ./hardware-tweaks.nix
    ../../modules/locale.nix
    ../../modules/networking.nix
    ./nvidia.nix
    ./fan-mode.nix
    ../../modules/nix-settings.nix
    ../../modules/packages.nix
    ../../apps/nixos
    ./power.nix
    ../../modules/users.nix
    ../../modules/shell.nix
    ../../modules/security
  ];

  # Swap文件配置（8G）
  swapDevices = [{
    device = "/swapfile";
    size = 8192;
  }];

  # ── 本机网络身份与额外开放端口 ──
  # 主机名和端口属于本机策略，不放在通用的 modules/networking.nix 里。
  networking.hostName = "nixos";
  # 7681：ttyd 网页终端。目前没有对应 systemd 服务，需要时手动
  # `ttyd -p 7681 <命令>`；22（SSH）由 security.hardening.allowedTCPPorts 放行。
  networking.firewall.allowedTCPPorts = [ 7681 ];

  # ── 安全配置 ──
  security.aide = {
    enable = true;
    checkInterval = "weekly";
    logRetentionDays = 28;
    monitoredPaths = [
      "/etc p+i+n+u+g+s+m"
      "/etc/passwd p+i+n+u+g"
      "/etc/ssh/sshd_config p+i+n+u+g"
      "/etc/nixos p+i+n+u+g"
      "/home/cloudygirl/.ssh p+i+n+u+g"
    ];
    excludedPaths = [
      "!/tmp"
      "!/nix/store"
      "!/proc"
      "!/sys"
      "!/dev"
    ];
  };

  security.auditRules = {
    enable = true;
    rules = [
      "-w /etc/passwd -p wa -k identity"
      "-w /etc/shadow -p wa -k identity"
      "-w /etc/ssh/sshd_config -p wa -k sshd"
      "-w /etc/nixos -p wa -k nixos"
    ];
  };

  security.hardening = {
    enable = true;
    enableFirewall = true;
    allowedTCPPorts = [ 22 ];
    enableFail2ban = true;
  };

  # NixOS 版本兼容级别
  system.stateVersion = "26.11";
}
