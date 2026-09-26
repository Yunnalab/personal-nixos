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
  # hook 显示用：eza 的「详细网格」——多列排布，每格前面带 git 标记列。
  #   纯网格（--grid）：--git / --git-repos 一列都不画（已实测）；
  #   纯详细（-l）：顺序一行一条，20 个文件占 20 行，太占屏幕。
  # --no-* 只掉用户/权限/时间/大小四列，名字与 git 标记保留。
  ezaAutoListDetail = [
    "--long" "--grid"
    "--no-user" "--no-permissions" "--no-time" "--no-filesize"
    "--git"
  ];
  # hook 枚举条目名用（结果会当参数回传给 eza，必须是干净的名字）：
  #   --no-quotes 必需：否则含空格的会被包成名 'a b.md'，回传时就成了不存在的文件；
  #   icons/color 关掉，避免 ANSI 混进名字里。
  ezaListNames = [ "-1" "--no-quotes" "--icons=never" "--color=never" "--group-directories-first" ];
  concat = builtins.concatStringsSep " ";
  eza = flags: "eza " + concat flags;
in
{
  # Fish hook 显示用（不含 "eza" 前缀，hook 里写成 `command eza $eza_flags`）。
  ezaAutoListFlags = concat (ezaCommon ++ ezaAutoListDetail);

  # Fish hook 枚举条目名用。
  ezaListNamesFlags = concat ezaListNames;

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
