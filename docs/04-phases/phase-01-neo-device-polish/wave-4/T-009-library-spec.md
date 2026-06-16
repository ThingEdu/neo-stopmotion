---
id: T-009
title: "Spec tính năng Thư viện phim (mở/duyệt/xem lại phim đã làm)"
assignee: "ba"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-4"
priority: "P1"
scope: "app"
ui: "yes"
design_required: "yes"
design_ref: "docs/03-codebase/design/brand/html-mockups/07-library.html (PO đã duyệt)"
dependencies: []
references:
  - "docs/04-phases/phase-01-neo-device-polish/wave-4/design-ref.md"
  - "src/neo_stopmotion/core/models.py (SessionMeta)"
  - "src/neo_stopmotion/core/frame_manager.py (_save_metadata → project.json)"
  - "src/neo_stopmotion/config/settings.py (StorageCfg.projects_dir)"
---

# T-009: Spec tính năng Thư viện phim

## Mục tiêu
Viết spec đầy đủ cho màn **Thư viện phim**: liệt kê, duyệt, xem lại, xem thông tin, và quản lý (lưu lại / chép link / xoá) các phim đã làm trên máy.

## Phạm vi
### Trong phạm vi
- Quét `projects_dir` (mặc định `~/projects`, env `NEO_STOPMOTION_PROJECTS_DIR`), đọc `project.json` (SessionMeta) của từng phim.
- Hiển thị danh sách + chi tiết: ngày tạo, số tấm, thời lượng, fps/tốc độ, độ phân giải, dung lượng (mp4+gif), link chia sẻ, đường dẫn lưu, thumbnail (frame đầu).
- Hành động trên 1 phim: **Xem** (phát lại mp4), **Lưu lại** (copy ra thư mục/USB — tái dùng `open_save_dialog`), **Chép link** (nếu có download_url), **Xoá phim** (xoá thư mục session, có xác nhận).
- Sắp xếp mặc định: mới nhất trước (theo created_at).
- Điều hướng: vào từ CapturePage (nút "📁 Phim đã làm" / phím `G`) và SuccessPage; thoát bằng `Esc` về CapturePage.
- Thao tác 100% bằng bàn phím (xem mockup 07 + T-011).

### Ngoài phạm vi
- Sửa/đổi tên phim, gắn tag (ghi vào "tương lai").
- Re-render đổi tốc độ (đã có R-4 roadmap).
- Upload lại phim chưa có link.

## Câu hỏi làm rõ (BA điền + xin PO khi cần)
1. Phim "đã làm" = mọi session có `exported=true`/có mp4, hay cả session dở dang (chỉ có frames)? (đề xuất: chỉ phim đã export thành công)
2. Xoá phim: xoá hẳn thư mục khỏi đĩa, có cần thùng rác/undo? (đề xuất: xác nhận 2 bước, xoá hẳn, không undo — giống xoá frame)
3. Tên phim hiển thị khi `title` rỗng: lấy gì? (đề xuất: theo ngày giờ tạo, vd "Phim 16/06 14:20")
4. Nếu chưa có phim nào → empty state hiển thị gì?
5. Phim lỗi (project.json hỏng / thiếu mp4): ẩn hay hiện cảnh báo?

**Trả lời từ PO:**
| # | Câu hỏi | Trả lời | Ngày |
|---|---------|---------|------|

## Acceptance Criteria
- [ ] **AC1**: Spec liệt kê đầy đủ trường metadata hiển thị + nguồn lấy (map sang `SessionMeta` field).
- [ ] **AC2**: Định nghĩa rõ "phim hợp lệ" để liệt kê + xử lý empty state + phim lỗi.
- [ ] **AC3**: Đặc tả hành vi từng hành động (Xem/Lưu/Chép link/Xoá) + xác nhận xoá.
- [ ] **AC4**: Bản đồ phím tắt cho màn Thư viện (khớp mockup 07 + T-011).
- [ ] **AC5**: Test scenarios (TS) cho LibraryService (list/parse/sort/delete) — P0 đánh dấu rõ.
- [ ] Spec đặt tại `docs/01-specs/features/film-library/spec.md`.

## Output Contract khi xong
- [ ] `docs/01-specs/features/film-library/spec.md` + test scenarios.
- [ ] PO duyệt spec trước khi T-012 code (Gate 3).
