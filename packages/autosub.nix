{ writeShellScriptBin, coreutils, wget, ffmpeg, whisper-cpp }:

# 视频自动生成字幕
# 用法：autosub 视频文件.mp4 [语言] [模型]
# 语言默认 zh（中文），可选 en/ja 等
# 模型默认 small，可选 tiny/base/small/medium/large-v3
writeShellScriptBin "autosub" ''
  set -euo pipefail

  if [ "$#" -lt 1 ]; then
    echo "Usage: autosub VIDEO [LANG] [MODEL]" >&2
    echo "  LANG:   zh(默认), en, ja, ko, ..." >&2
    echo "  MODEL:  tiny, base, small(默认), medium, large-v3" >&2
    exit 2
  fi

  input="$(${coreutils}/bin/realpath "$1")"
  lang="''${2:-zh}"
  model="''${3:-small}"

  model_dir="$HOME/.cache/whisper-cpp"
  model_file="$model_dir/ggml-$model.bin"

  if [ ! -f "$model_file" ]; then
    echo "Downloading model: $model ..." >&2
    ${coreutils}/bin/mkdir -p "$model_dir"
    ${wget}/bin/wget -q -O "$model_file" \
      "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-$model.bin"
  fi

  workdir="$(${coreutils}/bin/dirname "$input")"
  filename="$(${coreutils}/bin/basename "$input")"
  name="''${filename%.*}"

  tmpdir="$(${coreutils}/bin/mktemp -d)"
  ${ffmpeg}/bin/ffmpeg -i "$input" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$tmpdir/audio.wav" -y -loglevel error

  echo "Generating subtitles (model: $model, lang: $lang) ..." >&2
  ${whisper-cpp}/bin/whisper-cpp -m "$model_file" -f "$tmpdir/audio.wav" -l "$lang" -osrt -o "$tmpdir"

  ${coreutils}/bin/cp "$tmpdir/audio.srt" "$workdir/$name.srt"
  ${coreutils}/bin/rm -rf "$tmpdir"

  echo "Done: $workdir/$name.srt" >&2
''
