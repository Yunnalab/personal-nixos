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
  # Fish hook 用：common 的等效参数 + 详细视图 + git 状态列。
  #
  # 两个与别名不同、不能换成 --icons=auto 的地方：
  #   1) git 标记（-M 已改 / -N 未跟踪）只在详细视图里画得出来，网格模式下
  #      --git / --git-repos / --git-repos-no-status 都不显示（已实测）；
  #   2) hook 要把输出管道给 head 做 50 条截断，而 eza 的 --color/--icons 看的是
  #      它自己的 stdout 是不是终端，所以必须写 always，否则管道里会掉色掉图标。
  # -l + --no-* 只保留名字和 git 标记列，与 --icons=auto 在真终端下渲染一致。
  ezaAutoListFlags = concat (
    [ "--group-directories-first" "--icons=always" "--color=always" ]
    ++ [ "-l" "--no-user" "--no-permissions" "--no-time" "--no-filesize" "--git" ]
  );

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
