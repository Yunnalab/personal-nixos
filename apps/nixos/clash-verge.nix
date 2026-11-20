{ config, lib, pkgs, ... }:

{
  # Clash Verge Rev — 图形代理客户端
  # 已导入订阅后开启 TUN：serviceMode 让 root 运行的服务负责创建 TUN 网卡，
  # tunMode 给 GUI 授予额外 capabilities。
  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    tunMode = true;
  };

  # clash 内核需要绑定 53 端口做 DNS 解析（fake-ip / dns-hijack），
  # 但 nixpkgs 模块的 CapabilityBoundingSet 默认不含 CAP_NET_BIND_SERVICE，
  # 导致 "listen udp :53: bind: permission denied" 而 TUN 断网。
  systemd.services.clash-verge.serviceConfig = {
    CapabilityBoundingSet = [
      "CAP_NET_ADMIN"
      "CAP_NET_RAW"
      "CAP_SYS_ADMIN"
      "CAP_DAC_OVERRIDE"
      "CAP_SETUID"
      "CAP_SETGID"
      "CAP_CHOWN"
      "CAP_MKNOD"
      "CAP_NET_BIND_SERVICE"
    ];
  };

  # 清理旧版 serviceMode 留下的 root 所有权残留：
  # 这些文件导致 GUI 以普通用户身份无法写入配置、内核无法创建 socket，
  # 从而"启动失败" / "内核通信错误"。
  system.activationScripts.clash-verge-cleanup = ''
    rm -rf /run/user/1002/clash-verge-rev
    if [ -d /home/cloudygirl/.local/share/io.github.clash-verge-rev.clash-verge-rev ] \
       && [ "$(stat -c %U /home/cloudygirl/.local/share/io.github.clash-verge-rev.clash-verge-rev 2>/dev/null)" != "cloudygirl" ]; then
      rm -rf /home/cloudygirl/.local/share/io.github.clash-verge-rev.clash-verge-rev
    fi
  '';
}
