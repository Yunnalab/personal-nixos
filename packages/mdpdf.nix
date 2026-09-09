{ writeShellScriptBin, coreutils, pandoc }:

# Markdown 转 PDF
# 用法：mdpdf note.md [output.pdf]
writeShellScriptBin "mdpdf" ''
  set -euo pipefail

  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: mdpdf INPUT.md [OUTPUT.pdf]" >&2
    exit 2
  fi

  input="$(${coreutils}/bin/realpath "$1")"
  if [ "$#" -eq 2 ]; then
    output="$(${coreutils}/bin/realpath -m "$2")"
  else
    output="''${input%.*}.pdf"
  fi

  workdir="$(${coreutils}/bin/dirname "$input")"
  filename="$(${coreutils}/bin/basename "$input")"

  cd "$workdir"
  exec ${pandoc}/bin/pandoc "$filename" \
    -d ${../notes/template/pandoc.yaml} \
    -o "$output"
''
