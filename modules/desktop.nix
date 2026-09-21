{ config, lib, pkgs, ... }:

{
  # 文件管理器的图形提权、磁盘挂载和缩略图支持。
  security.polkit.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;
  services.gvfs.enable = true;

  # Wayland 兼容性：启用 Xwayland，并让 Electron/Chromium 类应用优先使用原生 Wayland 后端
  programs.xwayland.enable = true;
  environment.variables = {
    NIXOS_OZONE_WL = "1";
  };

  # 桌面栈：Plasma 作为应急备用桌面，Niri 为主桌面。
  # 登录界面使用 greetd + tuigreet（见文件末尾），不再使用 SDDM。
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    dolphin
  ];
  programs.niri.enable = true;

  # niri 为主桌面：明确默认会话，避免与 plasma6 的 defaultSession 冲突
  services.displayManager.defaultSession = lib.mkForce "niri";

  # ── 关机不再“假死” ──
  # 症状：关机时卡在 “Stopping A scrollable-tiling Wayland compositor...”，
  # 屏幕定格、机器迟迟不断电，只能长按电源键。
  #
  # 2026-09-20 21:49 那次关机（journalctl -b -1）就是这样：
  #   [12519.596] systemd[2613]: Stopping A scrollable-tiling Wayland compositor...
  #   （之后 51 秒无任何日志，直到用户按电源键）
  # 内核和 PID1 都还活着（logind 仍在记录合盖事件），说明是 niri 自己
  # 卡在退出流程，而不是内核挂死。
  #
  # systemd 对 Type=notify 的服务默认要等 DefaultTimeoutStopSec=90s 才会
  # SIGKILL，于是表现为“死机”。niri 正常退出只要 ~0.3s（对比 -2/-6 两次
  # 干净关机），所以给它一个短超时：10s 内没退就直接杀掉，关机流程继续。
  systemd.user.services.niri.serviceConfig = {
    TimeoutStopSec = 10;
  };

  # 兜底：用户会话里任何一个 unit 卡住，最多拖 20s，不会再出现分钟级的假死。
  systemd.user.settings.Manager.DefaultTimeoutStopSec = "20s";

  # ── 登录管理器：greetd + tuigreet ──
  # 替代 SDDM：终端 TUI 登录界面，整条依赖里没有 Qt。
  # 会话列表由 services.displayManager.sessionData 提供（niri、plasma 都已注册）。
  services.greetd = {
    enable = true;

    # TUI greeter 必须开启：把 greetd 的 stdin/stdout 接到 tty1，避免启动日志糊在界面上
    useTextGreeter = true;

    settings.default_session.command = lib.concatStringsSep " " [
      "${pkgs.tuigreet}/bin/tuigreet"
      "--time"
      "--user" "cloudygirl"   # 预填用户名：登录时直接回车 → 输密码
      "--remember"            # 兜底：记住上次成功登录的用户名
      "--remember-session"    # 记住上次选择的会话
      "--asterisks"
      "--greeting" (lib.escapeShellArg "Welcome back")
      "--sessions" "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
      "--xsessions" "${config.services.displayManager.sessionData.desktops}/share/xsessions"
    ];
  };

  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  # 音频：显式启用 PipeWire 全栈，确保 pactl/pavucontrol 可用
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  environment.systemPackages = with pkgs; [
    pavucontrol    # 图形化音量控制，可切换输出设备
  ];

  # Flatpak 支持和 Flathub 远程仓库自动配置。
  services.flatpak.enable = true;
  systemd.services.flatpak-add-flathub = {
    description = "Add Flathub remote for Flatpak";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
