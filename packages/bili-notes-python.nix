{ python3 }:

# B 站视频笔记 skill 的 Python 运行环境
# 依赖：yt-dlp / imagehash / rapidocr-onnxruntime / python-docx / pillow / requests / python-dotenv
python3.withPackages (ps: with ps; [
  yt-dlp
  imagehash
  rapidocr-onnxruntime
  python-docx
  pillow
  requests
  python-dotenv
])
