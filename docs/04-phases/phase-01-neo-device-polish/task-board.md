# Task Board — Phase: phase-01-neo-device-polish

> **Cập nhật**: 2026-06-15

## Tổng quan
| Metric | Count |
|--------|-------|
| Tổng task | 8 |
| ⚪ TODO | 1 |
| 🔵 IN_PROGRESS | 0 |
| 🔴 BLOCKED | 0 |
| 🟣 REVIEW | 5 |
| 🟢 DONE | 2 |

---

## Wave 1: NEO One Device Polish — 2 issue thiết bị thực
| ID | Task | Owner | Status | Scope | Deps | Notes |
|----|------|-------|--------|-------|------|-------|
| T-001 | GStreamer H.264 codec — phim tự play trên NEO | devops | 🟣 REVIEW | app | - | Codec cài + app patch demote hw decoder (v4l2slh264dec). Chờ PO test autoplay trên GUI |
| T-002 | Desktop launcher icon — icon ngoài màn hình XFCE | devops | 🟣 REVIEW | app | - | Launcher /home/neo/Desktop tạo, +x, owner neo. Chờ PO test bấm đúp |

---

## Wave 2: Frame review + delete — bé xoá ảnh không ưng ý
> Spec: `docs/01-specs/features/frame-review-delete/` (spec.md + design-spec.md, PO đã chốt 5 quyết định)

| ID | Task | Owner | Status | Scope | Deps | Notes |
|----|------|-------|--------|-------|------|-------|
| T-003 | Core delete_frame(n) + re-sequence + signal (TDD) | python-dev | 🟢 DONE | app | - | 19 test PASS (9 P0+); ruff/mypy core sạch |
| T-004 | UI filmstrip xem lại + xoá frame bất kỳ | python-dev | 🟢 DONE | app | T-003 | PO xác nhận xoá frame chạy trên thiết bị (2026-06-14). Kèm fix layout preview bị cắt |

---

## Wave 3: Polish trải nghiệm — camera / tốc độ / lưu video (3 quick-win)
> Từ 4 vấn đề PO nêu 2026-06-15. Phần chiến lược (#2 phân phối) → `docs/04-phases/roadmap.md`.
> Mỗi task đi pipeline: BA spec → ux design → PO duyệt → python-dev. `design_required: yes`.

| ID | Task | Owner | Status | Scope | Deps | Notes |
|----|------|-------|--------|-------|------|-------|
| T-005 | Chọn camera input (picker + live preview, xoay index) | python-dev | 🟣 REVIEW | app | - | Architect PASS. 90 test PASS. Chờ PO test live preview + đổi camera trên GUI |
| T-006 | Chọn tốc độ / FPS video thành phẩm | python-dev | 🟣 REVIEW | app | - | Architect PASS. Smoke xác nhận file ra đúng fps. Chờ PO test + emoji trên NEO |
| T-007 | Lưu / tải video về máy/USB | python-dev | 🟣 REVIEW | app | - | Architect PASS. Lưu MP4 + copy link. Chờ PO test dialog lưu trên GUI |
| T-008 | Phóng to khung preview CapturePage (UX layout) | ux-designer | ⚪ TODO | app | - | PO test 2026-06-15: preview quá bé. Redesign layout → ux trước |

---

## Roadmap (làm sau) — `docs/04-phases/roadmap.md`
- **R-1** Đóng gói & phân phối build (chiến lược, P1) — chờ PO trả 4 câu hỏi (Apple Dev $99? khách kỹ thuật? online/USB? auto-update?)
- **R-2** Trang đích download điện thoại (gộp R-1) · **R-3** camera tên thiết bị/Qt · **R-4** re-render đổi tốc độ sau export

---

## Blocked
_(không có)_

## Legend
⚪ TODO · 🔵 IN_PROGRESS · 🔴 BLOCKED · 🟣 REVIEW · 🟢 DONE

## WIP
| Loại | Đang dở | Limit | Trạng thái |
|------|---------|-------|-----------|
| Feature | 0 | 3 | OK |
