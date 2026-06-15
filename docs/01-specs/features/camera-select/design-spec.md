## Design Spec: Chọn Camera — Nút "Đổi camera" + Picker Popup trên CapturePage
**Date**: 2026-06-15 · **Status**: Draft · **Implements**: T-005 (camera-select)

---

### Context

**Vấn đề**: App mặc định lấy camera index 0. Trên macOS, Continuity Camera của iPhone hay được macOS ưu tiên làm index 0, khiến app quay bằng iPhone thay vì webcam lớp học. Người vận hành (Thợ Cả) phải sửa file config hoặc đặt biến môi trường — thao tác kỹ thuật mà Thợ Cả không thể tự làm.

**Đối tượng thao tác**: Thợ Cả — người vận hành trạm, không phải trẻ em. Trẻ không cần biết và không nên tự đổi camera giữa phiên.

**Giới hạn kỹ thuật**: OpenCV không trả về tên thiết bị. Preview trực tiếp là cách xác nhận duy nhất đúng camera.

**Giải pháp thiết kế**: Nút nhỏ, kín đáo — không nổi bật như nút chụp/tạo phim. Picker dạng popup với preview live, xoay vòng qua index 0–5, Thợ Cả nhận ra camera đúng bằng mắt.

---

### Wireframe

**CapturePage — thêm nút "Đổi camera" (góc phải thanh HintBar)**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [Logo 80px]  TRẠM LÀM PHIM HOẠT HÌNH                 NEO One — ThingEdu   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                 ┌──────────────────────────┐│
│  ┌───────────────────────────────────────────┐  │       FRAME              ││
│  │                                           │  │         42               ││
│  │           LIVE PREVIEW                    │  │  Thời lượng: 4.2s        ││
│  │           (camera trực tiếp)              │  └──────────────────────────┘│
│  │           onion skin bên trên             │                              │
│  │                                           │                              │
│  └───────────────────────────────────────────┘                              │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ FILMSTRIP (cuộn ngang)                                               │   │
│  │ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐               [🗑️]  │   │
│  │ │  1   │ │  2   │ │  3   │ │  4   │ │  5   │    ...               │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  📷 Nút xanh / Space: chụp  ↩️ Z: xoá cuối  🎬 Enter: tạo phim            │
│                                                     [📷 Đổi camera]        │
├─────────────────────────────────────────────────────────────────────────────┤
│  [📷  CHỤP  (Space)]       [↩️  XOÁ FRAME  (Z)]    [🎬  TẠO PHIM  (Enter)]│
└─────────────────────────────────────────────────────────────────────────────┘
```

Vị trí nút "Đổi camera": cuối phải của thanh HintBar (cùng dòng hint text, align phải). Nhỏ, nhạt màu — không cạnh tranh thị giác với 3 nút chính bên dưới.

---

**Picker Popup — Modal overlay căn giữa màn**

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│   📷  Chọn camera                       [✕ Huỷ]     │
│                                                      │
│   ┌────────────────────────────────────────────┐     │
│   │                                            │     │
│   │        PREVIEW TRỰC TIẾP (4:3)             │     │
│   │        (đang hiện từ camera đang xét)      │     │
│   │                                            │     │
│   │        [Spinner khi đang mở camera]        │     │
│   │                                            │     │
│   └────────────────────────────────────────────┘     │
│                                                      │
│          Camera 2 / 6                                │
│   [◀ Camera trước]           [Camera tiếp ▶]         │
│                                                      │
│   ┌──────────────────────────────────────────┐       │
│   │        ✓  CHỌN CAMERA NÀY               │       │
│   └──────────────────────────────────────────┘       │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**Trạng thái lỗi (camera index không mở được)**:
```
┌────────────────────────────────────────────┐
│                                            │
│   ⚠️  Camera này không hoạt động           │
│       Thử camera khác nhé!                │
│                                            │
│        Camera 3 / 6                        │
│  [◀ Camera trước]       [Camera tiếp ▶]    │
│                                            │
│  [✓ CHỌN CAMERA NÀY]  ← disabled          │
└────────────────────────────────────────────┘
```

**Trạng thái không có camera nào**:
```
┌────────────────────────────────────────────┐
│                                            │
│   ⚠️  Không tìm thấy camera nào           │
│       Kiểm tra dây USB rồi thử lại nhé!   │
│                                            │
│              [✕ Đóng]                      │
└────────────────────────────────────────────┘
```

---

### Component Specs

#### A. Nút "Đổi camera" (CameraSelectButton — đặt trong HintBar)

| Thuộc tính | Giá trị |
|---|---|
| Vị trí | Cuối phải của hàng HintBar, align phải trong RowLayout |
| Kích thước | 160 x 40px |
| Background | Transparent; border 1px solid NeoConstants.textSecondary (#616161) |
| Background hover | NeoConstants.surface (#FFFFFF) với border đậm hơn #424242 |
| Text | "Đổi camera" |
| Icon | Camera (Unicode U+1F4F7 hoặc SVG nhỏ) đặt trước text |
| Typography | fontCaption (18px), weight regular (không bold), màu NeoConstants.textSecondary (#616161) |
| Corner radius | 8px |
| Vùng chạm | Min 40px chiều cao (touchMin 52px — cần thêm padding ẩn trên/dưới 6px mỗi bên nếu layout cho phép) |
| Ý đồ thiết kế | Kín đáo, không nổi bật. Người mới nhìn không chú ý ngay; Thợ Cả biết nơi cần tìm. |

**Lý do không dùng icon-only**: Thợ Cả người lớn cần đọc label, không quen biểu tượng camera thuần túy trong context điều khiển thiết bị.

#### B. CameraPickerPopup (Modal popup)

| Thuộc tính | Giá trị |
|---|---|
| Loại | Modal Popup với Overlay dim |
| Kích thước | 520 x 480px, căn giữa màn (anchors.centerIn: Overlay.overlay) |
| Background | NeoConstants.surface (#FFFFFF), border-radius 16px |
| Border | 2px solid NeoConstants.primary (#FF7043) |
| Overlay dim | #80000000 (50% black) |
| Padding trong | 24px tất cả cạnh |
| Spacing giữa sections | NeoConstants.spacingM (16px) |

**Header:**
| Thuộc tính | Giá trị |
|---|---|
| Title text | "Chọn camera" |
| Typography title | fontBody (24px), bold, NeoConstants.textPrimary (#212121) |
| Nút đóng [✕ Huỷ] | 80 x 36px, background #E0E0E0, text #212121, radius 8px — góc trên phải header |
| Hành vi nút Huỷ | Đóng popup, giữ camera đang dùng trước đó |

**Preview window:**
| Thuộc tính | Giá trị |
|---|---|
| Kích thước | 400 x 300px (tỉ lệ 4:3), căn giữa ngang trong popup |
| Background | #000000 (black) khi chưa có frame |
| Corner radius | 8px |
| Border | 1px solid #E0E0E0 |
| Nội dung trạng thái Loading | BusyIndicator (spinner) + text "Đang mở camera..." 18px, màu #FFFFFF, căn giữa trên nền đen |
| Nội dung trạng thái Error | Icon cảnh báo (⚠️ hoặc SVG) + text 2 dòng, màu NeoConstants.warning (#FF8F00), căn giữa |
| Nội dung trạng thái NoCamera | Icon ⚠️ + text đỏ, nút đóng |
| Nội dung trạng thái Active | Frame live từ camera (refresh theo FPS nhẹ — khoảng 10fps trong picker) |

**Indicator vị trí:**
| Thuộc tính | Giá trị |
|---|---|
| Text | "Camera [N] / 6" |
| Typography | fontBody (24px), bold, NeoConstants.textPrimary, căn giữa ngang |
| Vị trí | Bên dưới preview window, trên nút điều hướng |

**Nút điều hướng (2 nút ngang):**
| Thuộc tính | Giá trị |
|---|---|
| Nút "◀ Camera trước" | 200 x 52px |
| Nút "Camera tiếp ▶" | 200 x 52px |
| Layout | RowLayout, spacing 16px, căn giữa ngang |
| Background | #E0E0E0 (mặc định), hover #CCCCCC |
| Text color | NeoConstants.textPrimary (#212121) |
| Typography | fontCaption (18px), bold |
| Corner radius | 10px |

**Nút xác nhận "CHỌN CAMERA NÀY":**
| Thuộc tính | Giá trị |
|---|---|
| Kích thước | fillWidth (bên trong popup padding) x 56px |
| Background enabled | NeoConstants.primary (#FF7043), hover #E64A19 |
| Background disabled | #9E9E9E, opacity 0.6 |
| Text enabled | "✓  CHỌN CAMERA NÀY" |
| Text color | #FFFFFF |
| Typography | fontButton (24px), bold |
| Corner radius | 12px |
| Disabled khi | Camera index hiện tại không mở được (isOpened = false) |

---

### States

| State | Preview Area | Chỉ số "Camera N/6" | Nút "Trước/Tiếp" | Nút "Chọn" | Nút "Đổi camera" (CapturePage) |
|---|---|---|---|---|---|
| **Idle** (popup chưa mở) | — | — | — | — | Hiện, enabled |
| **Picker mở — Loading** | Spinner + "Đang mở camera..." | "Camera N / 6" | Enabled (có thể tiếp nhưng đợi load) | Disabled | Ẩn (popup che) |
| **Picker mở — Active** | Frame live từ camera | "Camera N / 6" | Enabled | Enabled |  — |
| **Picker mở — Error** | ⚠️ + "Camera này không hoạt động / Thử camera khác nhé!" | "Camera N / 6" | Enabled | Disabled | — |
| **Picker mở — NoCamera** | ⚠️ + "Không tìm thấy camera nào / Kiểm tra dây USB rồi thử lại nhé!" | Ẩn | Ẩn | Ẩn; chỉ có nút "Đóng" | — |
| **Đã chọn** (popup đóng) | LivePreview CapturePage cập nhật ngay | — | — | — | Hiện, enabled (cho lần đổi kế tiếp) |

---

### Interaction

**Mở picker:**
- Thợ Cả bấm "Đổi camera" → Popup xuất hiện với animation scale-in nhẹ (duration 200ms).
- Picker tải camera index hiện tại (webcam_index) đang dùng → hiện preview + "Camera [N] / 6".
- Live preview trong picker chạy ở ~10fps (không cần 30fps — chỉ để nhận biết).

**Điều hướng index:**
- "Camera tiếp ▶": index tăng (0→1→2→3→4→5→0, xoay vòng).
- "◀ Camera trước": index giảm (0→5→4..., xoay vòng).
- Mỗi lần chuyển: overlay loading ngắn (~500ms), spinner xuất hiện, thử mở camera mới.
- Nếu mở được: preview hiện live.
- Nếu không mở được: trạng thái Error, nút "Chọn" disabled.

**Xác nhận chọn:**
- Bấm "CHỌN CAMERA NÀY" → popup đóng (animation 150ms fade out).
- CaptureEngine re-init với webcam_index mới.
- LivePreview trên CapturePage cập nhật ngay khi `webcam_ready` signal emit.
- Config ghi: `~/.config/neostopmotion/config.toml → [capture] webcam_index = N`.

**Huỷ:**
- Bấm "Huỷ" hoặc Escape hoặc bấm vùng nền mờ → popup đóng, camera cũ giữ nguyên.

**Phím cứng ThingBot:** Không có tương tác phím cứng trong picker — ThingBot chỉ có SHOOT/UNDO/EXPORT. Thợ Cả dùng chuột/bàn phím để thao tác picker.

**Animation:**
- Popup mở: scale từ 0.9→1.0 + opacity 0→1, duration 200ms (animFast).
- Popup đóng: opacity 1→0, duration 150ms.
- Chuyển camera: preview fade out 100ms → spinner → preview fade in 100ms khi ready.

---

### Accessibility

- **Vùng chạm**: Nút "Trước/Tiếp" 200x52px (≥ touchMin 52px). Nút "Chọn" 56px cao (≥ touchMin). Nút "Đổi camera" cần padding ẩn để đạt 52px vùng chạm dù hiển thị 40px.
- **Tương phản**:
  - Text "Đổi camera" (#616161 trên nền transparent/#FFF8E1) = 4.5:1 (đúng ngưỡng AA).
  - Nút "CHỌN CAMERA NÀY" #FFFFFF trên #FF7043 = 3.1:1 — đạt AA cho large text (24px bold). Lưu ý: nếu cần WCAG AA strict cho mọi text, cân nhắc dùng màu text #212121 trên #FF7043 = 4.8:1.
  - Text trạng thái Error: #FF8F00 (warning) trên #000000 = 11:1 (PASS).
- **Không chỉ dựa vào màu**: Nút disabled có cả opacity giảm + text khác (thêm indicator "không hoạt động"). Trạng thái Error có cả icon + text, không chỉ màu đỏ.
- **Cỡ chữ**: Indicator "Camera N / 6" dùng fontBody 24px — đủ lớn cho Thợ Cả đọc dễ trên màn NEO One khoảng cách 60-80cm.
- **Keyboard**: Escape = Huỷ. Tab điều hướng qua 4 nút. Enter kích hoạt nút đang focus.

---

### Design Learnings

1. **Kín đáo có chủ đích**: Nút "Đổi camera" đặt trong HintBar (không phải hàng Action Buttons dưới) là quyết định có ý nghĩa UX — hàng dưới là 3 hành động học sinh dùng nhiều nhất, gắn với ThingBot. "Đổi camera" là thao tác vận hành một lần trước buổi, không nên cùng "cân" với 3 nút đó.

2. **Preview là tên thiết bị**: Vì OpenCV không cho tên camera, live preview 4:3 đảm nhiệm vai trò nhận diện. Kích thước 400x300px đủ để Thợ Cả nhìn rõ góc/ánh sáng/đối tượng để phân biệt camera nào.

3. **Xoay vòng index ưu tiên "Camera tiếp"**: Người dùng hay bấm tiếp tục hơn là quay lại. Đặt "Camera tiếp ▶" bên phải (thuận tự nhiên từ trái sang phải).

4. **State NoCamera khác Error**: Error = index cụ thể fail (camera tồn tại nhưng đang bận/lỗi). NoCamera = tất cả 0–5 đều fail. NoCamera cần UX khác vì không còn gì để điều hướng.

5. **Config write silent fail**: Nếu ghi config thất bại (quyền hạn), camera vẫn đổi trong phiên; chỉ cần log warning. Không cần thông báo cho Thợ Cả trừ khi họ cần biết (thêm toast nhẹ: "Không lưu được tùy chọn" — đây là điểm cần PO duyệt, xem bên dưới).

---

### Điểm cần PO duyệt

**P1 — Màu nút "Đổi camera"**: Thiết kế đề xuất màu textSecondary (#616161) để kín đáo. Nếu PO thấy quá khó thấy (nhất là trên NEO One màn hình nhỏ hơn) → có thể nâng lên màu secondary (#1565C0, xanh dương) với border xanh. Đề xuất: giữ #616161 thử trước.

**P2 — Toast khi config write lỗi**: Khi ghi `config.toml` thất bại (quyền hạn), có hiện toast "Không lưu được tùy chọn — camera vẫn đổi trong phiên này" không? Đề xuất: có toast nhẹ, duration 3s.

**P3 — Tốc độ refresh preview trong picker**: Hiện đề xuất 10fps để nhẹ CPU. Nếu NEO One mạnh đủ, có thể tăng 15fps cho preview mượt hơn. Đề xuất: 10fps đủ cho mục đích nhận diện camera.
