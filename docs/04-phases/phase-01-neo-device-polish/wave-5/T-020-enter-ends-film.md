---
id: T-020
title: "Enter phải KẾT THÚC làm phim, không làm tiếp"
assignee: "python-dev"
status: "DONE"
phase: "phase-01-neo-device-polish"
wave: "wave-5"
priority: "P0"
scope: "app"
ui: "yes"
design_required: "no"
design_ref: "N/A"
dependencies: []
references:
  - "src/neo_stopmotion/services/app_controller.py"
  - "src/neo_stopmotion/ui/qml/pages/SuccessPage.qml"
  - "src/neo_stopmotion/ui/qml/components/KeyboardShortcutsOverlay.qml"
---

# T-020: Enter phải KẾT THÚC làm phim, không làm tiếp

PO báo (2026-08-19): *"bấm phím Enter lại làm tiếp như Space. Sửa lại giúp tôi
Enter là kết thúc làm phim."*

## Tái hiện trên NEO One 192.168.1.28 (trước fix)
Trên **màn hình kết quả** (phim đã xong):
```
truoc:      export=2 frames=6
bam ENTER:  export=3 frames=6   <-- ghép LẠI phim cũ, không kết thúc gì cả
bam SPACE:  export=3 frames=7   <-- auto-reset, bắt đầu phim mới
```
Cả hai phím đều "làm tiếp". Ngoài ra bấm Enter 2 lần lúc đang ghép phim sẽ chạy
**2 tiến trình ffmpeg song song** trên cùng bộ frame.

## Root cause
`AppController._do_export()` không có trạng thái nào chặn lặp: mỗi lệnh EXPORT đều
gọi thẳng `start_export()`, bất kể đang ghép dở hay phim đã xong. `_post_export`
chỉ dùng cho SHOOT (làm phim mới), không dùng cho EXPORT.

Thêm nữa, `SuccessPage.qml` gán `N hoặc Enter → reset_session()` — nghĩa là ngay cả
khi chặn được export lặp thì Enter vẫn "làm phim mới", trái với ý nghĩa PO muốn.

## Sửa
1. `AppController`: thêm cờ `_exporting` (bật khi EXPORT, tắt khi `export_completed`
   **hoặc** `export_failed` — export lỗi vẫn phải cho làm lại). `_do_export()` bỏ qua
   lệnh khi `_exporting` hoặc `_post_export`. `reset_session()` xoá cả hai cờ.
   Đặt ở tầng controller nên **nút đỏ ThingBot cứng cũng được bảo vệ**, không chỉ bàn phím.
2. `SuccessPage.qml`: Enter không còn gán "làm phim mới"; nó bị nuốt tại trang (để không
   rơi xuống handler EXPORT toàn cục). Làm phim mới = phím **N** hoặc nút trên màn hình.
3. Chữ hướng dẫn: nhãn nút `N / Enter` → `N`; chân trang bỏ "N/Enter"; bảng phím tắt
   sửa `Enter — Tạo phim` → `Enter — Kết thúc, tạo phim`.

Ý nghĩa phím sau khi sửa: **Enter = kết thúc làm phim (đúng 1 lần). Space = chụp;
ở màn hình kết quả Space = bắt đầu phim mới (giữ nguyên thiết kế cũ).**

## Acceptance Criteria
- [x] AC1 — Enter lần 1 trên màn chụp: ghép phim chạy (`export_started=1`).
- [x] AC2 — Enter lần 2 lúc đang ghép: bị bỏ qua, vẫn `export_started=1`.
- [x] AC3 — Enter trên màn kết quả: bị bỏ qua, không ghép lại.
- [x] AC4 — Space trên màn kết quả: vẫn bắt đầu phim mới (frames +1).
- [x] AC5 — Export lỗi thì vẫn bấm lại được (test `test_failed_export_can_be_retried`).
- [x] AC6 — 136 test PASS (5 test mới `tests/unit/test_export_once.py`, viết đỏ trước).

## Bằng chứng on-device (sau fix)
```
sau khi chup 6 tam:            frames=8 export_started=0 bo_qua=0
ENTER lan 1 (ket thuc):        frames=8 export_started=1 bo_qua=0
ENTER lan 2 (dang ghep):       frames=8 export_started=1 bo_qua=1
ENTER tren man KET QUA:        frames=8 export_started=1 bo_qua=2
SPACE tren man KET QUA:        frames=9 export_started=1 bo_qua=2
```
Đối chứng nhiễu: 1 phím = đúng 1 lệnh (`SHOOT=9`, `frames=9`). Các số bất thường
lúc đầu điều tra là do script test cũ còn chạy nền gửi phím, không phải bug app.

## Còn lại
- [ ] PO test tay trên NEO One.
- [ ] Ship lên main cùng T-019.
