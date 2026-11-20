{ pkgs, ... }:

let
  # Kazumi 内置的 libmpv 在 mpv_create() 里强制要求 LC_NUMERIC 是 C/POSIX：
  #   struct MPContext *mp_create(void) {
  #     if (!check_locale()) { fprintf(stderr, "Non-C locale detected..."); return NULL; }
  # 系统默认 LANG=zh_CN.UTF-8，GTK 启动时 setlocale(LC_ALL, "") 会把 LC_NUMERIC
  # 变成 zh_CN.UTF-8，于是 mpv_create() 返回 NULL，Kazumi 报
  #   PlayerController: failed to initialize video | Bad state: mpv_create failed
  # 表现就是「所有番剧源都解析失败 / 一直转圈」（跟代理、源无关）。
  # 这里在 wrapper 里把 LC_NUMERIC 钉成 C（不动 LC_ALL/LANG，界面仍是中文）。
  kazumi-c-locale = pkgs.symlinkJoin {
    name = "kazumi";
    paths = [ pkgs.kazumi ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/kazumi --set LC_NUMERIC C
    '';
  };
in
{
  # 替换原 kazumi（packages.nix 中不再重复列出，避免 bin 冲突）
  environment.systemPackages = [ kazumi-c-locale ];
}
