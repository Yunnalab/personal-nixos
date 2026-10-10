{ pkgs, ... }:

let
  # Sioyek 2.0（Qt6/QtQuick）在原生 Wayland 后端下不会提交窗口缓冲区：
  # 客户端只创建 xdg_toplevel、ack configure，随后既不 attach buffer 也不重绘，
  # 合成器因此永远不会映射窗口——进程活着、stderr 无任何报错，但屏幕上什么都看不到，
  # 表现为「点了 PDF 没反应」。改用 XWayland (xcb) 平台后窗口正常显示并渲染页面。
  sioyek-x11 = pkgs.symlinkJoin {
    name = "sioyek";
    paths = [ pkgs.sioyek ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/sioyek"
      makeWrapper "${pkgs.sioyek}/bin/sioyek" "$out/bin/sioyek" \
        --set QT_QPA_PLATFORM xcb \
        --set QT_IM_MODULE fcitx \
        --set XMODIFIERS "@im=fcitx"
    '';
    # desktop 入口 Exec=sioyek %f / TryExec=sioyek 走 PATH，自动指向本 wrapper，无需改写
  };
in
{
  # 替换原 sioyek（packages.nix 中已移除，避免 bin 冲突）
  environment.systemPackages = [ sioyek-x11 ];
}
