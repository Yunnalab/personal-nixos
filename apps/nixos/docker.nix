{ pkgs, ... }:
let
  # 端口只在这里定义：apps/clash-proxy-data.nix
  clash = import ../clash-proxy-data.nix;
in
{
    virtualisation.docker.enable = true;
    users.users.cloudygirl.extraGroups = [ "docker" ];
    virtualisation.docker.autoPrune.enable = true;
    virtualisation.docker.autoPrune.dates = "weekly";

    # 拉镜像也走 clash（Docker daemon 只认小写 http-proxy 这种写法）
    virtualisation.docker.daemon.settings = {
        proxies = {
            http-proxy = clash.http;
            https-proxy = clash.http;
            # Docker 的 no-proxy 只接受逗号分隔的 IP/域名，不认 ::1 这种带方括号的写法
            no-proxy = "localhost,127.0.0.1";
        };
    };
}
