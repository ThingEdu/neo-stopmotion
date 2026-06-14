# Task Board — Phase: phase-01-neo-device-polish

> **Cập nhật**: 2026-06-14

## Tổng quan
| Metric | Count |
|--------|-------|
| Tổng task | 4 |
| ⚪ TODO | 0 |
| 🔵 IN_PROGRESS | 0 |
| 🔴 BLOCKED | 0 |
| 🟣 REVIEW | 2 |
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

## Blocked
_(không có)_

## Legend
⚪ TODO · 🔵 IN_PROGRESS · 🔴 BLOCKED · 🟣 REVIEW · 🟢 DONE

## WIP
| Loại | Đang dở | Limit | Trạng thái |
|------|---------|-------|-----------|
| Feature | 0 | 3 | OK |
