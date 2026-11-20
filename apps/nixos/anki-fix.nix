{ pkgs, ... }:

let
  # Anki 在 Wayland 原生模式下的输入法 bug：
  # 浏览界面的 QtWebEngine 编辑器会走 fcitx5-qt 插件的兜底输入路径（Qt Wayland
  # 平台本应走合成器 text-input 协议），导致按键被提交两次——打拼音 "shuru"
  # 输出 "shuru shuru"，候选框也随之消失。
  # 强制 Anki 走 XWayland (xcb) 平台，fcitx5-qt 插件即成为受支持的单一输入路径。
  anki-x11 = pkgs.symlinkJoin {
    name = "anki";
    paths = [ pkgs.anki ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/anki"
      makeWrapper "${pkgs.anki}/bin/anki" "$out/bin/anki" \
        --set QT_QPA_PLATFORM xcb \
        --set QT_IM_MODULE fcitx \
        --set GTK_IM_MODULE fcitx \
        --set XMODIFIERS "@im=fcitx"
    '';
    # desktop 入口 Exec=anki %f 走 PATH，自动指向本 wrapper，无需改写
  };
in
{
  # 替换原 anki（packages.nix 中已移除，避免 bin 冲突）
  environment.systemPackages = [ anki-x11 ];
}
