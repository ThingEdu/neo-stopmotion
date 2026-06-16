# Wave-4 — Design reference (PO đã duyệt 2026-06-16)

PO chốt **Variant B "Cột phải"** cho CapturePage và duyệt toàn bộ hướng redesign + tính năng mới
**Thư viện phim**. Mockup HTML đã duyệt là **nguồn chân lý về layout** — code QML phải bám sát.

## Mockup đã duyệt (bám sát khi code)
| Màn | File mockup |
|-----|-------------|
| Splash | `docs/03-codebase/design/brand/html-mockups/01-splash.html` |
| **Capture (CHỌN: Variant B)** | `docs/03-codebase/design/brand/html-mockups/02-capture-B.html` |
| Chọn camera | `docs/03-codebase/design/brand/html-mockups/03-camera-picker.html` |
| Xác nhận xoá | `docs/03-codebase/design/brand/html-mockups/04-delete-dialog.html` |
| Đang tạo phim | `docs/03-codebase/design/brand/html-mockups/05-exporting.html` |
| Phim đã xong | `docs/03-codebase/design/brand/html-mockups/06-success.html` |
| **Thư viện phim (MỚI)** | `docs/03-codebase/design/brand/html-mockups/07-library.html` |
| Gallery so sánh | `docs/03-codebase/design/brand/html-mockups/_gallery.html` |

## Nguyên tắc bám sát mockup (PO yêu cầu rõ)
- Layout, tỉ lệ, vị trí nút, màu (token `NeoConstants.qml`), emoji, cỡ chữ **phải khớp mockup**.
- Không được "mockup đẹp, thành phẩm khác xa". QA + Architect kiểm đối chiếu mockup ↔ ảnh chụp GUI.
- Dùng đúng design token sẵn có: primary #FF7043, secondary #1565C0, accent #FFD600, background #FFF8E1,
  success #2E7D32, error #C62828. Vùng chạm ≥ `touchMin`.

## Mô hình điều khiển (PO chốt)
- **3 nút cốt lõi** (ánh xạ nút vật lý ThingBot IO1/IO2/IO3): Chụp (`Space`), Xoá (`Del`), Tạo phim (`Enter`).
  - Nút **Xoá**: nếu đang chọn 1 tấm (filmstrip) → xoá tấm đó; không chọn → xoá tấm cuối.
- **Bàn phím có ĐỦ phím tắt cho mọi tính năng** (bàn phím dư phím): xem bản đồ trong T-011.
- Mọi màn có tính năng đều phải thao tác được 100% bằng bàn phím, không cần chuột.
