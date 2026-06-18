# Test Guide — Wave 5: Camera enumerate fix + hot-plug + wording

> Dành cho PO tự test sau khi T-016 DONE + T-017 ARCHITECT PASS.
> Không cần biết code. Chỉ cần làm theo các bước.

---

## Chuẩn bị

1. Chắc chắn app đang chạy bản mới nhất: `make run-sim` (chế độ mô phỏng, không cần camera thật)
   hoặc `make run` (cần webcam thật).
2. Nếu test trên NEO One: deploy bản mới trước (Coordinator sẽ hướng dẫn).

---

## Bài test 1 — Máy 1 camera: hiện đúng "Camera 1 / 1" (không còn 6 ô)

**Vấn đề trước đây**: Dù máy chỉ có 1 camera, picker vẫn hiện 6 ô, bấm vào 5 ô còn lại thì báo
"Camera này không hoạt động".

**Bước kiểm tra:**
1. Mở app → vào màn Chụp.
2. Bấm nút "Đổi camera" (hoặc phím C).
3. Popup "Chọn camera" xuất hiện.

**Kết quả mong đợi (SAU fix):**
- Tiêu đề hiện: "Chọn camera" (không phải "Chọn máy ảnh")
- Số camera: "Camera 1 / 1" (không phải "Camera 1 / 6")
- Chỉ có 1 chấm tròn dưới preview (không phải 6 chấm)
- Nút "Camera trước" / "Camera sau" có thể disable (chỉ 1 lựa chọn)
- Nút xác nhận: "DÙNG CAMERA NÀY" (không phải "DÙNG MÁY ẢNH NÀY")

---

## Bài test 2 — Không có camera: hiện trạng thái rõ ràng + nút Quét lại

**Bước kiểm tra (dùng chế độ sim):**
1. Chạy `make run-sim` (chế độ mô phỏng không camera thật).
2. Bấm nút "Đổi camera".
3. Popup mở.

**Kết quả mong đợi:**
- Thấy màn "Không tìm thấy camera nào" (không phải 6 ô lỗi)
- Có nút "Quét lại" — bấm vào, app thử tìm lại camera
- Sau ~2 giây (hot-plug timer), nếu không có camera mới, trạng thái giữ nguyên
- App không bị đơ, không crash

---

## Bài test 3 — Hot-plug: cắm camera khi đang mở popup

> Bài này chỉ làm được nếu có 2 thiết bị camera (hoặc cắm thêm USB webcam).

**Bước kiểm tra:**
1. Mở app, mở popup "Chọn camera" khi chưa có camera (hoặc rút 1 camera ra trước).
2. Thấy màn "Không tìm thấy camera nào".
3. Cắm camera USB vào.
4. Chờ khoảng 2-3 giây.

**Kết quả mong đợi:**
- Popup tự động phát hiện camera mới, hiện preview luôn
- Không cần bấm gì thêm
- Nếu không tự động, bấm "Quét lại" → cũng phải thấy camera

---

## Bài test 4 — Chữ "Camera" đồng nhất toàn bộ

**Bước kiểm tra:**
1. Mở popup "Chọn camera".
2. Đọc TẤT CẢ chữ trong popup.

**Kết quả mong đợi — KHÔNG được thấy những chữ này:**
- "Máy ảnh" (bất kỳ chỗ nào)
- "máy ảnh" (chữ thường)
- "đổi máy" (trong thanh phím tắt)

**Phải thấy:**
- "Chọn camera"
- "Camera N / M"
- "Camera trước" / "Camera sau"
- "DÙNG CAMERA NÀY"
- "đổi camera" (trong thanh phím tắt)

---

## Lưu ý
- Bài test 1 và 4 dễ làm nhất, nên bắt đầu từ đó.
- Bài test 3 cần phần cứng, có thể bỏ qua nếu không có thêm thiết bị.
- Nếu thấy bất kỳ chữ "Máy ảnh"/"máy ảnh" nào còn sót → báo lại Coordinator ngay.
