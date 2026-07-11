#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
URL="http://127.0.0.1:5173"

if ! pgrep -f "vite --host 127.0.0.1 --port 5173 --strictPort" >/dev/null 2>&1; then
  (cd "$ROOT_DIR" && npm run dev >/tmp/nudge-video.log 2>&1 &)
  sleep 2
fi

open -a "Google Chrome" "$URL"
