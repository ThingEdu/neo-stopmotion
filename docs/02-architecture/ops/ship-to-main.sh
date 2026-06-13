#!/usr/bin/env bash
#
# ship-to-main.sh — Đưa CHỈ code sản phẩm từ nhánh team/feature hiện tại sang
# một nhánh PR sạch tách từ main. Tầng team (docs/, .claude/, .agents/,
# CLAUDE.md, AGENTS.md, .codex/, .mcp.json) KHÔNG BAO GIỜ được mang theo.
#
# Vì sao cần script này:
#   Nhánh của chúng ta commit cả code lẫn tầng team. `git merge` thường sẽ kéo
#   tất cả sang main. Script dựng một nhánh PR mới từ origin/main rồi CHỈ áp các
#   thay đổi thuộc danh sách đường dẫn code → main luôn sạch, không lẫn team layer.
#
# Cách dùng:
#   bash docs/02-architecture/ops/ship-to-main.sh [ten-nhanh-pr]
#   # mặc định nhánh PR: ship/<nhánh-hiện-tại>
#
# Biến môi trường:
#   BASE_BRANCH   nhánh đích (mặc định: main)
#
set -euo pipefail

BASE="${BASE_BRANCH:-main}"
SRC_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PR_BRANCH="${1:-ship/${SRC_BRANCH}}"

# === Danh sách đường dẫn CODE được phép vào main ===
# Thêm/bớt ở đây khi cấu trúc sản phẩm thay đổi. KHÔNG thêm docs/ .claude/ v.v.
PRODUCT_PATHS=(
  src
  firmware
  tests
  scripts
  pyproject.toml
  requirements.txt
  requirements-dev.txt
  Makefile
  README.md
  README-en.md
  CHANGELOG.md
  LICENSE
  .gitignore
)

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: Đang có thay đổi chưa commit. Hãy commit trên nhánh '$SRC_BRANCH' trước." >&2
  exit 1
fi

echo ">> Fetch origin/$BASE ..."
git fetch origin "$BASE"

echo ">> Tạo nhánh PR sạch '$PR_BRANCH' từ origin/$BASE ..."
git switch -c "$PR_BRANCH" "origin/$BASE"

echo ">> Áp thay đổi (thêm/sửa) cho các đường dẫn code ..."
for p in "${PRODUCT_PATHS[@]}"; do
  git checkout "$SRC_BRANCH" -- "$p" 2>/dev/null || true
done

echo ">> Áp các file code bị XOÁ trên nhánh nguồn ..."
git diff --diff-filter=D --name-only "origin/$BASE" "$SRC_BRANCH" -- "${PRODUCT_PATHS[@]}" \
  | while read -r f; do
      [ -n "$f" ] && git rm -q --ignore-unmatch -- "$f" || true
    done

echo
echo ">> Trạng thái nhánh PR (chỉ nên thấy đường dẫn code):"
git status --short

echo
echo "Bước tiếp theo:"
echo "  bash docs/02-architecture/ops/check-no-team-files.sh   # xác nhận không rò rỉ team layer"
echo "  git commit -m \"<mô tả>\""
echo "  git push -u origin $PR_BRANCH"
echo "  gh pr create --base $BASE --title \"...\" --body \"...\""
