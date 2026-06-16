---
id: T-010
title: "Redesign CapturePage → Variant B (bám sát mockup) + thay T-008"
assignee: "python-dev"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-4"
priority: "P0"
scope: "app"
ui: "yes"
design_required: "yes"
design_ref: "docs/03-codebase/design/brand/html-mockups/02-capture-B.html (PO duyệt Variant B)"
dependencies: []
references:
  - "docs/04-phases/phase-01-neo-device-polish/wave-4/design-ref.md"
  - "src/neo_stopmotion/ui/qml/pages/CapturePage.qml"
  - "src/neo_stopmotion/ui/qml/components/ (FilmStrip, FrameCounter, LivePreview)"
  - "src/neo_stopmotion/ui/qml/singletons/NeoConstants.qml"
---

# T-010: Redesign CapturePage theo Variant B

## Mục tiêu
Dựng lại CapturePage theo **mockup Variant B**: preview lớn bên trái là tâm điểm; cột phải = huy hiệu đếm frame (vàng) + chọn tốc độ + 3 nút cốt lõi dọc (Chụp/Xoá/Tạo phim); filmstrip dải dưới đáy; thanh chú thích phím tắt; header có nút Đổi camera + Phim đã làm + Phím tắt. **Giải quyết luôn T-008 (preview quá bé).**

## Phạm vi
### Trong phạm vi
- Layout lại `CapturePage.qml` đúng mockup B (bỏ panel FrameCounter 240×320 cũ → huy hiệu vàng nhỏ trong cột phải).
- Cột phải: đếm frame (vàng, `fontFrameCount`), hộp chọn tốc độ (🐌🐇⚡ + số 1/2/3), nút CHỤP (cam, to), nút Xoá tấm (viền đỏ), nút TẠO PHIM (xanh lá, đáy cột).
- Filmstrip giữ chức năng cũ (T-004) nhưng đặt thành dải đáy + header "Các tấm đã chụp ◀▶".
- Header: logo + tiêu đề; phải = nút Đổi camera (`C`), Phim đã làm (`G` — emit signal điều hướng, để T-012 nối), Phím tắt (`?`).
- Dùng token `NeoConstants`; vùng chạm ≥ `touchMin`; khớp màu/cỡ chữ mockup.
- Footer legend phím tắt như mockup.

### Ngoài phạm vi
- Logic phím tắt chi tiết (T-011) — task này chỉ dựng UI + nút bấm + chừa hook signal.
- LibraryPage thực thi (T-012).

## Acceptance Criteria
- [ ] **AC1**: CapturePage render đúng bố cục Variant B (preview trái lớn, cột phải, filmstrip đáy).
  - **File**: `src/neo_stopmotion/ui/qml/pages/CapturePage.qml`
  - **Thay đổi**: layout RowLayout (preview | rail) + filmstrip dưới + legend; xoá panel FrameCounter cũ hoặc thu nhỏ thành badge.
- [ ] **AC2**: 3 nút cốt lõi (Chụp/Xoá/Tạo phim) hiển thị cỡ + màu như mockup; nút Tạo phim disable khi < `minFrames` (5) như hiện hành.
- [ ] **AC3**: Đếm frame + thời lượng cập nhật realtime (giữ binding `frameCountChanged`).
- [ ] **AC4**: Nút Đổi camera / Phim đã làm / Phím tắt có mặt; click phát đúng signal/mở popup (Phim đã làm: chừa stub gọi điều hướng).
- [ ] **AC5**: Đối chiếu ảnh chụp GUI ↔ mockup B: khớp về layout/màu (QA chấm).

## Test
### Lệnh
```bash
make test
make lint
NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion
```
Cổng chấp nhận:
- [ ] make test PASS (không hồi quy)
- [ ] ruff + mypy PASS
- [ ] Smoke headless chạy được; QML không lỗi runtime (console sạch)

## Output Contract khi xong
- [ ] CapturePage.qml + component liên quan cập nhật, bám sát mockup B.
- [ ] Ảnh chụp GUI gửi kèm cho QA/PO đối chiếu mockup.
- [ ] Sẵn sàng cho T-011 (phím tắt) + architect review.
