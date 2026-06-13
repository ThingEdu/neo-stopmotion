# Branch & Phase Naming Convention — neo-stopmotion

> **Status**: Active · Companion: `working-modes-policy.md`, `two-layer-separation.md`

## 1. Mô hình nhánh (đặc thù dự án này)

Khác với dự án thường: **tầng team không bao giờ vào `main`**. Vì vậy có một
**nhánh nền team** giữ tầng team, và các nhánh việc tách ra từ nó.

```
main                       ← team khác dùng; CHỈ code sản phẩm
  └── team                 ← NHÁNH NỀN: chứa docs/ + .claude/ + CLAUDE.md + AGENTS.md
        ├── feat/<name>     ← cut từ team → thừa hưởng tầng team
        ├── fix/<name>
        ├── lab/<name>
        └── docs/<name>
```

- Việc mới: `git switch team && git switch -c feat/<short-name>`.
- Cập nhật tài liệu: merge `feat/* → team` (đầy đủ).
- Đưa code lên main: `bash docs/02-architecture/ops/ship-to-main.sh` (xem `two-layer-separation.md`). **Không** merge thẳng vào main.

## 2. Format nhánh

```
<type>/<short-name>
```

| Type | Mục đích | Working Mode | Lên main? |
|------|----------|--------------|-----------|
| `lab` | Spike, prototype, thử nghiệm | Lab | Không bao giờ |
| `feat` | Feature / bug có spec | Feature | Code-only PR (PO merge) |
| `foundation` | Trích asset sạch từ lab | Foundation | Code-only PR |
| `fix` | Hotfix ngoài phase | Hotfix | Code-only PR |
| `docs` | Policy, kiến trúc, tài liệu team | Strategy | **Không lên main** (chỉ về `team`) |

Ví dụ: `feat/fps-selector`, `fix/io1-double-capture`, `lab/onion-skin-gpu`, `docs/working-modes`.

> Lưu ý: nhánh `docs/*` ở dự án này chỉ về `team`, **không** lên main (vì là tầng team).

## 3. Phase folder
Đánh số theo roadmap trong `docs/04-phases/`:
```
docs/04-phases/
├── claude-active-phase.md
├── _compliance-violations.md
├── phase-01-.../ { session-log.md, task-board.md, wave-1/T-001-*.md }
└── hotfixes/ { index.md, backlog.md, <name>/summary.md }
```

## 4. Auto-resolution working mode (Coordinator đọc lúc SESSION START)
```
team             -> TEAM-BASE (chỉ cập nhật tầng team, không code sản phẩm trực tiếp)
feat/*           -> FEATURE
fix/*            -> HOTFIX
lab/*            -> LAB
foundation/*     -> FOUNDATION
docs/*           -> STRATEGY
main             -> STOP (không bao giờ làm trực tiếp)
khác             -> hỏi PO
```

## 5. Edge cases
| Tình huống | Quy tắc |
|-----------|---------|
| Trùng tên | thêm hậu tố `-a`, `-b` |
| Không chắc type | hỏi PO trước khi tạo nhánh |
