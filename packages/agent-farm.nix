{ writeShellApplication, git, tmux, pi-coding-agent }:

# agent-farm <仓库路径> <agent 名>...
#
# 多 agent 协作的头号纪律是「一个 agent 一个工作树」：几个 agent 同时改同一份
# 检出会互相覆盖、制造假冲突。这个脚本把一个仓库按 agent 拆成若干 git
# worktree，再在同一个 tmux session 里给每个 agent 一个窗口，方便一眼看全。
#
# 每个窗口的起始目录就是那个 agent 独占的 worktree；pi-subagents 派发出来的
# 子 agent 默认继承父进程的 cwd，所以「父 agent 在哪个 worktree」等于
# 「它的子 agent 在哪个 worktree」。
#
# agent 定义本身由 home/cloudygirl/pi-agents.nix 部署到 ~/.pi/agent/agents/。
writeShellApplication {
  name = "agent-farm";
  runtimeInputs = [ git tmux pi-coding-agent ];
  text = ''
    usage() {
      cat <<'USAGE'
用法: agent-farm <仓库路径> <agent 名> [<agent 名> ...]

为每个 agent 在仓库父目录下创建独立 worktree（分支 agent/<名字>），
并在 tmux session "agents-<仓库名>" 里各开一个窗口运行 pi。

示例:
  agent-farm ~/code/proj scout builder reviewer
USAGE
    }

    if [ "$#" -lt 2 ]; then
      usage
      exit 2
    fi

    if ! repo=$(git -C "$1" rev-parse --show-toplevel); then
      echo "不是 git 仓库: $1" >&2
      exit 1
    fi
    shift

    repo_name=$(basename "$repo")
    parent=$(dirname "$repo")
    session="agents-$repo_name"

    # agent 名会进 tmux 窗口名、分支名和命令行，先收紧字符集。
    for name in "$@"; do
      case "$name" in
        "" | *[!A-Za-z0-9_-]*)
          echo "agent 名只能是字母、数字、下划线和短横线: '$name'" >&2
          exit 2
          ;;
      esac
    done

    if tmux has-session -t "=$session" 2>/dev/null; then
      echo "tmux 会话已存在，直接接入: $session" >&2
      exec tmux attach -t "=$session"
    fi

    # 先把所有 worktree 准备好再开会话，免得留下一个空窗口。
    rest=()
    first_name=""
    first_dir=""
    for name in "$@"; do
      wt="$parent/$repo_name-$name"
      branch="agent/$name"

      if [ -e "$wt/.git" ]; then
        echo "复用已有 worktree: $wt" >&2
      elif git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
        git -C "$repo" worktree add "$wt" "$branch"
      else
        git -C "$repo" worktree add "$wt" -b "$branch"
      fi

      if [ -z "$first_name" ]; then
        first_name="$name"
        first_dir="$wt"
      else
        rest+=("$name")
      fi
    done

    # 让 pi-subagents 明确用 tmux 当后端；子 agent 可以给窗口改名，
    # 这样窗口标题就直接显示出正在跑哪个子 agent。
    # 注意 tmux 的 -e 是「窗格环境」，必须在这里一次性给全。
    mux_env=(
      -e PI_SUBAGENT_MUX=tmux
      -e PI_SUBAGENT_ENABLE_SET_TAB_TITLE=1
      -e PI_SUBAGENT_RENAME_TMUX_WINDOW=1
    )

    # -c 决定 pi 的工作目录，也就是这个 agent 独占的 worktree。
    # 目标要写成 "$session:"：在 tmux 3.7 上 `new-window -t <session>` 会被当成
    # 「在 0 号窗口位置新建」而报 index in use。
    tmux new-session -d -s "$session" -n "$first_name" -c "$first_dir" \
      "''${mux_env[@]}" "pi -n $first_name"

    for name in "''${rest[@]}"; do
      tmux new-window -t "$session:" -n "$name" -c "$parent/$repo_name-$name" \
        "''${mux_env[@]}" "pi -n $name"
    done

    tmux select-window -t "$session:$first_name"
    exec tmux attach -t "$session"
  '';
}
