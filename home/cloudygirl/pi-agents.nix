{ lib, pkgs, ... }:

# pi 的多 agent 配置。
#
# pi 刻意不内置 sub-agent：自带 README 的 Philosophy 一节写明「No sub-agents.
# Spawn pi instances via tmux」。本机已安装 pi-subagents 包
# （settings.json 里的 git:github.com/edxeth/pi-subagents）负责派发任务，
# tmux 只是它的 interactive 后端。
#
# 这里放三样东西：
#   1. agents/*.md  子 agent 的角色定义，部署到 ~/.pi/agent/agents/
#   2. agent-farm   一个仓库多个 worktree + 多个 tmux 窗口的启动器
#   3. tmux.nix     窗口、键位与 extended-keys，见该文件
#
# 注意：下面这些 md 会以指向 store 的只读软链落地，因此 pi 的 /subagents
# 面板里按 Space 切换 enabled 会写盘失败。要启停某个 agent，请改
# config/pi/agents/ 里对应文件的 enabled 字段，再 rebuild。
{
  home.file = {
    ".pi/agent/agents/scout.md".source = ./config/pi/agents/scout.md;
    ".pi/agent/agents/builder.md".source = ./config/pi/agents/builder.md;
    ".pi/agent/agents/reviewer.md".source = ./config/pi/agents/reviewer.md;
  };

  # 与 packages.nix 一致用 mkAfter：显式安装的包排在程序模块自动添加的包之后。
  home.packages = lib.mkAfter [
    (pkgs.callPackage ../../packages/agent-farm.nix { })
  ];
}
