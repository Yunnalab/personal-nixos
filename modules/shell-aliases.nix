{ ... }:
let
  # 别名表来自共享纯数据。改别名或改 eza 参数都改那个文件，这里不要手写。
  aliases = (import ./shell-aliases-data.nix).aliases;
in
#常用命令简化
{
  environment.shellAliases = aliases;
}
