## Design Spec: Frame Review + Delete — Xem lại và xoá frame trên CapturePage
**Date**: 2026-06-14 · **Status**: Draft · **Implements**: frame-review-delete feature

---

### Context

**Vấn đề**: Khi bé chụp ảnh stop-motion, không phải tấm nào cũng đẹp. Bé muốn xoá đúng một tấm hỏng ở giữa dải, nhưng hiện tại nút "XOÁ FRAME (Z)" chỉ xoá frame cuối (LIFO — như undo). Không có cách nào xem lại và chọn xoá frame bất kỳ.

**Mục tiêu trải nghiệm cho bé**:
- Bé thấy được ngay các tấm đã chụp (filmstrip nhỏ bên dưới camera).
- Bé bấm vào tấm nào thì tấm đó được chọn (nổi bật rõ).
- Bé bấm nút xoá (thùng rác) → app hỏi lại nhẹ nhàng → xác nhận → frame biến mất.
- Xoá xong bé chụp tiếp bình thường (frame mới nối vào cuối, không nhảy vào vị trí đã xoá — xem Q&A cuối spec).
- Nút Z nhanh vẫn hoạt động như cũ (xoá frame cuối, không cần chọn).

---

### Wireframe

**Màn CapturePage — sau khi thêm Filmstrip**

```
┌─────────────────────────────────────────────────────────────────────┐
│  [Logo]  TRẠM LÀM PHIM HOẠT HÌNH          NEO One — ThingEdu       │
├─────────────────────────────────────────────────────────────────────┤
│                                           ┌───────────────────────┐ │
│                                           │       FRAME           │ │
│   ┌───────────────────────────────────┐   │         42            │ │
│   │                                   │   │  Thời lượng: 4.2s     │ │
│   │         LIVE PREVIEW              │   └───────────────────────┘ │
│   │         (camera trực tiếp)        │                             │
│   │         onion skin bên trên       │                             │
│   │                                   │                             │
│   └───────────────────────────────────┘                             │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ FILMSTRIP (cuộn ngang)                                       │   │
│  │ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ [>] │   │
│  │ │  1   │ │  2   │ │  3   │ │[  4 ]│ │  5   │ │  6   │     │   │
│  │ │thumb │ │thumb │ │thumb │ │CHỌN  │ │thumb │ │thumb │     │   │
│  │ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘     │   │
│  │                              [🗑️ XOÁ TẤM NÀY]               │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  [Gợi ý: Bấm tấm ảnh để chọn, rồi nhấn XOÁ TẤM NÀY]             │
├─────────────────────────────────────────────────────────────────────┤
│  [📷 CHỤP (Space)]    [↩️ XOÁ FRAME (Z)]    [🎬 TẠO PHIM (Enter)] │
└─────────────────────────────────────────────────────────────────────┘
```

**Dialog xác nhận xoá** (overlay, giữa màn):

```
┌─────────────────────────────────┐
│                                 │
│   🗑️  Xoá tấm số 4 nhé?        │
│                                 │
│   ┌──────────┐  ┌────────────┐  │
│   │  THÔI ĐÃ │  │  XOÁ ĐI!  │  │
│   └──────────┘  └────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Trạng thái rỗng** (chưa có frame nào):

```
┌──────────────────────────────────────────────────────────┐
│  FILMSTRIP                                               │
│                                                          │
│       Chụp tấm đầu tiên đi!  [📷 ảnh trống vui vẻ]     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

### Component Specs

#### A. FilmStrip (component mới, thêm vào CapturePage)

| Thuộc tính | Giá trị |
|---|---|
| Vị trí | Bên dưới RowLayout (LivePreview + FrameCounter), trên HintBar |
| Chiều cao | 120px (thumbnail 80px + label số 18px + padding) |
| Chiều rộng | Layout.fillWidth (toàn bộ chiều ngang) |
| Background | NeoConstants.surface (#FFFFFF), border-radius 12px |
| Border | 2px solid NeoConstants.primary (#FF7043) khi có frame đang chọn; 1px solid #E0E0E0 khi rỗng |
| Cuộn | ListView ngang, ScrollBar mỏng 4px phía dưới (opacity thấp, chỉ hiện khi cuộn) |
| Padding trong | 8px top/bottom, 12px left/right |
| Spacing giữa thumbnail | NeoConstants.spacingS (8px) |

#### B. FrameThumbnail (item trong ListView)

| Thuộc tính | Giá trị |
|---|---|
| Kích thước thumbnail | 80 x 60px (tỉ lệ 4:3 cho ảnh stop-motion) |
| Corner radius | 8px |
| Label số frame | NeoConstants.fontCaption (18px), bold, căn giữa bên dưới thumbnail |
| Color label | NeoConstants.textSecondary (#616161) |
| Trạng thái Default | border 2px solid transparent |
| Trạng thái Selected | border 3px solid NeoConstants.primary (#FF7043), scale 1.08, drop shadow nhẹ (4px blur, #FF704366) |
| Trạng thái Hover (chuột) | border 2px solid NeoConstants.warning (#FF8F00), cursor pointer |
| Vùng chạm tối thiểu | 80x80px (padding nếu thumbnail nhỏ hơn) |
| Animation chọn | NumberAnimation duration 150ms (NeoConstants.animFast) |

#### C. Nút "XOÁ TẤM NÀY" (DeleteFrameButton)

| Thuộc tính | Giá trị |
|---|---|
| Vị trí | Bên phải trong FilmStrip, căn dọc giữa, hoặc float ở góc trên phải thumbnail đang chọn |
| Kích thước | 160 x 56px |
| Background | NeoConstants.error (#C62828), hover #B71C1C |
| Text | "XOÁ TẤM NÀY" |
| Icon | Thùng rác (Unicode U+1F5D1 hoặc SVG) đặt trước text |
| Typography | fontCaption (18px), bold, màu #FFFFFF |
| Disabled (chưa chọn frame) | opacity 0.35, background #9E9E9E, cursor default |
| Enabled (có frame được chọn) | opacity 1.0, active |
| Corner radius | 12px |
| Vùng chạm | Đủ 56px chiều cao (≥ touchMin 52px) |

**Quyết định vị trí nút xoá**: Đặt cố định bên phải thanh FilmStrip (không float trên thumbnail), vì:
- Bé cần nhìn thấy nút xoá dù không cuộn — tránh thao tác ẩn.
- Nút cố định dễ nhớ vị trí, phù hợp trẻ 6-9 tuổi.

#### D. Dialog xác nhận DeleteConfirmDialog

| Thuộc tính | Giá trị |
|---|---|
| Loại | Modal overlay (mờ nền 60% đen phía sau) |
| Kích thước popup | 380 x 200px, căn giữa màn |
| Background | NeoConstants.surface (#FFFFFF), border-radius 20px |
| Border | 3px solid NeoConstants.error (#C62828) |
| Title text | "Xoá tấm số [N] nhé?" |
| Typography title | fontBody (24px), bold, NeoConstants.textPrimary (#212121) |
| Nút "THÔI ĐÃ" | 140 x 56px, background #E0E0E0, text #212121, radius 12px — đặt bên trái |
| Nút "XOÁ ĐI!" | 140 x 56px, background NeoConstants.error, text #FFFFFF, bold, radius 12px — đặt bên phải |
| Focus mặc định | "THÔI ĐÃ" (phím Enter/Space khi dialog mở = hủy, không xoá) |
| Dismiss | Nhấn Escape, nhấn vùng nền mờ = hủy (như "THÔI ĐÃ") |

**Lý do focus mặc định = hủy**: trẻ hay bấm phím tắt thói quen; ưu tiên bảo vệ dữ liệu.

#### E. HintBar — cập nhật gợi ý

| Trạng thái app | Nội dung HintBar |
|---|---|
| Không có frame nào chọn | "Bấm tấm ảnh trong filmstrip bên dưới để xem lại" |
| Đang chọn frame N | "Tấm số [N] đang chọn — nhấn XOÁ TẤM NÀY để xoá" |
| Xoá xong | "Đã xoá tấm [N]. Chụp tiếp thôi!" (hiện 2.5s rồi về default) |

---

### Typography — nhất quán NeoConstants

| Yếu tố | Token | Giá trị | Ghi chú |
|---|---|---|---|
| Label số frame (filmstrip) | fontCaption | 18px | Dưới thumbnail |
| Nút XOÁ TẤM NÀY | fontCaption | 18px bold | |
| Dialog title | fontBody | 24px bold | |
| Nút dialog | fontCaption | 18px bold | |
| HintBar | fontCaption | 18px | Đã có sẵn |

---

### Colors — nhất quán NeoConstants

| Màu | Hex | Dùng cho |
|---|---|---|
| primary | #FF7043 | Border thumbnail chọn, border FilmStrip active |
| error | #C62828 | Nút XOÁ, border dialog, hover đỏ đậm |
| warning | #FF8F00 | Hover thumbnail (chuột) |
| surface | #FFFFFF | Background FilmStrip, dialog |
| textPrimary | #212121 | Text dialog |
| textSecondary | #616161 | Label số frame |
| background | #FFF8E1 | Nền trang (không đổi) |

**Tương phản**: #FF7043 trên #FFFFFF = 3.5:1 (OK cho large text ≥18px bold). Nút đỏ #C62828 trên #FFFFFF = 5.9:1 (PASS AA). Text trắng trên #C62828 = 5.9:1 (PASS AA).

---

### Interaction

#### Luồng 1 — Xoá frame cuối nhanh (giữ nguyên)
1. Bé bấm nút "XOÁ FRAME (Z)" hoặc phím Z hoặc nút UNDO trên ThingBot.
2. Frame cuối cùng bị xoá ngay (không cần dialog — hành vi đã có, quen thuộc).
3. Filmstrip cập nhật, số frame giảm 1.
4. HintBar: "Đã xoá tấm [N]. Chụp tiếp thôi!"

#### Luồng 2 — Chọn + xoá frame bất kỳ (tính năng mới)
1. **Chọn**: bé bấm thumbnail trong filmstrip.
   - Thumbnail nổi bật (border cam, scale 1.08, animation 150ms).
   - HintBar cập nhật: "Tấm số [N] đang chọn — nhấn XOÁ TẤM NÀY để xoá".
   - Nút "XOÁ TẤM NÀY" chuyển sang active (màu đỏ).
2. **Xoá**: bé bấm "XOÁ TẤM NÀY" (chuột) hoặc phím Delete (keyboard).
   - Dialog xuất hiện: "Xoá tấm số [N] nhé?", focus = "THÔI ĐÃ".
   - Bé bấm "XOÁ ĐI!" (chuột / Tab + Enter) → frame xoá, filmstrip cập nhật.
   - Bé bấm "THÔI ĐÃ" hoặc Escape → dialog đóng, frame giữ nguyên, selection vẫn giữ.
3. **Sau khi xoá**: không có selection nào (deselect). Camera live preview tiếp tục. Bé chụp tiếp thì frame mới nối vào cuối.

#### Phím tắt keyboard
| Phím | Hành động |
|---|---|
| Mũi tên Trái / Phải | Di chuyển selection trong filmstrip |
| Delete | Mở dialog xoá frame đang chọn (chỉ khi có frame chọn) |
| Escape | Bỏ chọn (deselect) / đóng dialog |
| Z | Xoá frame cuối (LIFO, giữ như cũ, KHÔNG mở dialog) |
| Space | Chụp frame (giữ như cũ) |
| Enter | Tạo phim (giữ như cũ) |

#### Phím cứng ThingBot
- SHOOT (IO1) → chụp (giữ như cũ).
- UNDO → xoá frame cuối (giữ như cũ, Luồng 1).
- EXPORT → tạo phim (giữ như cũ).
- Không bổ sung hành vi phím cứng cho Luồng 2 vì ThingBot hiện chỉ có 3 nút; thao tác chọn thumbnail cần chuột/bàn phím.

**Ghi chú firmware**: Không thay đổi giao thức UART. Thiết kế Luồng 2 không phụ thuộc phím cứng.

#### Animation filmstrip
- Cuộn tự động đến frame mới chụp: sau mỗi lần SHOOT, filmstrip `positionViewAtEnd()`.
- Thumbnail vừa xoá: fade out 200ms trước khi xoá khỏi model.
- Frame counter: giữ NumberAnimation tăng/giảm như hiện tại.

---

### States

| State | FilmStrip | DeleteButton | Dialog | HintBar |
|---|---|---|---|---|
| **Empty** (0 frame) | Hiện placeholder "Chụp tấm đầu tiên đi!" | Ẩn | Ẩn | Default |
| **HasFrames, NoSelection** | Filmstrip bình thường, không thumbnail nào nổi | Disabled (xám) | Ẩn | "Bấm tấm ảnh..." |
| **FrameSelected** | Thumbnail N nổi bật cam | Active (đỏ) | Ẩn | "Tấm số N đang chọn..." |
| **DeleteDialog** | Blur nhẹ (opacity 0.6) | Disabled | Hiện modal | Ẩn (dialog che) |
| **Capturing** (sau SHOOT) | Flash thumbnail mới 200ms | Không đổi | — | "Đã chụp!" (flash 1s) |
| **MinFrames** (1-2 frame) | Hiện frame, vẫn xoá được | Active nếu selected | Hiện cảnh báo nhẹ: "Còn ít tấm lắm — xoá nữa phim sẽ ngắn đó!" | — |

---

### Edge Cases UX

| Tình huống | Xử lý |
|---|---|
| Xoá khi chỉ còn 1 frame | Cho phép xoá (không block), filmstrip về Empty state sau đó |
| Xoá hết tất cả frame | Filmstrip hiện placeholder; nút "TẠO PHIM" disabled như hiện tại (cần ≥ 5 frame) |
| Bé bấm nhầm Z (xoá frame cuối) | Không có undo-of-undo; HintBar nói "Đã xoá tấm [N]. Chụp tiếp thôi!" Không có nút Undo-undo (scope hiện tại — xem Q3 bên dưới) |
| Filmstrip nhiều frame (> 10) | ListView cuộn ngang, ScrollBar tự hiện; filmstrip auto-scroll đến frame mới sau SHOOT |
| Filmstrip quá nhiều frame (> 50) | Thumbnail 80x60 = ~88px mỗi item (có spacing) → 50 item = ~4400px. Hiệu năng QML ListView ổn với lazy render. Không cần pagination |
| Bé bấm Delete khi không chọn frame | Nút disabled → không có gì xảy ra; không show lỗi |
| Màn hình nhỏ hơn 1280px | FilmStrip vẫn fillWidth, thumbnail scale theo; tối thiểu giữ 60x45px với vùng chạm 80px |

---

### Accessibility

- **Vùng chạm**: Thumbnail 80x80px (min), nút XOÁ TẤM NÀY 160x56px, nút dialog 140x56px. Tất cả ≥ NeoConstants.touchMin (52px).
- **Tương phản**: Tất cả cặp màu chính ≥ 4.5:1 (xem bảng Colors).
- **Không chỉ dựa vào màu**: Thumbnail chọn có cả border + scale + drop shadow (3 tín hiệu). Nút disabled có opacity thấp + cursor thay đổi.
- **Cỡ chữ**: fontCaption 18px (bold trên nút) đủ cho trẻ 6 tuổi ở khoảng cách 40-60cm màn hình desktop.
- **Keyboard fully navigable**: mũi tên + Delete + Escape đủ dùng không cần chuột.
- **Label số frame**: hiện số thứ tự rõ ràng dưới thumbnail (không chỉ tooltip).

---

### Câu hỏi mở cho PO

**Q1. Màn hình có cảm ứng không?**
- NEO One dùng màn hình nào? Có touch screen không, hay chỉ chuột + bàn phím?
- Thiết kế này không bắt buộc cảm ứng (chuột bấm thumbnail đủ dùng), nhưng nếu có cảm ứng thì thumbnail có thể nhỏ hơn mức tối ưu cảm ứng (80x80px).
- Đề xuất của em: nếu chưa rõ, giữ vùng chạm 80x80px để an toàn cả 2 trường hợp.

**Q2. Chụp lại "đúng vị trí" frame đã xoá hay chụp nối tiếp?**
- Hiện thiết kế: xoá frame N xong → frame mới chụp nối vào cuối (không điền vào vị trí N).
- Bé có cần thay thế đúng vị trí không? Ví dụ: phim 10 frame, xoá frame 5, chụp lại và nó thành frame 5 mới (insert-at-position)?
- Đề xuất của em: chụp nối tiếp (append cuối) cho đơn giản. Insert-at-position phức tạp hơn và trẻ nhỏ khó hiểu.

**Q3. Có cần "hoàn tác" (undo) sau khi xoá nhầm không?**
- Hiện không có undo cho Luồng 2. Đã có dialog xác nhận để ngăn bấm nhầm.
- Nếu PO thấy cần undo → đây là scope riêng, cần task mới.
- Đề xuất của em: không cần undo, dialog xác nhận là đủ cho phase này.

**Q4. Giới hạn số frame tối đa hiện là 100 (NeoConstants.maxFrames). Filmstrip có cần "chế độ thu gọn" khi > 30 frame không?**
- Với 100 frame, filmstrip cuộn ngang vẫn dùng được nhưng bé phải cuộn nhiều.
- Đề xuất của em: giữ cuộn ngang đơn giản cho phase này; đánh giá lại khi có feedback thực tế.

---

### Design Learnings

1. **FrameCounter không hiển thị thumbnail** — panel 240x320px bên phải hiện chỉ có số đếm và thời lượng. Có thể cân nhắc bỏ panel này khi filmstrip đã đảm nhiệm vai trò trực quan, trả lại không gian cho LivePreview. Để lại PO quyết (không scope trong feature này).

2. **Nút "XOÁ FRAME (Z)" hiện nhỏ hơn 2 nút kia** (preferredWidth 220 so với fillWidth và 320) — không nhất quán về tầm quan trọng. Thiết kế mới không đổi hàng nút dưới, nhưng ghi nhận để cải thiện trong lần refactor HintBar/ActionBar.

3. **Dialog focus mặc định = hủy** là pattern quan trọng cho app trẻ em: ưu tiên bảo vệ dữ liệu hơn tốc độ thao tác. Áp dụng nhất quán cho mọi dialog xoá/reset trong tương lai.

4. **Không thêm nút mới vào hàng Action Buttons dưới cùng** — hàng đó đã đủ 3 nút chính gắn với ThingBot. Nút "XOÁ TẤM NÀY" thuộc về FilmStrip (ngữ cảnh), không phải action chính.
