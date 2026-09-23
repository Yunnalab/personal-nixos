{ pkgs, ... }:

# tmux：终端复用器。
#
# 这份配置有两个目的：
#   1. 让 pi 在 tmux 里键位正常。原生 tmux 会剥掉修饰键信息，导致
#      Shift+Enter / Ctrl+Enter 和裸 Enter 不可区分（见 pi 自带文档
#      docs/tmux.md），不开 extended-keys 就是「想换行却提交」。
#   2. 当多 agent 的工作台：一个 agent 一个窗口，配 resurrect 让布局
#      在重启后还能回来。agent 定义与启动脚本见 pi-agents.nix。
{
  programs.tmux = {
    enable = true;

    # C-b 又远又和 readline 的 backward-char 打架，改用 screen 风格的 C-a。
    prefix = "C-a";
    keyMode = "vi";
    # 窗口 / 面板都从 1 开始编号，键盘左上角顺手。
    baseIndex = 1;
    mouse = true;
    # neovim 的 FocusGained / FocusLost 依赖它。
    focusEvents = true;
    # agent 的输出量比人手动敲大得多，默认 2000 行很快就不够翻。
    historyLimit = 50000;
    terminal = "tmux-256color";
    # 默认 500ms：按 ESC 和发 Alt 序列时会有肉眼可见的卡顿，本机连接改 10ms。
    escapeTime = 10;
    # sensible 插件的合理默认值放在配置最前面，后面的设置可以覆盖它。
    sensibleOnTop = true;

    plugins = [
      # 保存 / 恢复 session、窗口、面板布局。选项在「保存时」读取，
      # 因此相关的 @resurrect-* 写在 extraConfig 里即可。
      pkgs.tmuxPlugins.resurrect

      # continuum：定时自动保存 + tmux 服务启动时自动恢复。
      # 它和别的插件不同：@continuum-restore 是在插件「加载时」读取的，
      # 而 Home Manager 把 extraConfig 排在插件 run-shell 之后，写在那里
      # 已经太晚。Home Manager 会把插件自带的 extraConfig 属性插在
      # run-shell 之前，所以只能这样注入。
      (pkgs.tmuxPlugins.continuum // {
        extraConfig = "set -g @continuum-restore 'on'";
      })

      # 复制到系统剪贴板。Wayland 下插件会自己探测到 wl-copy。
      pkgs.tmuxPlugins.yank
    ];

    extraConfig = ''
      # ── 与 pi 协作的必备项 ────────────────────────────────────────────
      # csi-u 格式需要 tmux >= 3.5（本机 3.7c）。
      set -g extended-keys on
      set -g extended-keys-format csi-u

      # ── 终端能力 ─────────────────────────────────────────────────────
      # 真彩色；allow-passthrough 让 kitty graphics / OSC52 这类序列穿过
      # tmux 直达终端，pi-markdown-preview 的终端内联图片依赖它。
      set -as terminal-features ",*:RGB"
      set -g allow-passthrough on
      set -g set-clipboard on

      # ── 多 agent 工作台 ──────────────────────────────────────────────
      # 新窗口 / 新面板继承当前目录。agent-farm 正是靠这个让每个 agent
      # 落在自己独占的 git worktree 里，而不是全部回到 $HOME。
      bind c   new-window   -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      bind %   split-window -h -c "#{pane_current_path}"

      # Alt+hjkl 免前缀切面板，Alt+数字 免前缀跳窗口。
      # 特意用 Alt 而不是 Ctrl：C-hjkl 要和 neovim、readline 抢。
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9

      # C-a r 重载配置。
      bind r source-file ~/.config/tmux/tmux.conf \; display "配置已重载"

      # ── 插件参数 ─────────────────────────────────────────────────────
      # 这两项都是运行时读取的（resurrect 在保存时读，continuum 的状态栏
      # 脚本每次刷新时读），写在这里顺序没问题。
      # 不要在这里改 @continuum-restore：见上面 plugins 里的说明。
      set -g @resurrect-capture-pane-contents 'on'
      set -g @continuum-save-interval '15'
    '';
  };
}
