# 系统 shell（modules/shell-aliases.nix）与用户 Fish（home/cloudygirl/shell.nix）
# 共享的纯数据，不是模块。导出两项：
#   ezaAutoListFlags —— Fish 自动列目录 hook 的参数串（不含 "eza" 前缀，hook 自己拼）
#   aliases          —— 两边共用的别名表
let
  # ── eza 参数的唯一来源 ──────────────────────────────────────────────
  # 别名 ll/la/lt 和 home/cloudygirl/shell.nix 的自动列目录 hook 都从这里取。
  # 要改 eza 的 flag 只改这里，不要在模块里再手写一份。
  # --icons=auto 只在真终端里画图标（eza 按终端宽度探测判断，不是 isatty）；
  # 实测与不带值的 --icons 输出逐字节相同，所以两类调用可以共用。
  ezaCommon = [ "--group-directories-first" "--icons=auto" ];
  concat = builtins.concatStringsSep " ";
  eza = flags: "eza " + concat flags;
in
{
  # Fish hook 用：common + git 状态列。
  #
  # ⚠️ 已知限制：网格（默认）布局下 --git / --git-repos / --git-repos-no-status 都不显示，
  #    输出与不带 --git 逐字节相同（已实测）。它只花掉一次 git status 的时间，不做任何可见的事。
  #    要看 git 标记（-M 已改 / -N 未跟踪）必须换详细视图，把下面这行改成：
  #      concat (ezaCommon ++ [ "-l" "--no-user" "--no-permissions" "--no-time" "--no-filesize" "--git" ])
  #    实测这样图标和 -M/-N 都能正常显示，但一行一个条目：本机 /tmp 有 400+ 项、~/nixpkgs
  #    有上万项，cd 过去会刷屏。默认因此保持紧凑的网格布局。
  ezaAutoListFlags = concat (ezaCommon ++ [ "--git" ]);

  aliases = {
    nixrs = "git -C /home/cloudygirl/nixos add -A && nh os switch";
    ncg = "nh clean all";
    rollback = "nh os rollback";
    nixinfo = "nh os info";
    gitupdate = "git add . && git commit -m 'update' && git push";
    codenix = "z /nixos && code .";
    # eza：不覆盖 ls，沿用原 ls
    ll = eza (ezaCommon ++ [ "-lh" ]);
    la = eza (ezaCommon ++ [ "-lah" ]);
    lt = eza ([ "--tree" "--level=2" ] ++ ezaCommon);
    # bat：不覆盖 cat，需要时用 bcat
    bcat = "bat --style=plain --paging=never";
  };
}
