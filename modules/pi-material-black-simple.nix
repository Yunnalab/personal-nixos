# 给 pi 预打 material-black-simple 的渲染器补丁。
#
# 背景：pi 由 nixpkgs 装进 /nix/store（只读）。pi-material-black-simple 这个主题
# 扩展需要在 pi 的 dist 里改三处渲染代码（最终回答加底色、中间输出转灰、用户气泡
# 着色），运行时写盘必然 EROFS，功能也完全不生效。Nix 侧的做法是构建期就把补丁
# 打进去，扩展启动后看到 "already" 便不再写盘，报错自然消失。
#
# 补丁脚本：packages/pi-material-black-simple/patch-pi.mjs
# （锚点与注入片段逐字取自上游 patch.ts，只去了 TS 类型注解）
#
# 升级 pi 后若 dist 布局有变，脚本会打印告警但**不会**让 rebuild 失败，表现为
# 最终回答底色失效、扩展重新报 EROFS；此时对照上游更新脚本里的锚点即可。
{ ... }:

let
  patchScript = ../packages/pi-material-black-simple/patch-pi.mjs;

  # 不用 overrideAttrs 重编（那要重跑一遍 tsgo），而是把现成产物整棵拷进可写的
  # $out 再改。pi 目录里唯一引用自身 store 路径的是 bin/pi 和 bin/.pi-wrapped
  # 这两个 wrapper，改完 sed 指向新路径即可。
  patchPi =
    { pkgs, pi }:
    pkgs.runCommand "${pi.name}-material-black-simple" {
      nativeBuildInputs = [ pkgs.nodejs ];
      meta = pi.meta;
      passthru = pi.passthru or { };
    } ''
      mkdir -p $out
      # 保留权限位（含 bin/pi 的可执行位），但不要拷 owner，否则非 root 构建会报错
      cp -r --preserve=mode,links ${pi}/. $out/
      chmod -R u+w $out

      # 构建期不需要 .orig 备份，免得白占 store
      MBS_BACKUP_SUFFIX= node ${patchScript} $out/lib/node_modules/pi-monorepo

      sed -i "s|${pi}/|$out/|g" $out/bin/pi $out/bin/.pi-wrapped

      # 构建期自检：wrapper 指对了、补丁在位、CLI 能起来
      nm=$out/lib/node_modules/pi-monorepo
      echo "补丁状态：assistant=$(grep -c isIntermediate $nm/dist/modes/interactive/components/assistant-message.js)"
      echo "补丁状态：user=$(grep -c __mbsConfig $nm/dist/modes/interactive/components/user-message.js)"
      echo "补丁状态：bundle=$(grep -l 'function __mbsAssistantStyle' $nm/dist/bundle/chunks/*.js | wc -l) 个 chunk"
      export HOME=$TMPDIR
      got=$($out/bin/pi --offline --version)
      test "$got" = "${pi.version}" || {
        echo "pi 自检失败：--version 返回 '$got'，期望 '${pi.version}'" >&2
        exit 1
      }
    '';
in
{
  nixpkgs.overlays = [
    (final: prev: {
      pi-coding-agent = patchPi {
        pkgs = prev;
        pi = prev.pi-coding-agent;
      };
    })
  ];
}
