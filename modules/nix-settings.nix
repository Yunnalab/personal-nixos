{ ... }:

{
  # Chrome, VS Code 和 QQ必要权限
  nixpkgs.config.allowUnfree = true;
  # Nix 命令行为和二进制缓存。
  # 顺序很重要：nix 按顺序尝试，某个源缺 NAR 会回退到下一个源。
  # 实测（2026-11-13，本地宽带）：
  #   科大 单连接 9~12 MB/s（最快；个别包的 NAR 404，nix 会自动回退）
  #   上交 0.07 MB/s，且并发连接一多就集体卡死（曾经最快，现已严重劣化）
  #   官方 直连 0.06~0.28 MB/s；走本机 Clash（127.0.0.1:7897）可达 10 MB/s
  #   南大 narinfo 404（仍在同步）
  # 另外注意：镜像对并发连接限速，大包宁可 nix 单连接串行下载，
  # 不要用多个 nix copy 并行去拉（会一起卡死）。
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://noctalia.cachix.org"
      # 上交镜像目前很慢，只作最后的兜底：
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      # 南大镜像同步中（narinfo 404），同步完成后可代替上交排在最后：
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
