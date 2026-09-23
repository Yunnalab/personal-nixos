{ ... }:

{
  # Chrome, VS Code 和 QQ必要权限
  nixpkgs.config.allowUnfree = true;
  # Nix 命令行为和二进制缓存。
  # 顺序很重要：nix 按顺序尝试，第一个能提供 narinfo 的就会去下 NAR，
  # 下 NAR 失败不会退回后面的源，而是报错或长时间卡住。
  # 实测（2026-09-23，本地宽带）：
  #   上交 11.7 MB/s（最快，但偶发慢启动）
  #   官方 0.07 MB/s（被链路限速）
  #   科大 narinfo 有、NAR 404（同步不全）
  #   南大 narinfo 404
  # 因此上交排第一，官方做兜底，科大/南大降到最后。
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://noctalia.cachix.org"
      # 科大镜像建议保留在最后：它可能对某些包只有 narinfo 没有 NAR：
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      # 南大镜像同步中（narinfo 404），同步完成后可移到官方之前：
      # "https://mirrors.nju.edu.cn/nix-channels/store"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
    trusted-users = [ "root" "cloudygirl" ];
  };

  # 自动垃圾回收：每周清理旧 generation 和 store，防止磁盘占满
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
