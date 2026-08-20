#!/bin/bash
# 在本機啟動一個簡易 HTTP 伺服器，方便在電腦或同 Wi-Fi 的手機上預覽 index.html
set -euo pipefail
cd "$(dirname "$0")"

PORT=8001

IP="$(ipconfig getifaddr en0 2>/dev/null || true)"
if [ -z "$IP" ]; then
  IP="$(ipconfig getifaddr en1 2>/dev/null || true)"
fi

echo "電腦上預覽：http://localhost:${PORT}"
if [ -n "$IP" ]; then
  echo "手機上預覽（要同一個 Wi-Fi）：http://${IP}:${PORT}"
else
  echo "手機上預覽：抓不到區網 IP（en0/en1 都失敗），請確認已連上 Wi-Fi"
fi

python3 -m http.server "$PORT"
