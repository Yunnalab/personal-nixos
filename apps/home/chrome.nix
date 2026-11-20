{ ... }:

let
  # 端口只在这里定义：apps/clash-proxy-data.nix
  clash = import ../clash-proxy-data.nix;
in
{
  # Chrome 除代理外的参数（实验特性 + VA-API 解码）与本模块无关，
  # 但同属一个 programs.google-chrome 属性集，拆开会更难读，故一起写在这里。
  programs.google-chrome = {
    enable = true;
    commandLineArgs = [
      "--enable-experimental-web-platform-features"
      "--enable-features=AcceleratedVideoDecodeLinuxGL"
      # Chrome 固定走 clash 混合代理端口（socks5）
      "--proxy-server=${clash.socks}"
    ];
  };
}
