# Tầng vận hành team — neo-stopmotion

Thư mục `docs/` là **tầng team**: nghiên cứu, spec, kiến trúc/policy, theo dõi phase,
template. Song song với `DOC/` (tài liệu sản phẩm gốc) và **không bao giờ merge vào `main`**.

> Cơ cấu & quy trình tham khảo team `MySpace/bap-bean-book` (Agent Teams mode), điều
> chỉnh cho ứng dụng Python desktop (PyQt6/QML) + firmware ThingBot, và layer thêm
> luật tách 2 tầng (xem `02-architecture/two-layer-separation.md`).

## Cấu trúc

| Thư mục / file | Nội dung |
|----------------|----------|
| `WORKING-WITH-PO.md` | Cẩm nang giao tiếp & phối hợp với PO (đọc trước tiên) |
| `product-kanban.md` | Bảng feature cấp cao (PM/Coordinator) |
| `00-research/` | R&D, benchmark, tâm lý/giáo dục |
| `01-specs/features/<key>/` | Spec từng feature: `product-brief.md` (PM), `manifest.yml`+`spec.md`+`domain.md` (BA) |
| `02-architecture/` | `working-modes-policy.md`, `branch-naming-convention.md`, `two-layer-separation.md`, `ops/`, `adrs/` |
| `03-codebase/` | Ghi chú codebase + `design/` + `devops/runbooks/`; trỏ về `DOC/ARCHITECTURE.md` |
| `04-phases/` | `claude-active-phase.md`, `_compliance-violations.md`, `<phase>/`, `hotfixes/` |
| `05-system-state/` | Ảnh chụp hạ tầng/release/luồng dữ liệu/issues |
| `99-templates/` | Template cho mọi tài liệu trên |

## Hai luật cốt lõi

1. **Tầng team không vào main.** Code lên main chỉ qua `02-architecture/ops/ship-to-main.sh`
   (code-only PR). Chi tiết: `02-architecture/two-layer-separation.md`.
2. **Spec-first + Architect gate.** ba/pm viết spec → (ux design nếu cần) → dev code +
   test → architect PASS → ship. Chi tiết: `02-architecture/working-modes-policy.md`.

## Bắt đầu
- Cơ cấu team & vai trò: `AGENTS.md` (root) + `CLAUDE.md` (root).
- Quy trình & session protocol: `02-architecture/working-modes-policy.md` + `CLAUDE.md` §SESSION.
- PO gõ `SESSION START` để Coordinator báo cáo trạng thái phase đang chạy.
