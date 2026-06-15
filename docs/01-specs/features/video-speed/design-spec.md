## Design Spec: Chọn Tốc Độ Phim — Bộ Chọn 3 Mức trên CapturePage
**Date**: 2026-06-15 · **Status**: Draft · **Implements**: T-006 (video-speed)

---

### Context

**Vấn đề**: FPS xuất cố định = 10. Phim ít frame (~20 tấm) dài chỉ 2 giây — "vút qua" khi xem trên catbox, khó cảm nhận câu chuyện. Trẻ mất công chụp nhiều tấm nhưng phim xem không kịp.

**Đối tượng**: Trẻ 6-14 + Thợ Cả đều có thể dùng bộ chọn này. Ngôn ngữ thân thiện trẻ, biểu tượng trực quan (con sên / con thỏ), không cần hiểu "fps".

**Quyết định PO đã chốt (2026-06-15)**:
- 3 mức: Chậm (5fps) / Vừa (8fps) / Nhanh (12fps).
- Đặt trên CapturePage, phía trên nút "Tạo phim".
- Gợi ý tự động theo số frame (ít frame → highlight Chậm) nhưng không ép.
- Không có toggle tốc độ xem ở SuccessPage đợt này.

**Vị trí trong layout CapturePage**: Bộ chọn tốc độ chen vào giữa FilmStrip và hàng Action Buttons. Chiều cao cần nhỏ gọn để không đẩy các thành phần khác ra ngoài màn.

---

### Wireframe

**CapturePage — sau khi thêm SpeedSelector (giữa FilmStrip và Action Buttons)**

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
│  └───────────────────────────────────────────┘                              │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ FILMSTRIP (cuộn ngang) ...                                [🗑️ XOÁ]  │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  📷 Space: chụp  ↩️ Z: xoá cuối  🎬 Enter: tạo phim     [📷 Đổi camera]  │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Tốc độ phim:                                                        │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐      │   │
│  │  │  🐌              │  │  🐇              │  │  ⚡              │      │   │
│  │  │  Chậm           │  │  Vừa            │  │  Nhanh          │      │   │
│  │  │  5fps           │  │  8fps           │  │  12fps          │      │   │
│  │  │  [GỢI Ý nếu     │  │  ← MẶC ĐỊNH    │  │                 │      │   │
│  │  │   ≤15 frame]    │  │                 │  │                 │      │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘      │   │
│  │  💡 Phim ít tấm nên chọn Chậm để xem rõ nha!  (ẩn khi không gợi ý) │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  [📷  CHỤP  (Space)]       [↩️  XOÁ FRAME  (Z)]    [🎬  TẠO PHIM  (Enter)]│
└─────────────────────────────────────────────────────────────────────────────┘
```

**Chi tiết 1 nút tốc độ — trạng thái Active (Chậm được chọn):**
```
┌───────────────────────┐
│  🐌                    │  ← Icon 32px, căn giữa
│  Chậm                 │  ← fontBody 24px bold, primary
│  5 fps                │  ← fontCaption 18px, textSecondary
│  ▼ GỢI Ý             │  ← badge nhỏ màu accent, chỉ khi gợi ý
└───────────────────────┘
 border 3px primary, radius 12px
 background: #FFF3E0 (cam nhạt)
```

**Chi tiết 1 nút tốc độ — trạng thái Default (chưa chọn, không gợi ý):**
```
┌───────────────────────┐
│  🐇                    │  ← Icon 32px, căn giữa
│  Vừa                  │  ← fontBody 24px, textPrimary
│  8 fps                │  ← fontCaption 18px, textSecondary
└───────────────────────┘
 border 1px #E0E0E0, radius 12px
 background: #FFFFFF
```

**Chi tiết 1 nút tốc độ — trạng thái Gợi ý (chưa chọn nhưng được highlight gợi ý):**
```
┌───────────────────────┐
│  🐌                    │
│  Chậm                 │  ← fontBody 24px, textPrimary
│  5 fps                │
│  [★ Gợi ý]           │  ← badge accent #FFD600, text #212121 12px
└───────────────────────┘
 border 2px dashed #FFD600, radius 12px
 background: #FFFDE7 (vàng nhạt)
```

---

### Component Specs

#### A. SpeedSelectorBar (wrapper container)

| Thuộc tính | Giá trị |
|---|---|
| Vị trí | Giữa HintBar và hàng Action Buttons trong ColumnLayout CapturePage |
| Chiều cao | 110px (bao gồm label "Tốc độ phim:" + 3 nút + gợi ý text) |
| Chiều rộng | Layout.fillWidth |
| Background | NeoConstants.surface (#FFFFFF), border-radius 12px |
| Border | 1px solid #E0E0E0 |
| Padding trong | 12px top/bottom, 16px left/right |
| Spacing bên trong | spacingS (8px) giữa label và hàng nút; 0px giữa hàng nút và gợi ý text |

**Label "Tốc độ phim:"**
| Thuộc tính | Giá trị |
|---|---|
| Text | "Tốc độ phim:" |
| Typography | fontCaption (18px), weight regular, color NeoConstants.textSecondary (#616161) |
| Vị trí | Đầu dòng trái trong SpeedSelectorBar, trên hàng 3 nút |

#### B. SpeedOptionButton (3 nút: Chậm / Vừa / Nhanh)

| Thuộc tính | Giá trị |
|---|---|
| Layout | RowLayout, spacing 12px, fillWidth |
| Kích thước mỗi nút | Layout.fillWidth (1/3 chiều ngang) x 72px |
| Corner radius | 12px |
| Vùng chạm | fillWidth x 72px — luôn ≥ touchMin (52px) theo chiều dọc |

**Trạng thái Default (chưa chọn, không gợi ý):**
| Thuộc tính | Giá trị |
|---|---|
| Background | NeoConstants.surface (#FFFFFF) |
| Border | 1px solid #E0E0E0 |
| Icon | 28px, màu NeoConstants.textSecondary (#616161) |
| Text tên | fontBody (24px), NeoConstants.textPrimary (#212121) |
| Text fps | fontCaption (18px), NeoConstants.textSecondary (#616161) |
| Badge gợi ý | Ẩn |

**Trạng thái Suggested (gợi ý tự động, chưa được chọn bởi người dùng):**
| Thuộc tính | Giá trị |
|---|---|
| Background | #FFFDE7 (vàng nhạt) |
| Border | 2px dashed NeoConstants.accent (#FFD600) |
| Icon | 28px, màu NeoConstants.accent (#B8860B — tối hơn để đủ tương phản) |
| Text tên | fontBody (24px), NeoConstants.textPrimary |
| Badge "★ Gợi ý" | height 20px, background #FFD600, text #212121 12px bold, radius 4px, đặt dưới text fps |
| Animation | Border pulse nhẹ opacity 0.6→1.0 loop 1.5s (gợi ý thị giác không nhức mắt) |

**Trạng thái Active (đã được chọn bởi người dùng):**
| Thuộc tính | Giá trị |
|---|---|
| Background | #FFF3E0 (cam nhạt — on-brand với primary) |
| Border | 3px solid NeoConstants.primary (#FF7043) |
| Icon | 28px, màu NeoConstants.primary (#FF7043) |
| Text tên | fontBody (24px), bold, NeoConstants.primary (#FF7043) |
| Text fps | fontCaption (18px), NeoConstants.textSecondary |
| Badge "★ Gợi ý" | Ẩn (đã chọn rồi, không cần gợi ý nữa) |
| Animation khi chọn | scale 0.95→1.0 bounce 150ms (animFast) |

**Trạng thái Disabled (0 frame — chưa chụp gì):**
| Thuộc tính | Giá trị |
|---|---|
| Background | #F5F5F5 |
| Border | 1px solid #E0E0E0 |
| Opacity | 0.45 |
| Cursor | default (không thể click) |
| Icon / Text | Màu #9E9E9E |

**Trạng thái Hover (chuột di vào — chưa chọn):**
| Thuộc tính | Giá trị |
|---|---|
| Background | #F5F5F5 |
| Border | 2px solid NeoConstants.textSecondary (#616161) |
| Cursor | pointer |

#### C. Icon cho 3 mức tốc độ

| Mức | Icon Unicode | Ý nghĩa với trẻ | Alt nếu font không hỗ trợ |
|---|---|---|---|
| Chậm | 🐌 (U+1F40C) | Con sên → chậm chạp, dễ hiểu | SVG sên đơn giản |
| Vừa | 🐇 (U+1F407) | Con thỏ → nhanh vừa | SVG thỏ đơn giản |
| Nhanh | ⚡ (U+26A1) | Sấm sét → rất nhanh | SVG tia sét |

**Lưu ý cho python-dev**: Kiểm tra font system trên NEO One (Linux ARM64) có render đúng emoji không. Nếu không, dùng SVG bundled trong `resources/images/speed/`. Không dùng Image source mà dùng Text với emoji — đơn giản hơn và không cần file ảnh riêng nếu font ổn.

#### D. Gợi ý text (SpeedHintText)

| Thuộc tính | Giá trị |
|---|---|
| Hiện khi | frameCount > 0 VÀ gợi ý tự động đang active (khác với lựa chọn user) |
| Ẩn khi | frameCount = 0 HOẶC user đã chọn = mức gợi ý (không cần nhắc nữa) |
| Text mẫu (ít frame) | "💡 Phim ít tấm nên chọn Chậm để xem rõ nha!" |
| Text mẫu (nhiều frame) | "💡 Nhiều tấm rồi, chọn Nhanh cho phim mượt nha!" |
| Typography | fontCaption (18px), italic, NeoConstants.warning (#FF8F00) |
| Vị trí | Dưới hàng 3 nút, trong SpeedSelectorBar |
| Animation xuất hiện | fade in opacity 0→1 duration 300ms |

---

### Quy tắc gợi ý tự động (Logic)

| Số frame | Mức gợi ý | Lý do |
|---|---|---|
| 0 | Không gợi ý; toàn bộ disable | Chưa chụp gì |
| 1 – 15 | Chậm (5fps) | 15 frame ÷ 5fps = 3 giây — tối thiểu để xem hiểu câu chuyện |
| 16 – 30 | Vừa (8fps) | 20 frame ÷ 8fps = 2.5 giây — ngưỡng tốt cho stop-motion thủ công |
| > 30 | Nhanh (12fps) | Nhiều frame → phim đủ dài kể cả ở fps cao |

**Hành vi**: Mỗi khi frameCount thay đổi (sau chụp hoặc xoá), tính lại gợi ý. Nếu user đã chọn thủ công một mức — GIỮ lựa chọn đó (không override). Badge "★ Gợi ý" chỉ hiện trên mức gợi ý khi mức đó khác lựa chọn hiện tại của user.

---

### States — CapturePage tổng thể

| State | SpeedSelector | Nút "TẠO PHIM" | HintText |
|---|---|---|---|
| **Empty** (0 frame) | Hiện nhưng toàn bộ disabled + opacity 0.45 | Disabled | Ẩn |
| **HasFrames** (≥1) | Enabled; tính gợi ý; mức "Vừa" active mặc định | Disabled nếu <5 frame | Hiện nếu gợi ý ≠ lựa chọn |
| **ReadyToExport** (≥5) | Enabled, lựa chọn giữ nguyên | Enabled | Tùy trạng thái gợi ý |
| **Exporting** | Disabled (đang xử lý) | Disabled + spinner | Ẩn |

---

### Interaction

**Chọn tốc độ:**
1. Người dùng bấm 1 trong 3 nút → animation scale bounce 150ms.
2. Nút đó chuyển sang Active, 2 nút còn lại về Default.
3. HintText cập nhật nếu cần.
4. Toast nhẹ xuất hiện 1.5 giây: "Đã chọn: Chậm (5fps)" — vị trí góc phải dưới màn, không chặn thao tác.

**Toast thông báo khi đổi tốc độ:**
| Thuộc tính | Giá trị |
|---|---|
| Vị trí | Góc dưới phải màn, margin 24px cạnh và đáy |
| Kích thước | Auto (text + padding 12px) |
| Background | NeoConstants.textPrimary (#212121), opacity 0.85 |
| Text | "Đã chọn: [Tên mức] ([N]fps)" |
| Typography | fontCaption (18px), màu #FFFFFF |
| Corner radius | 8px |
| Duration | 1500ms rồi fade out 300ms |

**Truyền giá trị khi export:**
- Khi bấm "TẠO PHIM", giá trị fps hiện tại (5/8/12) được truyền vào `export_service.start_export(fps=selectedFps)`.
- Không có thêm popup xác nhận tốc độ — người dùng đã thấy mức đang chọn ngay trên UI.

**Phím cứng ThingBot:**
- EXPORT (IO2) / phím Enter: tạo phim với fps đang chọn — không thay đổi hành vi.
- Không cần thêm hành vi phím cứng cho bộ chọn tốc độ.

---

### Accessibility

- **Vùng chạm**: Mỗi nút tốc độ fillWidth/3 × 72px — luôn ≥ touchMin (52px) trên mọi màn hình ≥ 800px ngang.
- **Tương phản**:
  - Text tên ở Active: primary (#FF7043) trên #FFF3E0 = 3.2:1 — đủ cho large text 24px bold theo WCAG AA Large.
  - Text fps ở Active: textSecondary (#616161) trên #FFF3E0 = 4.6:1 (PASS AA).
  - Text disabled: #9E9E9E trên #F5F5F5 = 2.85:1 — thấp nhưng chấp nhận được vì element không tương tác (WCAG exempts disabled controls).
  - Badge "★ Gợi ý": #212121 trên #FFD600 = 8.2:1 (PASS AAA).
- **Không chỉ dựa vào màu**: Mức Active có cả màu khác + border dày hơn + bold + icon màu đổi. Mức Suggested có cả border dashed + badge text. Không phân biệt bằng màu đơn thuần.
- **Icon**: Emoji có alt text ngầm theo tên nút. Nếu dùng SVG, thêm `Accessible.name` cho mỗi nút.
- **Disabled state rõ ràng**: opacity 0.45 + cursor default — trẻ nhỏ nhìn thấy ngay không thể bấm.
- **Keyboard**: Tab chuyển qua 3 nút. Space/Enter chọn. Không cần mũi tên (3 lựa chọn đủ nhỏ để Tab qua).

---

### Tích hợp với layout CapturePage hiện tại

SpeedSelectorBar thêm khoảng ~110px vào chiều cao tổng. Cần đảm bảo:

- **LivePreview**: Giảm `Layout.fillHeight: true` nhưng vẫn `Layout.minimumHeight: 200` — ưu tiên Preview không bị ép quá nhỏ.
- **FilmStrip**: Giữ `Layout.preferredHeight: 120` không đổi.
- **SpeedSelectorBar**: `Layout.preferredHeight: 110`.
- **HintBar**: `Layout.preferredHeight: 50` — có thêm nút "Đổi camera" bên phải (xem T-005).
- **Action Buttons**: `Layout.preferredHeight: 80`.

Tổng chiều cao các element cố định: header (~140) + SpeedSelector (110) + FilmStrip (120) + HintBar (50) + Actions (80) + margins/spacing (~80) = ~580px tối thiểu. LivePreview lấy phần còn lại. Trên màn 768px cao: LivePreview còn ~188px — chấp nhận được (minimumHeight: 200 có thể cần hạ xuống 180 nếu màn hình nhỏ).

**Đề xuất**: Để SpeedSelectorBar không che LivePreview quá nhiều, có thể nhập SpeedSelectorBar vào cùng dòng FilmStrip (bên phải FilmStrip, cột riêng) nếu chiều ngang đủ. Phương án đó cần đánh giá thêm khi có màn thật. Hiện tại spec mặc định đặt dưới FilmStrip (dòng riêng) — đơn giản và rõ ràng hơn cho trẻ.

---

### Design Learnings

1. **"Vừa" là mặc định, không phải "Chậm"**: Mặc dù vấn đề gốc là phim chạy quá nhanh, đặt "Vừa" làm mặc định là đúng vì phần lớn phiên chụp sẽ có > 15 frame. "Chậm" chỉ đúng cho trường hợp ít frame — gợi ý tự động xử lý điều đó.

2. **Icon sinh vật > icon kỹ thuật**: Con sên/thỏ/sấm sét dễ hiểu với trẻ 6 tuổi hơn là mũi tên lên/xuống hay số fps. Số fps (5/8/12) vẫn cần hiển thị nhỏ bên dưới để Thợ Cả xác nhận kỹ thuật.

3. **Gợi ý là trợ lý, không phải quyết định**: Badge "★ Gợi ý" + HintText không ngăn user chọn khác. Sau khi user bấm chọn thủ công một lần, badge ẩn đi — không nhắc mãi. Tôn trọng quyết định của người dùng.

4. **Toast, không phải dialog**: Thông báo "Đã chọn: Chậm (5fps)" là toast góc màn, không modal. Modal sẽ làm gián đoạn flow — người dùng chỉ cần biết đã ghi nhận, không cần xác nhận thêm.

---

### Điểm cần PO duyệt

**P1 — Icon emoji vs SVG**: Emoji 🐌🐇⚡ đơn giản nhất về triển khai. Nhưng rendering emoji trên Linux ARM64 (NEO One) có thể khác nhau tùy font. Nếu PO muốn nhất quán tuyệt đối giữa macOS và NEO One → dùng SVG bundled. Đề xuất: dùng emoji trước, nếu NEO One render lỗi thì chuyển SVG.

**P2 — Vị trí SpeedSelectorBar**: Đề xuất hiện tại: dòng riêng dưới FilmStrip. Phương án phụ: cạnh phải của FilmStrip (cùng dòng). Phương án phụ tiết kiệm chiều dọc hơn nhưng phức tạp layout hơn. PO muốn ưu tiên chiều cao màn hình hay đơn giản layout?

**P3 — HintText bao lâu thì ẩn**: Hiện đề xuất ẩn ngay khi user chọn đúng mức gợi ý. Có cần để 3 giây trước khi ẩn không? Đề xuất: ẩn ngay để UI sạch hơn.
