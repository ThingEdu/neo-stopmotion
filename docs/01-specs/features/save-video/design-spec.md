## Design Spec: Lưu Video + Sao Chép Link — 2 Nút Hành Động trên SuccessPage
**Date**: 2026-06-15 · **Status**: Draft · **Implements**: T-007 (save-video)

---

### Context

**Vấn đề**: SuccessPage hiện chỉ hiện URL text nhỏ và QR code. Thợ Cả muốn lưu file MP4 về thư mục cụ thể (không cần mở terminal tìm `session_dir`), hoặc copy link để gửi Zalo nhóm phụ huynh. Cả 2 thao tác hiện không có nút rõ ràng.

**Đối tượng**: Thợ Cả (người vận hành trạm) — không phải trẻ. Copy và cỡ nút theo phong cách người lớn; không lấn át phần xem phim của trẻ (video preview + QR + celebration message vẫn là nhân vật chính).

**Quyết định PO đã chốt (2026-06-15)**:
- "Lưu video": mở file dialog chọn thư mục mỗi lần; lưu MP4; báo đường dẫn đã lưu bằng toast.
- "Sao chép link": copy shareUrl vào clipboard; hiện chỉ khi `shareUrl != ""`.
- Chỉ lưu MP4 (không GIF đợt này).
- UX theo phong cách người lớn vận hành; không lấn át vùng trẻ.

---

### Wireframe

**SuccessPage — toàn màn (sau khi thêm 2 nút)**

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  [Logo 64px]  Maker Việt × ThingEdu            NEO One — Trạm Làm Phim       │
├──────────────────────────────────────────────────────────────────────────────┤
│                  🎉 Phim của bạn đã xong!                                     │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────┐   ┌──────────────────────────────────┐ │
│  │                                  │   │                                  │ │
│  │        VIDEO PREVIEW             │   │   📱 Mời bạn quét mã             │ │
│  │        (đang phát loop)          │   │                                  │ │
│  │        [MediaPlayer]             │   │   ┌────────────────────────────┐ │ │
│  │                                  │   │   │                            │ │ │
│  │                                  │   │   │   [QR CODE 360x360]        │ │ │
│  │                                  │   │   │                            │ │ │
│  │                                  │   │   └────────────────────────────┘ │ │
│  │                                  │   │                                  │ │
│  │                                  │   │   https://files.catbox.moe/...   │ │
│  │                                  │   │   Phim lưu tại: /path/output.mp4 │ │
│  │                                  │   │                                  │ │
│  │                                  │   │   ┌──────────────────────────┐   │ │
│  │                                  │   │   │ ↓  Lưu video             │   │ │
│  │                                  │   │   └──────────────────────────┘   │ │
│  │                                  │   │   ┌──────────────────────────┐   │ │
│  │                                  │   │   │ 🔗  Sao chép link        │   │ │
│  │                                  │   │   └──────────────────────────┘   │ │
│  └──────────────────────────────────┘   └──────────────────────────────────┘ │
│                                                                              │
│          💡 Mời bạn bấm nút để làm lại phim                                 │
│                          [🔁  Làm phim mới]                                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Vị trí 2 nút**: Cột phải (ColumnLayout width 420px), dưới URL text và path text, ngay trên footer. Không chen vào vùng video preview (cột trái).

---

**Chi tiết nút "Lưu video" — các trạng thái:**

```
[Idle / Normal]
┌──────────────────────────────────────────────┐
│  ↓  Lưu video                                │
└──────────────────────────────────────────────┘
 background: secondary (#1565C0), text: #FFFFFF

[Loading — đang sao chép]
┌──────────────────────────────────────────────┐
│  ◌  Đang lưu...                              │
└──────────────────────────────────────────────┘
 background: secondary, opacity 0.7; BusyIndicator nhỏ bên trái

[Disabled — mp4Path rỗng]
┌──────────────────────────────────────────────┐
│  ↓  Lưu video                                │
└──────────────────────────────────────────────┘
 background: #9E9E9E, opacity 0.5; cursor default

[Success — vừa lưu xong (1.5 giây)]
┌──────────────────────────────────────────────┐
│  ✓  Đã lưu!                                  │
└──────────────────────────────────────────────┘
 background: success (#2E7D32), text: #FFFFFF; rồi về Normal
```

---

**Toast thông báo lưu thành công:**

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                          [Phần chính màn]                                    │
│                                                                              │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                   ┌───────────────────────────────────────┐
                                   │  ✓  Đã lưu phim tại:                  │
                                   │  /home/user/Desktop/output.mp4         │
                                   └───────────────────────────────────────┘
                                      ↑ Góc dưới phải, margin 24px
```

**Toast lỗi:**
```
                                   ┌───────────────────────────────────────┐
                                   │  ⚠️  Không thể lưu: thư mục không    │
                                   │  truy cập được. Thử lại nhé!          │
                                   └───────────────────────────────────────┘
```

---

### Component Specs

#### A. SaveVideoButton (Nút "Lưu video")

| Thuộc tính | Giá trị |
|---|---|
| Vị trí | Cột phải SuccessPage, dưới URL text + path text |
| Kích thước | Layout.fillWidth (trong cột phải 420px, trừ padding 16px hai bên = ~388px hiệu dụng) x 52px |
| Background — Normal | NeoConstants.secondary (#1565C0) |
| Background — Hover | #0D47A1 (secondary đậm) |
| Background — Loading | NeoConstants.secondary, opacity 0.7 |
| Background — Success (1.5s) | NeoConstants.success (#2E7D32) |
| Background — Disabled | #9E9E9E, opacity 0.5 |
| Text — Normal | "↓  Lưu video" |
| Text — Loading | "Đang lưu..." (với BusyIndicator 16px bên trái) |
| Text — Success | "✓  Đã lưu!" |
| Text color | #FFFFFF tất cả trạng thái |
| Typography | fontCaption (18px), bold |
| Icon | Mũi tên xuống (↓) hoặc SVG download icon, đặt trước text |
| Corner radius | 10px |
| Spacing icon-text | spacingS (8px) |
| ToolTip khi disabled | "Chưa có phim để lưu" (hiện khi hover) |

**Lý do dùng secondary (#1565C0 — xanh dương)** thay primary (#FF7043 — cam): Cam đã dùng cho các action chính gắn với trẻ (nút chụp, border thumbnail chọn). "Lưu video" là action của Thợ Cả — dùng màu phụ phân biệt vai trò rõ ràng, không cạnh tranh với "Làm phim mới" (highlighted/primary).

#### B. CopyLinkButton (Nút "Sao chép link")

| Thuộc tính | Giá trị |
|---|---|
| Vị trí | Ngay dưới SaveVideoButton, cùng cột |
| Kích thước | Layout.fillWidth x 52px |
| Visible | Chỉ khi `shareUrl !== ""` (ẩn hoàn toàn khi không có link) |
| Background — Normal | Transparent; border 1px solid NeoConstants.secondary (#1565C0) |
| Background — Hover | #E3F2FD (xanh nhạt) |
| Background — Copied (1.5s) | #E3F2FD; border đậm hơn |
| Text — Normal | "🔗  Sao chép link" |
| Text — Copied (1.5s) | "✓  Đã sao chép!" |
| Text color — Normal | NeoConstants.secondary (#1565C0) |
| Text color — Copied | NeoConstants.success (#2E7D32) |
| Typography | fontCaption (18px), bold |
| Corner radius | 10px |

**Lý do outline (không filled)**: Nút phụ, hành động thấp hơn "Lưu video" về độ quan trọng. Outline tự nhiên nhường ưu tiên thị giác cho nút filled bên trên.

#### C. Toast thông báo (SaveToast / CopyToast)

| Thuộc tính | Giá trị |
|---|---|
| Vị trí | Góc dưới phải màn hình, margin 24px cạnh và đáy |
| Chiều rộng tối đa | 480px (đủ hiện đường dẫn dài) |
| Chiều cao | Auto (padding 12px top/bottom, 16px left/right) |
| Background — Success | NeoConstants.textPrimary (#212121), opacity 0.9 |
| Background — Error | NeoConstants.error (#C62828), opacity 0.9 |
| Icon | ✓ (success) hoặc ⚠️ (error) đặt đầu dòng |
| Text — Success lưu | "✓  Đã lưu phim tại: [đường dẫn đầy đủ]" |
| Text — Success copy | "✓  Đã sao chép link!" |
| Text — Error | "⚠️  [Thông báo lỗi]. Thử lại nhé!" |
| Text color | #FFFFFF |
| Typography | fontCaption (18px) |
| Corner radius | 8px |
| Duration | 4000ms (dài hơn vì có đường dẫn cần đọc) rồi fade out 300ms |
| Text wrap | Text.WrapAnywhere — đường dẫn có thể dài trên Linux |
| Animation xuất hiện | slide up từ dưới + fade in, 200ms |

**Lý do duration 4 giây** (thay vì 1.5-2s thông thường): Thợ Cả cần đọc và ghi nhớ đường dẫn đầy đủ, hoặc so sánh với file dialog vừa mở. Toast ẩn quá nhanh họ không kịp đọc.

#### D. Trạng thái lỗi trong SuccessPage (inline error — thay toast nếu nghiêm trọng)

Khi copy file thất bại (thư mục không truy cập, không đủ quyền, đĩa đầy):
- Toast error xuất hiện 6 giây (dài hơn để Thợ Cả xử lý).
- Nút "Lưu video" trở về Normal sau khi toast ẩn — người dùng có thể thử lại với thư mục khác.
- Không mất dữ liệu gốc (file vẫn ở `session_dir/output.mp4`).

| Loại lỗi | Nội dung toast |
|---|---|
| Thư mục không tồn tại | "⚠️  Thư mục không tìm thấy (có thể USB đã rút). Thử lại nhé!" |
| Không đủ quyền ghi | "⚠️  Không đủ quyền lưu tại thư mục đó. Chọn thư mục khác nhé!" |
| Đĩa đầy | "⚠️  Không đủ dung lượng. Xoá bớt file rồi thử lại nhé!" |
| Lỗi khác | "⚠️  Lưu không thành công. Thử lại nhé!" |

---

### States

| State | "Lưu video" | "Sao chép link" | Toast |
|---|---|---|---|
| **Idle** (`mp4Path != ""`, `shareUrl != ""`) | Normal (xanh dương) | Hiện, outline xanh | Ẩn |
| **Idle** (`mp4Path != ""`, `shareUrl == ""`) | Normal (xanh dương) | Ẩn hoàn toàn | Ẩn |
| **Idle** (`mp4Path == ""`) | Disabled (#9E9E9E) | Ẩn (nếu cũng không có shareUrl) | Ẩn |
| **File dialog mở** | Loading "Đang lưu..." | Disabled (chờ) | Ẩn |
| **Đang sao chép file** | Loading "Đang lưu..." | Disabled | Ẩn |
| **Lưu thành công** | Success "✓ Đã lưu!" 1.5s → Normal | Trở lại normal | Toast success 4s |
| **Lưu thất bại** | Normal (cho thử lại) | Trở lại normal | Toast error 6s |
| **Sao chép link** (trong khi `mp4Path` OK) | Normal (không bị ảnh hưởng) | "✓ Đã sao chép!" 1.5s → outline | Toast copy 2s |
| **Dialog bị huỷ** (user đóng file dialog không chọn) | Normal (không có gì xảy ra) | Không đổi | Ẩn |

---

### Interaction

**Luồng Lưu video:**
1. Thợ Cả bấm "↓ Lưu video".
2. Nút chuyển sang Loading "Đang lưu...".
3. Native file dialog mở (`QFileDialog.getExistingDirectory()`).
4. Nếu Thợ Cả chọn thư mục → đóng dialog → background thread sao chép file.
   - Video preview vẫn tiếp tục phát (không block).
4b. Nếu Thợ Cả đóng dialog không chọn (Cancel) → nút về Normal, không có gì xảy ra.
5. Sao chép xong → nút flash "✓ Đã lưu!" 1.5 giây → về Normal.
6. Toast hiện: "✓ Đã lưu phim tại: [đường dẫn đầy đủ]" duration 4 giây.
7. Thợ Cả có thể bấm lại "Lưu video" để lưu lên thư mục khác (ví dụ USB và Desktop cùng lúc).

**Luồng Sao chép link:**
1. Thợ Cả bấm "🔗 Sao chép link".
2. `QGuiApplication.clipboard().setText(shareUrl)` — tức thì.
3. Nút text đổi "✓ Đã sao chép!" 1.5 giây → về outline.
4. Toast nhẹ: "✓ Đã sao chép link!" duration 2 giây.

**Phím cứng ThingBot:**
- Không thêm hành vi phím cứng cho 2 nút này — đây là thao tác của Thợ Cả bằng chuột/bàn phím máy tính.
- "Làm phim mới" vẫn là action chính sau phiên chụp.

**Animation:**
- Nút "Lưu video" khi bấm: opacity pulse nhẹ 0.7→1.0 50ms.
- Nút thành công: flash màu xanh lá 1.5s rồi transition màu về xanh dương 300ms.
- Toast slide-up + fade-in 200ms; fade-out 300ms khi ẩn.

---

### Tích hợp với layout SuccessPage hiện tại

SuccessPage hiện có cột phải (`Layout.preferredWidth: 420`) chứa: tiêu đề QR, ảnh QR (360x360), URL text, path text nhỏ. Thêm 2 nút vào dưới path text:

```
Cột phải (420px):
 - Text "📱 Mời bạn quét mã" [24px bold]
 - Rectangle QR 360x360 (chỉ hiện nếu qrPath != "")
 - Text shareUrl [18px, wrap, chỉ hiện nếu shareUrl != ""]
 - Text "Phim lưu tại: ..." [12px, hiện luôn nếu mp4Path != ""]
 - [THÊM MỚI] spacingM (16px)
 - [THÊM MỚI] SaveVideoButton 52px
 - [THÊM MỚI] spacingS (8px)
 - [THÊM MỚI] CopyLinkButton 52px (visible nếu shareUrl != "")
```

Tổng chiều cao cột phải tăng ~128px (2 nút + spacing). QR 360x360 có thể cần thu nhỏ xuống 300x300 nếu tổng vượt chiều cao màn. Ưu tiên:
1. Giữ 2 nút mới đủ to (52px mỗi nút).
2. Giữ QR đủ scan (≥280px là ổn với điện thoại).
3. Cắt QR nếu cần, không cắt nút.

---

### Accessibility

- **Vùng chạm**: Cả 2 nút 52px cao × fillWidth — luôn ≥ touchMin (52px). Trên NEO One nếu có touch screen: 388px rộng x 52px cao — đủ dễ chạm.
- **Tương phản**:
  - "Lưu video" — #FFFFFF trên secondary #1565C0 = 7.5:1 (PASS AAA).
  - "Sao chép link" normal — secondary #1565C0 trên #FFFFFF = 7.5:1 (PASS AAA).
  - Toast success — #FFFFFF trên #212121 = 16:1 (PASS AAA).
  - Toast error — #FFFFFF trên error #C62828 = 5.9:1 (PASS AA).
- **Không chỉ dựa vào màu**:
  - Nút "Lưu video" disabled: opacity giảm + ToolTip text giải thích.
  - Trạng thái thành công: text đổi ("✓ Đã lưu!") + màu đổi — 2 tín hiệu.
  - Toast: icon (✓ / ⚠️) + text — không chỉ màu.
- **Text đường dẫn**: fontCaption 18px, WrapAnywhere — đường dẫn dài vẫn đọc được.
- **Keyboard**: Tab tới "Lưu video" → Enter mở dialog. Tab tới "Sao chép link" → Enter copy. Escape trong file dialog huỷ.
- **Screen reader**: `Accessible.name` cho mỗi nút: "Lưu file video về máy tính" / "Sao chép link chia sẻ vào clipboard".

---

### Design Learnings

1. **Phân vùng theo đối tượng**: SuccessPage phục vụ 2 đối tượng — trẻ xem phim (cột trái: video, celebration) và Thợ Cả lưu/chia sẻ (cột phải: QR, link, nút lưu). Không trộn lẫn. 2 nút mới đặt cột phải, dưới cùng, không lấn ảnh trẻ.

2. **secondary (#1565C0) là màu của Thợ Cả**: primary (#FF7043) gắn với action trẻ em (chụp, chọn frame, tạo phim). Chọn secondary cho action của Thợ Cả tạo ra ngôn ngữ màu sắc nhất quán: cam = hành động học tập, xanh = hành động vận hành.

3. **Toast 4 giây cho đường dẫn**: Khác với toast thông thường 1.5-2 giây, thông báo đường dẫn file cần thời gian đọc. Đây là quy ước riêng cho toast có nội dung dài (> 40 ký tự) — ghi nhận cho các component tương tự sau này.

4. **File dialog không cần customization**: Dùng native dialog (`QFileDialog.getExistingDirectory()`) là đúng — nó quen thuộc với Thợ Cả hơn dialog custom, và hoạt động tốt trên cả macOS + Linux ARM64.

5. **"Lưu lại nhiều lần" là valid use case**: Thợ Cả có thể muốn lưu vào cả USB lẫn Desktop. Nút về Normal sau khi lưu thành công — không disable sau lần lưu đầu.

---

### Điểm cần PO duyệt

**P1 — Màu nút "Lưu video" (secondary xanh dương vs primary cam)**: Đề xuất xanh dương (#1565C0) để phân biệt với action của trẻ. Nếu PO thấy xanh lạ lẫm với tổng thể cam của app → có thể dùng primary (#FF7043) nhưng khi đó "Lưu video" và "Làm phim mới" sẽ có cùng màu — cần differentiate bằng cách khác (outlined vs filled). Đề xuất: giữ xanh dương.

**P2 — QR có thu nhỏ nếu thiếu chỗ không**: Khi thêm 2 nút, tổng chiều cao cột phải tăng ~128px. Trên màn thấp (<800px), QR 360px sẽ bị ép. Đề xuất: thu QR xuống max(min(availableHeight - 200, 360), 280) — tức là QR linh hoạt 280-360px. Nếu PO muốn QR cố định 360px → sẽ cần scroll trong cột phải (phức tạp hơn). Đề xuất: QR linh hoạt.

**P3 — Toast đường dẫn có nên clickable không**: Nếu click vào toast → mở file manager tại thư mục đó. Tính năng tiện lợi nhưng phức tạp triển khai (cần `QDesktopServices.openUrl`). Đề xuất: không clickable đợt này — Thợ Cả biết thư mục từ dialog vừa chọn.
