---
id: T-006
title: "Chọn tốc độ / FPS cho video thành phẩm"
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
  - "docs/01-specs/features/video-speed/spec.md"
---

# T-006: Chọn tốc độ / FPS cho video thành phẩm

## Mục tiêu
Cho người dùng chọn tốc độ phim để video ít frame không bị chạy quá nhanh (vấn đề PO gặp trên catbox).

## Bối cảnh (hiện trạng code)
- FPS xuất video cố định = 10 (`config/defaults.toml:22 playback_fps`, `core/video_exporter.py:29`).
- `app.py:155` truyền `fps_playback=settings.export.playback_fps` vào SessionService.
- KHÔNG có UI chọn FPS. SuccessPage `MediaPlayer` không set `playbackRate` (`SuccessPage.qml:75-88`).

## Phân biệt quan trọng
- **(a) Tốc độ file xuất ra** = đổi FPS lúc export → ảnh hưởng cả file lên catbox. **Đây là fix gốc của vấn đề PO.**
- **(b) Tốc độ xem trong app** = `MediaPlayer.playbackRate` → chỉ đổi lúc xem, KHÔNG đổi file đã up.

## Phạm vi
### Trong phạm vi (đợt này — quick win)
- Bộ chọn tốc độ thân thiện trẻ **trước khi export**: "Chậm / Vừa / Nhanh" = ví dụ 5 / 8 / 12 fps (giá trị BA/UX chốt).
- (tùy chọn nhẹ) toggle **0.5× / 1× / 2×** ở preview SuccessPage qua `playbackRate` để xem nhanh.
### Ngoài phạm vi (→ roadmap)
- Re-render đổi tốc độ SAU khi đã export mà không chụp lại (regenerate từ frames đã lưu) — cân nhắc sau.

## Câu hỏi làm rõ (BA điền + hỏi PO)
1. Chọn tốc độ ở bước nào — trước khi bấm "Tạo phim", hay trên màn xem lại với nút "làm lại nhanh/chậm hơn"?
2. Dải fps cho 3 mức Chậm/Vừa/Nhanh là bao nhiêu? Có cần auto gợi ý theo số frame (ít frame → fps thấp) không?
3. Có cần luôn cả toggle tốc độ xem trong app (0.5×/2×) hay chỉ cần fix file xuất ra là đủ?

**Trả lời từ PO:**
| # | Câu hỏi | Trả lời | Ngày |
|---|---------|---------|------|

## Acceptance Criteria (hoàn thiện sau spec+design)
- [ ] **AC1**: Người dùng chọn được tốc độ → file MP4/GIF xuất ra đúng tốc độ đó.
- [ ] **AC2**: Video ít frame (~20 tấm) ở mức "Chậm" xem dễ chịu, không vút qua.
- [ ] **AC3**: (nếu chốt) preview trong app đổi tốc độ xem được mà không export lại.

## Pipeline
BA spec → ux-designer design spec → **PO duyệt design** → python-dev implement + pytest → architect PASS.

## Test
```bash
make test
make lint
NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion
```

## Rủi ro / Ghi chú
- Đổi FPS phải khớp cả MP4 và GIF (GIF 2-pass palette, `video_exporter.py:93-111`).

## Output Contract khi xong
- [ ] Spec + design có, PO duyệt
- [ ] Code trong `src/` + test PASS (gồm smoke export)
- [ ] Sẵn sàng architect review → ship-to-main
