#!/usr/bin/env bash
#
# check-no-team-files.sh — Cổng bảo vệ: thất bại nếu phát hiện đường dẫn thuộc
# tầng team bị track trong cây hiện tại. Dùng trên nhánh PR (ship/*) trước khi
# push, hoặc làm CI check trên main.
#
set -euo pipefail

BANNED=(docs .claude .agents .codex CLAUDE.md AGENTS.md .mcp.json)
fail=0

for p in "${BANNED[@]}"; do
  if git ls-files -- "$p" | grep -q .; then
    echo "LEAK: tầng team bị track trên nhánh này: $p" >&2
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: không có đường dẫn tầng team nào bị track."
fi
exit "$fail"
