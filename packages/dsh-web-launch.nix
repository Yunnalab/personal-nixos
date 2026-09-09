{ writeShellApplication, curl, pnpm, nodejs_22, google-chrome }:

# 先启动本地 DeepSeek Harness 后端，再打开浏览器。
writeShellApplication {
  name = "dsh-web-launch";
  runtimeInputs = [ curl pnpm nodejs_22 google-chrome ];
  text = ''
    HARNESS_DIR="/home/cloudygirl/deepseek-harness"
    URL="http://127.0.0.1:3080"
    LOG="/tmp/dsh-web.log"

    # 后端未运行则先启动
    if ! curl -sf -o /dev/null "$URL"; then
      cd "$HARNESS_DIR" || exit 1
      nohup pnpm dsh web >> "$LOG" 2>&1 &
      for _ in {1..60}; do
        curl -sf -o /dev/null "$URL" && break
        sleep 1
      done
    fi

    exec google-chrome "$URL"
  '';
}
