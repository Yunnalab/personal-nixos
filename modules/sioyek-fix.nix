{ pkgs, ... }:

let
  # 2026-10-30 重新排查：sioyek「点了没反应」的真实根因是 GL 上下文创建失败，
  # 进程能起来、X11/Wayland toplevel 也创建了，但客户端从不提交缓冲区，
  # 所以合成器不会映射窗口，stderr 也没有明显报错。
  #
  # 触发条件是 Qt 走 GLX/EGL 的 NVIDIA 厂商库：PRIME offload 机器上
  # glvnd 在 xcb 平台会选中 libGLX_nvidia，而 18:03 的 rebuild 把用户态
  # 驱动升到 595.112.07、内核里仍是 595.104.02（重启后才更新），于是
  #   dmesg: NVRM: API mismatch: the client '.sioyek-wrapped'
  #   nvidia-smi: Failed to initialize NVML: Driver/library version mismatch
  #   sioyek: QOpenGLWidget: Failed to create context
  # 窗口因此永远不显示。
  #
  # 因此：不再强制 xcb（XWayland + GLX + NVIDIA），改为默认原生 Wayland，
  # 让 EGL 走合成器所在核显（Intel/Mesa），彻底避开 NVIDIA 用户态/内核态
  # 版本漂移这一类故障。—— 修复驱动漂移本身仍需重启系统。
  sioyek-wayland = pkgs.symlinkJoin {
    name = "sioyek";
    paths = [ pkgs.sioyek ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/sioyek"
      makeWrapper "${pkgs.sioyek}/bin/sioyek" "$out/bin/sioyek" \
        --set-default QT_QPA_PLATFORM wayland
    '';
    # -set-default：允许临时用 QT_QPA_PLATFORM=xcb 复现/对比。
    # desktop 入口 Exec=sioyek %f / TryExec=sioyek 走 PATH，自动指向本 wrapper，无需改写。
  };
in
{
  # 替换原 sioyek（packages.nix 中已移除，避免 bin 冲突）
  environment.systemPackages = [ sioyek-wayland ];
}
