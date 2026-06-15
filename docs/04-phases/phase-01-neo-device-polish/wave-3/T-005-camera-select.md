---
id: T-005
title: "Chọn camera input trong app (picker + preview)"
assignee: "ba"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-3"
priority: "P1"
scope: "app"
ui: "yes"
design_required: "yes"
design_ref: "N/A (chờ ux-designer sau khi có spec)"
dependencies: []
references:
  - "docs/01-specs/features/camera-select/spec.md"
---

# T-005: Chọn camera input trong app

## Mục tiêu
Cho người dùng chủ động chọn camera nào dùng cho app (thay vì app tự chọn index 0 / iPhone Continuity Camera).

## Bối cảnh (hiện trạng code)
- `core/capture_engine.py:39` dùng `cv2.VideoCapture(index)`, mặc định index 0.
- `app.py:81-107` dò index 0–5 nếu fail. Override duy nhất qua env `NEO_STOPMOTION_WEBCAM_INDEX`.
- KHÔNG có UI chọn camera, KHÔNG enumerate device list.
- Trên Mac, **Continuity Camera** (iPhone) thường được macOS ưu tiên làm camera mặc định → app "tự" lấy iPhone.

## Phạm vi
### Trong phạm vi (đợt này — quick win)
- **Option A**: nút "Đổi camera" + preview trực tiếp, xoay vòng index 0→5 để người dùng thấy đúng cam thì chọn. Cross-platform (chạy được cả NEO Linux).
- Lưu lựa chọn vào config để lần sau nhớ.
### Ngoài phạm vi (→ roadmap)
- Hiển thị **tên thiết bị** ("iPhone của Anh", "FaceTime HD") qua Qt `QMediaDevices` — chỉ Mac, map Qt↔OpenCV rủi ro.
- Chuyển hẳn capture sang Qt `QCamera`.

## Câu hỏi làm rõ (BA điền + hỏi PO)
1. Picker đặt ở đâu — màn splash/khởi động hay ngay trên CapturePage (nút nhỏ góc màn)?
2. Trẻ 6-14 có tự đổi camera không, hay đây là thao tác cho người vận hành (Thợ Cả) trước buổi?
3. Có cần nhớ camera đã chọn giữa các phiên không (ghi vào user config)?

**Trả lời từ PO:**
| # | Câu hỏi | Trả lời | Ngày |
|---|---------|---------|------|

## Acceptance Criteria (BA/UX hoàn thiện sau spec+design)
- [ ] **AC1**: Người dùng đổi được camera đang dùng mà không cần sửa env/config tay.
- [ ] **AC2**: Có preview để biết camera đang chọn là cái nào trước khi xác nhận.
- [ ] **AC3**: Lựa chọn được lưu lại (config) — lần mở sau dùng đúng camera.

## Pipeline
BA spec → ux-designer design spec → **PO duyệt design** → python-dev implement + pytest → architect PASS.

## Test (định nghĩa rõ trong spec)
```bash
make test
make lint
```

## Rủi ro / Ghi chú
- OpenCV trên macOS không lấy được tên thiết bị → đợt này dùng preview thay tên.
- Map index OpenCV không ổn định giữa các lần cắm/rút thiết bị.

## Output Contract khi xong
- [ ] Spec + design có, PO duyệt
- [ ] Code trong `src/` + test PASS
- [ ] Sẵn sàng architect review → ship-to-main
