# Test Guide — Wave 3 (PO test)

> Cho người test KHÔNG cần biết code. 3 tính năng mới: chọn camera, chọn tốc độ phim, lưu video.
> Architect đã PASS gate tự động (90 test PASS, smoke export đúng fps). Phần dưới là thứ **chỉ kiểm được bằng mắt trên app/thiết bị thật**.

## Chuẩn bị
- **Trên Mac:** `make run` (camera thật) — nên cắm/bật vài camera (webcam Mac + iPhone Continuity) để thử đổi.
- **Trên NEO One:** chạy app như thường lệ (1 webcam USB).
- Nếu chỉ muốn xem giao diện không cần camera: `make run-sim`.

---

## T-005 — Chọn camera (nút "Đổi camera" trên màn chụp)

| Bước | Làm | Kết quả mong đợi |
|------|-----|-------------------|
| 1 | Mở app, vào màn chụp (CapturePage). Tìm nút **"Đổi camera"** (nhỏ, kín đáo ở thanh gợi ý — dành cho người vận hành, không nổi như nút chụp) | Thấy nút |
| 2 | Bấm "Đổi camera" | Hiện popup có **khung hình trực tiếp** của camera đang chọn + chữ "Camera 1/6" |
| 3 | Bấm "Camera tiếp" để xoay vòng | Khung hình **đổi sang camera khác**; nếu index đó không có camera → hiện trạng thái lỗi "Camera này không hoạt động" |
| 4 | Chọn đúng camera → bấm **"Chọn camera này"** | Popup đóng; màn chụp tiếp tục chạy **bằng camera vừa chọn** (không đứng hình) |
| 5 | Bấm Esc khi popup mở | Popup đóng, **giữ camera cũ** (huỷ chọn), không treo |
| 6 | Tắt app → mở lại | App nhớ camera đã chọn (lưu config) |

⚠️ **Lưu ý Mac:** nếu iPhone (Continuity Camera) tự thành camera mặc định, dùng "Đổi camera" để chuyển về webcam Mac.

---

## T-006 — Chọn tốc độ phim (trên màn chụp, phía trên nút "Tạo phim")

| Bước | Làm | Kết quả mong đợi |
|------|-----|-------------------|
| 1 | Vào màn chụp, nhìn thanh 3 mức **🐌 Chậm (5fps) / 🐇 Vừa (8fps) / ⚡ Nhanh (12fps)** | Thấy 3 nút; mức "Vừa" chọn sẵn |
| 2 | Chụp ÍT ảnh (~15 tấm trở xuống) | Hệ thống **gợi ý mức "Chậm"** (có dấu/viền gợi ý) nhưng không ép — bạn vẫn đổi được |
| 3 | Chọn "Chậm" → bấm **Tạo phim** | Video thành phẩm chạy **chậm, xem dễ chịu** (không vút qua) |
| 4 | Làm lại, chọn "Nhanh" → Tạo phim | Video chạy nhanh hơn |
| 5 | (quan trọng trên NEO Linux) Nhìn 3 icon 🐌🐇⚡ | **Phải hiện đúng emoji**, không phải ô vuông/tofu. Nếu lỗi → báo lại, có phương án thay bằng hình SVG/chữ |

**Mấu chốt:** tốc độ này đổi **file video thật** (cả bản lên catbox), không chỉ đổi lúc xem.

---

## T-007 — Lưu video về máy (màn thành phẩm)

| Bước | Làm | Kết quả mong đợi |
|------|-----|-------------------|
| 1 | Làm xong 1 phim → tới màn thành phẩm (SuccessPage). Cột phải (vùng người vận hành) có **"Lưu video"** + **"Sao chép link"** | Thấy 2 nút (xanh dương) |
| 2 | Bấm **"Lưu video"** | Mở hộp thoại chọn thư mục |
| 3 | Chọn thư mục (hoặc USB) → xác nhận | Hiện thông báo **"Đã lưu phim tại: <đường dẫn>"**; file MP4 có trong thư mục đó |
| 4 | Mở file vừa lưu | Phát được, đúng video |
| 5 | Bấm **"Sao chép link"** (chỉ hiện khi có link cloud) | Báo đã copy; dán ra chỗ khác thấy link catbox |
| 6 | Trường hợp không có cloud (offline) | Nút "Sao chép link" ẩn; "Lưu video" vẫn dùng được |

---

## Ghi chú chung
- **Cảnh báo style "native" trong console:** chỉ là cảnh báo, app vẫn chạy. Cần xem **màu/nút có render đúng trên màn thật** không; nếu trông sai màu → báo lại để đổi style QML.
- Nếu mục nào hỏng, ghi rõ bước + ảnh chụp màn để team sửa.
