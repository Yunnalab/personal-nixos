{ pkgs, ... }:

let
  # 别名与 eza 参数都取自 modules/shell-aliases-data.nix（与系统 shell 共享的纯数据）。
  # 不要在本模块里再手写 eza 的 flag。
  shellData = import ../../modules/shell-aliases-data.nix;
in
{
  programs.fish = {
    enable = true;
    shellAliases = shellData.aliases;
    interactiveShellInit = ''
      # fzf + fd
      set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
      set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
      set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"

      # 初次进入终端时先列一次当前目录；之后的目录切换由 __eza_on_cd 负责。
      __eza_auto_list
    '';
    functions = {
      restart = ''
        if test (count $argv) -eq 0
          echo "用法: restart <进程名> [参数...]"
          return 1
        end
        pkill -f "$argv[1]"
        sleep 1
        $argv &>/dev/null &
        disown
      '';

      # ── 自动列目录 ─────────────────────────────────────────────
      # 进入终端时、以及每次目录变化后自动跑一次 eza。
      # 参数由 modules/shell-aliases-data.nix 提供，和 ll/la/lt 同一处定义。
      # 布局是多列的「详细网格」（--long --grid）：紧凑，且能显示 git 标记列。
      # 超过 50 项只列前 50 项并提示省略了多少；改上限就改下面的 limit。
      # 临时关掉（仅当前会话生效）： set -g EZA_NO_AUTO 1
      __eza_auto_list = ''
        # 只给交互式 shell 用；脚本/管道/命令替换里不打印
        status is-interactive; or return 0

        # fish 在 cd 到同一目录时也会发 PWD 事件，所以按「上次处理过的目录」去重。
        # 这两行必须排在 EZA_NO_AUTO 之前：关闭期间的 cd 也要同步状态，
        # 否则重新开启后会拿一个过期目录去比对，多列或漏列一次。
        set -q _eza_last_dir; and test "$_eza_last_dir" = "$PWD"; and return 0
        set -g _eza_last_dir "$PWD"

        set -q EZA_NO_AUTO; and return 0

        set -l limit 50
        set -l eza_flags ${shellData.ezaAutoListFlags}
        set -l name_flags ${shellData.ezaListNamesFlags}

        # 枚举走 eza 自己，不用 ls：ls 按 locale 排序（file-10 排在 file-2 前），
        # 截出来的前 50 跟屏幕上 eza 的顺序对不上。两处都要显式给一个 . ，
        # 因为 eza 在 stdin 不是终端时会改从 stdin 读文件名，不给路径会得到空集。
        # count 从管道读，只留一个数字，不把大目录的名字全读进内存。
        set -l total (command eza $name_flags . | count)

        if test $total -le $limit
            command eza $eza_flags .
        else
            # 按条目截断而不是按行：详细网格一行放多个条目，管道给 head 会横切一行。
            # -d 让目录参数只显示自身而不展开内容；-- 让以 - 开头的文件名不被当选项。
            set -l names (command eza $name_flags . | head -n $limit)
            command eza $eza_flags -d -- $names

            # string join 必须加 -- ：$eza_flags 以 --group-directories-first 开头，
            # 不加的话 fish 会把第一个 flag 当成 string 自己的选项而报错。
            printf '\n… 已省略 %d 项（共 %d 项，只列前 %d）。看全部：eza %s .\n' \
                (math $total - $limit) $total $limit (string join ' ' -- $eza_flags)
        end
      '';

      # PWD 变化 → 触发列目录。cd / z / pushd 都会触发。
      __eza_on_cd = {
        onVariable = "PWD";
        body = "__eza_auto_list";
      };

      # 终端代理开关：终端不读 KDE 系统代理，需手动设环境变量
      # 用法：proxy on / proxy off / proxy
      proxy = ''
        switch "$argv[1]"
          case on
            set -gx http_proxy http://127.0.0.1:7897
            set -gx https_proxy http://127.0.0.1:7897
            set -gx all_proxy socks5://127.0.0.1:7897
            echo "终端代理已开启 (127.0.0.1:7897)"
          case off
            set -e http_proxy
            set -e https_proxy
            set -e all_proxy
            echo "终端代理已关闭"
          case '*'
            if set -q http_proxy
              echo "终端代理: ON ($http_proxy)"
            else
              echo "终端代理: OFF"
            end
        end
      '';
    };
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      continuation_prompt = "[▸▹ ](dimmed white)";
      format = "($nix_shell$container$fill$git_metrics\n)$cmd_duration$hostname$localip$shlvl$shell$env_var$jobs$sudo$username$character";
      right_format = "$singularity$kubernetes$directory$vcsh$fossil_branch$git_branch$git_commit$git_state$git_status$hg_branch$pijul_channel$docker_context$package$c$cpp$cmake$cobol$daml$dart$deno$dotnet$elixir$elm$erlang$fennel$fortran$golang$guix_shell$haskell$haxe$helm$java$julia$kotlin$gradle$lua$maven$nim$nodejs$bun$ocaml$opa$perl$php$pulumi$purescript$python$raku$rlang$red$ruby$rust$scala$solidity$swift$terraform$vlang$vagrant$xmake$zig$buf$conda$pixi$meson$spack$memory_usage$aws$gcloud$openstack$azure$crystal$custom$status$os$battery$time";

      fill.symbol = " ";

      character = {
        format = "$symbol ";
        success_symbol = "[◎](bold italic bright-yellow)";
        error_symbol = "[○](italic purple)";
        vimcmd_symbol = "[■](italic dimmed green)";
        vimcmd_replace_one_symbol = "◌";
        vimcmd_replace_symbol = "□";
        vimcmd_visual_symbol = "▼";
      };

      sudo = {
        format = "[$symbol]($style)";
        style = "bold italic bright-purple";
        symbol = "⋈┈";
        disabled = false;
      };

      username = {
        style_user = "bright-yellow bold italic";
        style_root = "purple bold italic";
        format = "[⭘ $user]($style) ";
        disabled = false;
        show_always = false;
      };

      directory = {
        home_symbol = " ";
        truncation_length = 3;
        truncation_symbol = "…/";
        read_only = " ◈";
        use_os_path_sep = true;
        style = "italic blue";
        format = "[$path]($style)[$read_only]($read_only_style)";
        repo_root_style = "bold blue";
        repo_root_format = "[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) [△](bold bright-blue)";
      };

      directory.substitutions = {
        "Documents" = "󰈙 ";
        "Downloads" = " ";
        "Music" = " ";
        "Pictures" = " ";
      };

      cmd_duration.format = "[◄ $duration ](italic white)";

      jobs = {
        format = "[$symbol$number]($style) ";
        style = "white";
        symbol = "[▶](blue italic)";
      };

      git_branch = {
        format = " [$branch(:$remote_branch)]($style)";
        symbol = "";
        style = "italic bright-blue";
        truncation_symbol = "⋯";
        truncation_length = 11;
        ignore_branches = ["main" "master"];
        only_attached = true;
      };

      git_metrics = {
        format = "([▴$added]($added_style))([▿$deleted]($deleted_style))";
        added_style = "italic dimmed green";
        deleted_style = "italic dimmed red";
        ignore_submodules = true;
        disabled = false;
      };

      git_status = {
        style = "bold italic bright-blue";
        format = "([⎪$ahead_behind$staged$modified$untracked$renamed$deleted$conflicted$stashed⎥]($style))";
        conflicted = "[◪◦](italic bright-magenta)";
        ahead = "[▴│[\${count}](bold white)│](italic green)";
        behind = "[▿│[\${count}](bold white)│](italic red)";
        diverged = "[◇ ▴┤[\${ahead_count}](regular white)│▿┤[\${behind_count}](regular white)│](italic bright-magenta)";
        untracked = "[◌◦](italic bright-yellow)";
        stashed = "[◃◈](italic white)";
        modified = "[●◦](italic yellow)";
        staged = "[▪┤[$count](bold white)│](italic bright-cyan)";
        renamed = "[◎◦](italic bright-blue)";
        deleted = "[✕](italic red)";
      };

      nix_shell = {
        style = "bold bright-blue bg:#394260";
        symbol = "❄️";
        format = "[$symbol$nix_shell]($style)";
        impure_msg = "[⌽](bold red)";
        pure_msg = "[⌾](bold green)";
        unknown_msg = "[◌](bold yellow)";
      };

      nodejs = {
        format = " [node](italic) [ ($version)](bold bright-green)";
        version_format = "\${raw}";
      };

      python = {
        format = " [py](italic) [\${symbol}\${version}]($style)";
        symbol = "[⌉](bold bright-blue)⌊ ";
        version_format = "\${raw}";
        style = "bold bright-yellow";
      };

      rust = {
        format = " [rs](italic) [$symbol$version]($style)";
        symbol = " ";
        version_format = "\${raw}";
        style = "bold red";
      };

      golang = {
        symbol = " ";
        format = " go [$symbol($version )]($style)";
      };

      bun = {
        symbol = " ";
        format = " [bun](italic) [ ($version)](bold bright-green)";
        version_format = "\${raw}";
      };

      php = {
        symbol = " ";
        format = " [php](italic) [ ($version)](bold bright-green)";
        version_format = "\${raw}";
      };

      os = {
        style = "bg:##a0a9cb fg:#090c0c";
        format = "[ $symbol ]($style)";
        disabled = false;
      };

      os.symbols = {
        Windows = "󰍲";
        Ubuntu = "󰕈";
        SUSE = "";
        Raspbian = "󰐿";
        Mint = "󰣭";
        Macos = "󰀵";
        Manjaro = "";
        Linux = "󰌽";
        Gentoo = "󰣨";
        Fedora = "󰣛";
        Alpine = "";
        Amazon = "";
        Android = "";
        AOSC = "";
        Arch = "󰣇";
        Artix = "󰣇";
        EndeavourOS = "";
        CentOS = "";
        Debian = "󰣚";
        Redhat = "󱄛";
        RedHatEnterprise = "󱄛";
        Pop = "";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:#1d2230";
        format = "[ $time ](fg:#a0a9cb bg:#1d2230)($style)";
      };
    };
  };
}
