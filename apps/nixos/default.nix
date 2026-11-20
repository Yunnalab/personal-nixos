{ ... }:

# 系统侧的逐应用适配入口，由 devices/nixos/configuration.nix 导入。
#
# 只收两类东西，系统级服务/策略不要放这里（那些留在 modules/）：
#   1. 单个软件的联网设置（代理客户端本体、Steam、Docker daemon）；
#   2. 上游还没修的 bug 的本地处理（wrapper、nixpkgs overlay 修补）。
#
# ../clash-proxy-data.nix 是纯数据，不是模块，不能出现在这个 imports 里。
{
  imports = [
    ./clash-verge.nix
    ./steam.nix
    ./docker.nix
    ./qq-fix.nix
    ./anki-fix.nix
    ./kazumi-fix.nix
    ./nixpkgs-overrides.nix
  ];
}
