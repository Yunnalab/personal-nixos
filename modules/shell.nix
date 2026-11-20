{ ... }:

let
  # 别名表来自共享纯数据（Home Manager 的 Fish 也用同一份）。
  # 改别名或改 eza 参数都改那个文件，这里不要手写。
  aliases = (import ./shell-aliases-data.nix).aliases;
in
{
  # 系统编辑器（sudoedit、git commit 等不读 fish 的场合靠这两个变量）
  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  # 常用命令简化
  environment.shellAliases = aliases;
}
