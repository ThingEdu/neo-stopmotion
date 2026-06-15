---
id: T-008
title: "Phóng to khung preview trên CapturePage (UX layout)"
assignee: "ux-designer"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-3"
priority: "P1"
scope: "app"
ui: "yes"
design_required: "yes"
design_ref: "N/A (ux-designer làm design trước)"
dependencies: []
references:
  - "docs/01-specs/features/camera-select/design-spec.md"
---

# T-008: Phóng to khung preview trên CapturePage

## Mục tiêu
Khung preview camera phải là tâm điểm thị giác (lớn nhất) trên màn chụp, thay vì nhỏ như hiện tại.

## Bối cảnh
PO chạy thử wave-3 trên Mac (2026-06-15): khung preview (live camera) **quá bé** trong khi đây là thứ quan trọng nhất để canh chụp. Thẻ FRAME counter + thanh tốc độ + khoảng trắng đang chiếm nhiều chỗ, lấn át preview. Xem ảnh PO gửi.

## Phạm vi
### Trong phạm vi
- Thiết kế lại tỉ lệ/bố cục CapturePage để **preview lớn, nổi bật**; các control phụ (FRAME counter, filmstrip, thanh tốc độ, nút) co lại hợp lý, không che/đẩy preview.
- Giữ đủ chỗ cho các thành phần wave-3 vừa thêm (nút "Đổi camera", thanh tốc độ) nhưng không để chúng lấn preview.
### Ngoài phạm vi
- Không đổi logic chụp/export.

## Câu hỏi làm rõ
1. Preview chiếm tỉ lệ bao nhiêu màn là hợp lý (vd ≥ 50% chiều ngang khu trung tâm)?
2. FRAME counter có cần nằm cột riêng to như hiện tại, hay thu nhỏ/đưa lên góc?
3. Có giữ filmstrip xem lại ở vị trí cũ không?

**Trả lời từ PO:**
| # | Câu hỏi | Trả lời | Ngày |
|---|---------|---------|------|

## Acceptance Criteria
- [ ] **AC1**: Preview là phần tử lớn nhất vùng trung tâm CapturePage.
- [ ] **AC2**: Các control wave-3 (đổi camera, tốc độ) vẫn truy cập được, không lấn preview.
- [ ] **AC3**: PO xác nhận trên GUI Mac + NEO One.

## Pipeline
ux-designer redesign layout → PO duyệt → python-dev sửa QML CapturePage → architect.

## Output Contract khi xong
- [ ] Design spec cập nhật + PO duyệt
- [ ] QML sửa, app chạy, PO xác nhận preview to
