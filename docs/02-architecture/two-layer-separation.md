# Two-Layer Separation — tầng team không bao giờ vào main

> **Status**: Active · Đây là luật RIÊNG của dự án này, layer lên trên quy ước
> bap-bean-book. Đọc cùng `working-modes-policy.md` và `branch-naming-convention.md`.

## Vì sao
`main` được dùng chung với team khác. Tầng vận hành của chúng ta (quy trình, agents,
spec, phase log) **không được làm bẩn `main`**. Vì vậy chỉ **code sản phẩm** đi vào
`main`; toàn bộ tầng team ở lại trên nhánh `team` và các nhánh con của nó.

## Phân tầng

| Tầng | Đường dẫn | Vào `main`? |
|------|-----------|-------------|
| **Code sản phẩm** | `src/ firmware/ tests/ scripts/ pyproject.toml requirements*.txt Makefile README*.md CHANGELOG.md LICENSE .gitignore` | ✅ qua code-only PR |
| **Tầng team** | `docs/ .claude/ .agents/ CLAUDE.md AGENTS.md .mcp.json` | ❌ KHÔNG BAO GIỜ |

Tầng team **được commit** trên nhánh `team`/`feat/*` (có version control đầy đủ).
Việc loại nó khỏi main xảy ra **tại thời điểm đưa code lên main**, không bằng gitignore.

## Cơ chế: code-only PR

```bash
# Trên feat/<name>, sau khi đã commit hết:
bash docs/02-architecture/ops/ship-to-main.sh
#   → dựng nhánh ship/feat-<name> từ origin/main, CHỈ áp các đường dẫn code
bash docs/02-architecture/ops/check-no-team-files.sh   # cổng chống rò rỉ
git commit -m "feat: ..."
git push -u origin ship/feat-<name>
gh pr create --base main
```

- `ship-to-main.sh`: dựng nhánh PR từ `origin/main`, chỉ `checkout` các đường dẫn
  trong `PRODUCT_PATHS`. Lịch sử `main` **chưa bao giờ** chứa file tầng team.
- `check-no-team-files.sh`: thất bại nếu phát hiện `docs/`, `.claude/`, `CLAUDE.md`…
  bị track trên nhánh PR. Có thể dùng làm CI check trên main.

## Quy tắc cứng
1. **Không bao giờ** `git merge feat/* → main` (sẽ kéo tầng team). Luôn dùng `ship-to-main.sh`.
2. Architect kiểm `check-no-team-files.sh` PASS trước khi duyệt PR lên main (gate).
3. Nhánh `docs/*` (cập nhật tầng team) chỉ merge về `team`, không lên main.
4. `PRODUCT_PATHS` trong `ship-to-main.sh` là nguồn chân lý cho "cái gì là code" —
   cập nhật khi cấu trúc sản phẩm thay đổi.

## Quan hệ với git policy của bap-bean-book
bap-bean-book cho team commit/push tự do trên nhánh non-main và để docs/ lên main.
Ta giữ phần "commit/push tự do trên non-main" nhưng **đảo luật docs**: tầng team
không lên main. Mọi chỗ khác (working modes, spec-first, architect gate) giữ nguyên.
