{ pkgs, ... }:

let
  # QQ 在 Wayland 原生模式下剪贴板不工作，强制走 XWayland 让 wlroots 做剪贴板桥接
  qq-x11 = pkgs.symlinkJoin {
    name = "qq";
    paths = [ pkgs.qq ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/qq"
      makeWrapper "${pkgs.qq}/bin/qq" "$out/bin/qq" \
        --unset NIXOS_OZONE_WL \
        --set QT_IM_MODULE fcitx \
        --set GTK_IM_MODULE fcitx \
        --set XMODIFIERS "@im=fcitx"

      # 修正 desktop 入口指向新 wrapper
      rm "$out/share/applications/qq.desktop"
      sed "s|Exec=${pkgs.qq}/bin/qq|Exec=$out/bin/qq|" \
        "${pkgs.qq}/share/applications/qq.desktop" \
        > "$out/share/applications/qq.desktop"
    '';
  };
in
{
  # 替换原 qq，避免包冲突
  environment.systemPackages = [ qq-x11 ];
}
