---
id: T-012
title: "Thư viện phim — LibraryService + LibraryPage + thumbnail + điều hướng"
assignee: "python-dev"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-4"
priority: "P1"
scope: "app"
ui: "yes"
design_required: "yes"
design_ref: "docs/03-codebase/design/brand/html-mockups/07-library.html (PO duyệt)"
dependencies: ["T-009", "T-010", "T-011"]
references:
  - "docs/01-specs/features/film-library/spec.md (T-009)"
  - "src/neo_stopmotion/core/models.py (SessionMeta)"
  - "src/neo_stopmotion/services/export_service.py (open_save_dialog, copy_link pattern)"
  - "src/neo_stopmotion/ui/qml/pages/SuccessPage.qml (MediaPlayer/VideoOutput lines 76-89)"
  - "src/neo_stopmotion/app.py (setContextProperty, image providers lines 215-237)"
---

# T-012: Thư viện phim (implement)

## Mục tiêu
Hiện thực màn Thư viện phim theo spec T-009 + mockup 07 (master-detail): trái = lưới phim, phải = trình phát + thông tin + hành động. Thao tác 100% bằng bàn phím.

## Phạm vi
### Trong phạm vi
- **LibraryService** (`src/neo_stopmotion/services/library_service.py`): `list_sessions()` quét `projects_dir`, đọc `project.json` → list SessionMeta (sort mới nhất trước, lọc phim hợp lệ theo spec); `delete_session(id)`; lấy dung lượng file, thumbnail path (frame đầu).
- Expose `libraryService` qua `setContextProperty` (app.py).
- **LibraryPage.qml** (`ui/qml/pages/LibraryPage.qml`) bám mockup 07: lưới film card (thumbnail + tên + ngày + badge), detail pane (player + bảng info đầy đủ + nút Xem/Lưu lại/Chép link/Xoá).
- **Thumbnail**: tạo `SessionImageProvider` (đọc frame đầu của session) hoặc dùng `file://` tới frame_0001.png.
- **Tái dùng player**: tách `VideoPlayer.qml` từ SuccessPage hoặc tái dùng MediaPlayer/VideoOutput.
- **Điều hướng**: MainWindow thêm `libraryPageComponent`; vào từ CapturePage (`G`/nút) + SuccessPage (`G`/nút); `Esc` quay lại CapturePage. Thêm signal điều hướng vào `signal_bus.py` nếu cần.
- Phím tắt màn Thư viện: `◀▶▲▼` chọn · `Enter` xem · `S` lưu lại · `L` chép link · `Del` xoá (xác nhận) · `Esc` về.
- Empty state + phim lỗi theo spec.

### Ngoài phạm vi
- Đổi tên/tag/sắp xếp tuỳ chọn (tương lai).

## Acceptance Criteria
- [ ] **AC1**: `LibraryService.list_sessions()` trả đúng danh sách phim hợp lệ, sort mới nhất trước. **Unit test** với tmp_path nhiều session + project.json.
- [ ] **AC2**: LibraryPage render đúng mockup 07 (lưới trái + detail phải, đủ trường thông tin).
- [ ] **AC3**: Xem phim phát lại mp4 (loop, không tiếng) đúng; chọn phim khác → đổi nguồn.
- [ ] **AC4**: Lưu lại (tái dùng save dialog), Chép link (nếu có url), Xoá phim (xác nhận → `delete_session` → cập nhật danh sách).
- [ ] **AC5**: Vào/ra từ CapturePage + SuccessPage (`G`/`Esc`) chạy đúng.
- [ ] **AC6**: Toàn bộ thao tác bằng bàn phím (không cần chuột).

## Test
| TS | Scenario | P |
|----|----------|---|
| TS-01 | list_sessions: 3 session hợp lệ + 1 lỗi → trả 3, sort đúng | P0 |
| TS-02 | delete_session xoá thư mục + biến mất khỏi list | P0 |
| TS-03 | metadata parse đầy đủ trường hiển thị | P0 |
| TS-04 | empty state khi 0 phim | P1 |
```bash
make test && make lint
# smoke: mở app, bấm G vào thư viện, xem phim, Esc thoát
NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion
```

## Output Contract khi xong
- [ ] library_service.py + test PASS; LibraryPage.qml + provider + nav.
- [ ] Ảnh chụp GUI đối chiếu mockup 07.
- [ ] Sẵn sàng architect review.
