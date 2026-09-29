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
  # 登录界面使用 greetd + noctalia-greeter（见文件末尾），不再使用 SDDM / tuigreet。
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

  # ── 登录管理器：greetd + noctalia-greeter ──
  # 替代 SDDM / tuigreet：图形登录界面，自带 wlroots 合成器跑在 DRM/KMS 上，
  # 视觉风格与 Noctalia Shell 一致。nixpkgs unstable 已收录该包和模块
  # （services.displayManager.noctalia-greeter），不需要额外 flake input。
  # 会话列表：greeter 直接扫 /run/current-system/sw/share/wayland-sessions，
  # niri / plasma 的 .desktop 都在那里，无需手动指定路径。
  services.displayManager.noctalia-greeter = {
    enable = true;

    settings = {
      session.default = "niri";        # 默认会话（Name= 字段，不是 .desktop 文件名）
      user.default = "cloudygirl";     # 开机直接进入密码步骤

      # "Synced" = 用 Noctalia Shell 同步过来的配色（sync.toml）。
      # 还没同步过时 greeter 找不到 "Synced" 配色，会自动退回内置 Noctalia 配色。
      # ⚠️ 千万不要在 greeter.toml 里写 [appearance.palette]：完整的调色板会
      #    覆盖同步过来的颜色，同步就只剩壁纸生效了。
      appearance.scheme = "Synced";

      keyboard.layout = "us";
      idle.timeout = 300;              # 5 分钟无操作熄灭屏幕，0 = 不熄灭

      # 尺寸：面板 2560x1600 / 350x220mm，按 EDID 算出来的自动缩放≈1.93
      #（上限 2），所以界面明显偏大。这里只给内屏写死成和 niri 会话一致的 1.25；
      # 外接显示器不在列表里，仍按各自的 DPI 自动缩放。
      output.scales = "eDP-1:1.25";
    };

    # NixOS 上默认游标查找路径（~/.icons、/usr/share/icons）不存在，必须显式给包
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };
  };

  # ── 登录界面同步所需的 polkit 授权 ──
  # pkexec 必须用 setuid wrapper（store 里的 pkexec 是 0555，直接调用会报
  # "pkexec must be setuid root"）；/run/wrappers/bin 在用户 PATH 最前面。
  security.polkit.enablePkexecWrapper = true;

  # 免密同步：等价于上游新模块的 passwordlessSyncUsers = [ "cloudygirl" ]。
  # 本机 lock 的 nixpkgs（noctalia-greeter 1.5.0）还没这个选项，所以手写规则。
  # 只放开这一个动作：调用方是 greeter 的 apply-appearance helper、目标是 root、
  # 且是本机活跃会话里的 cloudygirl。想恢复「每次弹管理员授权」就删掉本段。
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      var helper = "${config.services.displayManager.noctalia-greeter.package}/bin/noctalia-greeter-apply-appearance";
      if (action.id == "org.noctalia.greeter.sync-appearance" &&
          action.lookup("program") == helper &&
          action.lookup("user") == "root" &&
          subject.local && subject.active &&
          subject.user == "cloudygirl") {
        return polkit.Result.YES;
      }
    });
  '';

  services.greetd = {
    enable = true;

    # 注意：noctalia-greeter 是 Wayland greeter（自建合成器，走 logind 拿 DRM 权限），
    # 不能再开 useTextGreeter —— 那是给 tuigreet 这类 TUI 用的，
    # 打开会把 greetd 的 stdin/stdout 钉在 tty1 上，图形 greeter 直接起不来。
    #
    # 登录界面的配色/壁纸同步开关在 noctalia 那一侧，见
    # home/cloudygirl/desktop.nix 的 settings.shell.greeter_sync.auto_sync。
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
