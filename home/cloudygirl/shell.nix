{ pkgs, ... }:

let
  aliases = import ../../modules/shell-aliases-data.nix;
in
{
  programs.fish = {
    enable = true;
    shellAliases = aliases;
    interactiveShellInit = ''
      # fzf + fd
      set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
      set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
      set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"
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
