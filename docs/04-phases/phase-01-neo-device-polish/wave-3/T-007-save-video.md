---
id: T-007
title: "Lưu / tải video thành phẩm về máy"
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
  - "docs/01-specs/features/save-video/spec.md"
---

# T-007: Lưu / tải video thành phẩm về máy

## Mục tiêu
Cho người dùng lưu video về máy/USB dễ dàng, thay vì chỉ có link catbox (khó tải trên điện thoại).

## Bối cảnh (hiện trạng code)
- Video thật **đã lưu local**: `session_dir/output.mp4` + `output.gif` (`core/frame_manager.py`, `services/export_service.py:33,37`).
- Upload trả về **direct link** `https://files.catbox.moe/<file>` (`core/cloud_uploader.py:65`) + QR.
- Trên điện thoại Safari, link catbox **phát inline**, muốn lưu phải nhấn giữ → không trực quan cho trẻ.
- SuccessPage chỉ hiện URL text, **không có nút lưu/tải** (`SuccessPage.qml`).

## Phạm vi
### Trong phạm vi (đợt này — quick win)
- Trên SuccessPage thêm hành động **"Lưu video"**: copy link + lưu file vào thư mục/USB người dùng chọn (cho Mac/NEO).
### Ngoài phạm vi (→ roadmap, gộp với #2 phân phối)
- **Trang đích download cho điện thoại** (nút "Tải về" với thuộc tính `download`) — cần chỗ host trang → quyết cùng feature phân phối.
- Đổi host upload sang dịch vụ có sẵn trang download.

## Câu hỏi làm rõ (BA điền + hỏi PO)
1. "Lưu video" lưu ra đâu — hỏi thư mục mỗi lần, hay 1 thư mục cố định / cắm USB tự nhận?
2. Lưu cả MP4 và GIF hay chỉ MP4?
3. Mục tiêu chính là người vận hành lưu tại trạm, hay trẻ/khách tải về điện thoại? (định hình có cần landing page ở roadmap không)

**Trả lời từ PO:**
| # | Câu hỏi | Trả lời | Ngày |
|---|---------|---------|------|

## Acceptance Criteria (hoàn thiện sau spec+design)
- [ ] **AC1**: Từ SuccessPage lưu được video về máy/USB bằng 1 thao tác.
- [ ] **AC2**: Người dùng biết file đã lưu ở đâu (thông báo đường dẫn).

## Pipeline
BA spec → ux-designer design spec → **PO duyệt design** → python-dev implement + pytest → architect PASS.

## Test
```bash
make test
make lint
```

## Rủi ro / Ghi chú
- Trên NEO (Linux ARM) cần xử lý mount USB; có thể đợt này chỉ lưu vào thư mục cố định, USB để roadmap.

## Output Contract khi xong
- [ ] Spec + design có, PO duyệt
- [ ] Code trong `src/` + test PASS
- [ ] Sẵn sàng architect review → ship-to-main
