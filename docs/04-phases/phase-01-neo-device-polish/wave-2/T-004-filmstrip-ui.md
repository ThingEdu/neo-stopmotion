---
id: T-004
title: "UI: Filmstrip xem lại + xoá frame bất kỳ trên CapturePage"
assignee: "python-dev"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-2"
priority: "P0"
scope: "app"
ui: "yes"
design_required: "yes"
design_ref: "docs/01-specs/features/frame-review-delete/design-spec.md"
dependencies: ["T-003"]
spec_ref: "docs/01-specs/features/frame-review-delete/spec.md"
references:
  - "src/neo_stopmotion/ui/qml/pages/CapturePage.qml"
  - "src/neo_stopmotion/ui/qml/components/FrameCounter.qml"
  - "src/neo_stopmotion/ui/qml/singletons/AppState.qml"
  - "src/neo_stopmotion/ui/qml/singletons/NeoConstants.qml"
---

# T-004: Filmstrip xem lại + xoá frame bất kỳ (UI)

## Mục tiêu
Bé xem lại các frame đã chụp dưới dạng dải thumbnail ngang, chọn một tấm và xoá
(có xác nhận). Theo design-spec đã được PO duyệt.

## Phụ thuộc
**T-003 phải xong trước** (cần `handle_delete_frame(n)` + signal `frame_deleted`).

## Design (đã PO duyệt) — `design-spec.md`
- FilmStrip ngang dưới LivePreview/FrameCounter, trước HintBar. Thumbnail ~80x60, có số thứ tự.
- Bấm thumbnail → viền cam + phóng to nhẹ (≈150ms) → nút đỏ "XOÁ TẤM NÀY" active.
- Bấm xoá → dialog "Xoá tấm số N nhé?" với "THÔI ĐÃ" (focus mặc định) + "XOÁ ĐI!".
- Nút Z + ThingBot UNDO giữ nguyên (xoá nhanh frame cuối, KHÔNG dialog).
- Bàn phím: ← → chọn thumbnail, Delete mở dialog, Escape huỷ.

## Quyết định PO (2026-06-14)
- NEO One **không cảm ứng** → chuột + bàn phím. Target to/rõ.
- Filmstrip cuộn ngang hiện **tất cả** frame (tối đa ~100).
- Thumbnail dùng **file:// + cache-busting** (`cache:false` hoặc timestamp suffix) để không hiện ảnh cũ sau re-sequence.
- Append-only: sau khi xoá, chụp tiếp nối cuối.

## Acceptance Criteria
- [ ] **AC1** Component FilmStrip (mới, vd `ui/qml/components/FilmStrip.qml`) hiện thumbnail
  tất cả frame từ thư mục session, cuộn ngang, có số thứ tự. Trạng thái rỗng: thông báo thân thiện.
- [ ] **AC2** Chọn frame bằng chuột (bấm) và bàn phím (← →). Frame đang chọn nổi bật theo design.
- [ ] **AC3** Nút "XOÁ TẤM NÀY" + dialog xác nhận (mặc định "THÔI ĐÃ"). Xác nhận → gọi
  `appController.handle_delete_frame(n)`. Phím Delete mở dialog, Escape huỷ.
- [ ] **AC4** Khi nhận signal `frame_deleted` → refresh filmstrip + FrameCounter (reload từ danh sách file, cache-busting).
- [ ] **AC5** Nút Z + ThingBot UNDO vẫn xoá nhanh frame cuối, không hồi quy.
- [ ] **AC6** Consistency với NeoConstants (primary, spacing, font). Không hardcode màu rời rạc.
- [ ] **AC7** Smoke headless không lỗi QML:
  `NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion` chạy không lỗi.
- [ ] **AC8** PO verify trên thiết bị NEO (GUI): chụp vài frame → bấm thumbnail giữa → xoá → đúng tấm biến mất, các tấm sau dồn lại, export vẫn ra phim đúng.

## Files to Touch
| File | Thay đổi |
|------|---------|
| `src/neo_stopmotion/ui/qml/components/FilmStrip.qml` | TẠO MỚI — dải thumbnail + chọn |
| `src/neo_stopmotion/ui/qml/pages/CapturePage.qml` | Nhúng FilmStrip + nút xoá + dialog + keyboard |
| `src/neo_stopmotion/ui/qml/singletons/AppState.qml` | (nếu cần) state frame đang chọn / danh sách frame |
| `src/neo_stopmotion/app.py` hoặc image_provider | (nếu chọn ImageProvider thay vì file://) |

## Output Contract
- [ ] Smoke headless PASS (AC7) + `make lint` PASS
- [ ] design-spec được tuân thủ; lệch thì ghi rõ lý do
- [ ] Chờ PO verify GUI trên thiết bị (AC8) → DONE
