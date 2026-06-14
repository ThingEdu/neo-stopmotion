# Hướng dẫn test — Wave 1 (NEO One Device Polish)

> Dành cho PO test **trực tiếp trên màn hình thiết bị NEO One** (đăng nhập user `neo`, giao diện XFCE).
> Không cần biết code. Làm theo từng bước, ghi lại PASS/FAIL.

Thiết bị: `thingedges-neo-1` (192.168.1.12). Hai fix đã được cài sẵn lên máy, anh chỉ cần test.

---

## Test 1 — Icon ngoài màn hình để mở app bằng chuột (T-002)

**Vấn đề trước đây:** không có icon nào ngoài desktop để mở app.

**Các bước:**
1. Ngồi trước màn hình NEO One (hoặc xem qua màn hình gắn vào máy), đang ở giao diện desktop XFCE của user `neo`.
2. Nhìn ra **màn hình nền (desktop)** — sẽ thấy một icon tên **"NEO Stopmotion"** (logo Maker Việt).
3. **Bấm đúp** vào icon đó.

**Kết quả mong đợi (PASS):**
- App NEO Stopmotion mở lên (màn hình live preview camera).
- Nếu XFCE hỏi một lần *"Launcher này có đáng tin không / Mark executable / Launch?"* → chọn **"Trust and Launch" / "Execute"**. (Lần đầu XFCE có thể hỏi 1 lần; các lần sau không hỏi nữa.)

**Nếu FAIL:** ghi lại — không thấy icon? bấm không mở? báo lỗi gì? hỏi mật khẩu?

---

## Test 2 — Phim tự động phát sau khi làm xong (T-001)

**Vấn đề trước đây:** trên macOS làm phim xong là tự play; trên NEO thì màn hình kết quả im lặng, không phát.

**Các bước:**
1. Mở app (bằng icon ở Test 1, hoặc menu Whisker → Education → NEO Stopmotion).
2. Chụp vài frame để tạo một đoạn phim ngắn (bấm nút chụp ThingBot, hoặc thao tác chụp như bình thường — tối thiểu 3-5 frame).
3. Thực hiện **xuất phim** (export) như mọi khi (bấm Enter / nút export theo luồng quen thuộc).
4. Đợi màn hình **kết quả (SuccessPage)** hiện ra — bên trái là khung video, bên phải là mã QR.

**Kết quả mong đợi (PASS):**
- Trong vài giây sau khi vào màn kết quả, **đoạn phim vừa làm TỰ ĐỘNG phát** trong khung video bên trái, và **lặp lại liên tục** — không cần bấm gì.

**Nếu FAIL:** khung video đen/đứng im, không phát → ghi lại và báo.

---

## Báo kết quả

| Test | Kết quả (PASS/FAIL) | Ghi chú |
|------|---------------------|---------|
| 1. Icon mở app bằng chuột | | |
| 2. Phim tự play màn kết quả | | |

Gửi lại bảng này cho team. Nếu cả 2 PASS → team sẽ đưa fix gốc vào bộ cài (`install_on_neo.sh`) và lên main.

---

## Ghi chú kỹ thuật (cho team, không bắt buộc đọc)

- **T-001:** thiếu bộ giải mã H.264 cho GStreamer (`gstreamer1.0-libav`) + thiết bị tự chọn decoder phần cứng Allwinner `v4l2slh264dec` bị lỗi. Đã cài codec + ép app dùng decoder phần mềm qua `GST_PLUGIN_FEATURE_RANK` (trong `src/neo_stopmotion/__main__.py`).
- **T-002:** tạo `/home/neo/Desktop/neo-stopmotion.desktop` (executable, owner neo). XFCE 4.18 không nhận `gio metadata::trusted` (cơ chế GNOME) → có thể hỏi xác nhận 1 lần ở lần bấm đầu — đây là hành vi bình thường của XFCE, không phải lỗi.
- Bản trên thiết bị hiện là **patch tay** vào bản pip 1.0.0 để test nhanh. Khi PASS, release chuẩn sẽ bump version + publish PyPI.
