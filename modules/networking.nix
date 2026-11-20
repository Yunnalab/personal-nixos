{ ... }:

{
  # 通用网络服务（主机名与开放端口属于本机策略，在 devices/nixos/configuration.nix）
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

  # SSH 远程连接；加固项（PermitRootLogin 等）在 modules/security/hardening.nix
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };
}
