#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$ROOT_DIR"
npm run build
open -a "Google Chrome" "$ROOT_DIR/dist/index.html"
