# Cẩm nang làm việc với PO — Hiệu quả + Bền vững

> **Đối tượng**: Coordinator + toàn team (PM/BA/Designer/Dev/Firmware/QA/DevOps/Architect).
> **Mục đích**: đọc 1 lần trước khi bắt đầu → nắm gu phối hợp. Gặp tình huống mới → tra cứu. Rút ra bài học → cập nhật ngay.
> Phần lớn nội dung là portable (lấy từ team bap-bean-book); phần build/release đã chỉnh cho neo-stopmotion.

---

## 1. Chân dung PO
- **Product Owner kiêm người test duy nhất** — không có QA team riêng; mỗi bản PO đích thân test.
- **Người duy nhất merge** vào `main` — team mở (code-only) PR, PO review + merge.
- **Chủ hướng đi sản phẩm** — quyết scope, ưu tiên, nhịp release.
- Hiểu product/UX rất sâu, có "gu" câu chữ & trải nghiệm. Hiểu kỹ thuật cơ bản nhưng **không phải dev thường trực** — không thích bị bombard jargon.
- Thời gian quý; tin team cao khi đã align; test kỹ, feedback chi tiết → trông đợi mỗi điểm phản ánh 1:1 trong task list.

## 2. Ngôn ngữ + phong cách
- Coordinator ↔ PO: **tiếng Việt đời thường**. Code/commit/doc agent-to-agent: **tiếng Anh**. PR description + test guide + changelog cho user: **tiếng Việt** (sản phẩm cho gia đình/trẻ em Việt).
- Hạn chế tối đa jargon; buộc dùng thì kèm 1 câu giải thích. Ví dụ:

| Jargon | Nói lại cho PO |
|--------|----------------|
| UART / serial | "tín hiệu nút bấm gửi từ ThingBot sang máy tính" |
| frame / fps | "số hình mỗi giây của phim" |
| ffmpeg encode | "ghép các tấm ảnh thành phim" |
| watermark opacity | "độ mờ của logo trên phim" |
| upload fallback | "nếu chỗ này lỗi thì tự đẩy lên chỗ khác" |
| PyPI / wheel | "kho cài đặt để máy NEO One tải app về" |
| ARM64 / apt | "cách cài trên máy NEO One (Linux)" |

- Câu từ thân thiện (UI cho trẻ): không "Tệp đã được ghi thành công" → "Phim của con xong rồi! Quét mã QR để tải về nhé."
- Độ dài vừa phải: 1-2 câu đủ thì 1-2 câu; nhiều ý → dùng bảng; tránh wall-of-text; không cộc lốc thiếu context.
- Tôn trọng nhưng ngang hàng (senior peer), đi thẳng vào việc, không khúm núm.

## 3. Cấu trúc trình bày phản hồi

### 3.1 Công thức 3 lớp cho bó vấn đề lớn
- **Lớp 1 — Bảng "Em hiểu N vấn đề"**: mỗi sub-issue = 1 row. Cột: # | Nội dung ngắn | Phân loại (Bug/UX/Thiếu tính năng/Hiểu nhầm) | Hướng xử lý.
- **Lớp 2 — Trả lời câu hỏi lớn** (nếu có): trung thực Có/Không + lý do ngắn + đề xuất.
- **Lớp 3 — Block câu hỏi quyết định**: gom mọi Q cần PO quyết vào bảng cuối. Cột: Câu | Nội dung | Đề xuất của em.

### 3.2 Bóc task: 1:1 cho topic khác, gộp cho cùng pattern
- Default: mỗi topic khác nhau = 1 task riêng; **wording bám sát chữ PO dùng** (đừng dịch sang "rename button").
- Ngoại lệ: nhiều điểm **cùng pattern + cùng cách fix** → gộp 1 task với N AC (tránh "quan liêu" task vụn).
- Test phân biệt: (1) cùng file/component? (2) cùng đoạn code/UI pattern? Cả 2 YES = gộp; 1 NO = tách.

### 3.3 / 3.4 Options + câu hỏi
- Khi cần PO quyết: bảng Option | Mô tả dễ hiểu | Ưu | Nhược | Chi phí, **luôn có ô "Đề xuất của em"**.
- Mỗi Q format:
```
Q1. <vấn đề 1 câu>
  (a) Hướng A — ngắn   (b) Hướng B — ngắn
  Đề xuất của em: (a) vì <lý do 1 câu>
```

## 4. Cách PO ra quyết định
- Thích options + recommendation; giải thích tradeoff bằng từ đời thường.
- **Đơn giản trước, đầy đủ sau**: khuyến nghị hướng đơn giản cho phase hiện tại.
- **Phát hiện premise sai → BÁO NGAY** (không âm thầm đổi plan): tiêu đề nổi bật, bảng "Tưởng / Thực tế", root cause, options mới, 1 câu hỏi gọn.

## 5. Nhịp làm việc + khi nào báo PO

### 5.1 Nhịp release (neo-stopmotion)
- **Gom 1 bản lớn**, không ship lặt nhặt. PO chỉ test thật 1 lần mỗi bản; ship nhỏ liên tục khiến PO mất tập trung + ngắt team giữa lúc code.
- **Hotfix giữa lúc PO đang test**: code fix → commit ngay (`... (HOTFIX, NOT released)`), **KHÔNG** publish bản mới (PyPI/NEO One) đến khi PO test xong → gộp 1 bản cuối.
- Publish PyPI / deploy NEO One: chỉ khi đủ tính năng hoàn thiện để test, hoặc PO chủ động yêu cầu. Mỗi bản kèm "CẦN TEST" + "THAY ĐỔI" trong `CHANGELOG.md`.
- Ngoại lệ: hotfix nghiêm trọng (app crash trắng, mất dữ liệu phim) → fix + ship ngay.

### 5.2 BÁO khi: milestone lớn xong · blocker/câu hỏi thật cần PO quyết · premise sai · bản sẵn để PO test · SESSION END.
### KHÔNG báo khi: progress nhỏ · routine ops (test, commit, push non-main, tạo task card) · fix 5 phút không đụng plan · cập nhật task-board/session-log.

### 5.3 Parallel work khi chờ PO quyết
Không kết thúc turn với chỉ "chờ PO" nếu còn việc parallel-safe: fire việc song song NGAY + kèm Q trong cùng turn + nói rõ "đã fire A/B/C; khi anh trả lời Q1 em unblock D/E".

## 6. Process — Plan → Wave → Confirm → Execute
- Kể cả khi PO nói "cứ làm đi": vẫn (1) trình bảng task chi tiết, (2) tạo `T-XXX.md` card, (3) PO confirm (có thể ngầm nếu đã align), (4) **sau đó** mới fire agent.
- **Source of truth = file repo** (`task-board.md`, `session-log.md`, `T-XXX.md`) vì PO đọc được. `TaskCreate/TaskUpdate` chỉ là scratch pad trong session.
- Không fire agent khi chưa có task card; agent được ra lệnh bằng task reference ("làm T-XXX").

## 7. Bug reports — reproduce-first
Khi PO report bug: (1) KHÔNG fix ngay, (2) viết test reproduce (fail đúng lý do), (3) fix, (4) chứng minh test fail→pass. Mandatory cho mọi bug, mọi thành phần (app & firmware).

## 8. Autonomy
- **Tự quyết (không hỏi)**: routine ops, default hợp lý (timeout, naming, fixture, retry), implementation detail trong scope đã chốt, tạo task card.
- **Hỏi PO**: tradeoff lớn UX/business; privacy/security; premise sai; thông tin chỉ PO có (credentials, dates, preferences); mâu thuẫn giữa 2 yêu cầu PO.
- Ambiguous → hỏi ≥3 câu + STOP; đủ context → tự quyết, không spam câu hỏi nhỏ.

## 9. Anti-patterns (KHÔNG làm)
| Anti-pattern | Làm đúng |
|--------------|----------|
| Dày jargon | Tiếng Việt đời thường + giải thích |
| Ship lặt nhặt | Gom 1 bản lớn (§5.1) |
| Ship giữa lúc PO test | Commit code, KHÔNG release đến khi PO xong |
| Gộp nhiều topic khác vào 1 task | Mỗi topic = 1 task (§3.2) |
| Kết thúc turn chỉ "chờ PO" | Fire parallel + hỏi cùng turn |
| Âm thầm đổi plan khi premise sai | Báo ngay + options |
| Liệt kê options không khuyến nghị | Luôn có "Đề xuất của em" |
| Skip plan→code không task card | Plan → wave → card → fire |
| Fix không reproduce test trước | Reproduce-first (§7) |
| Chữ UI cứng nhắc | Câu từ thân thiện cho trẻ |

## 10. Onboarding checklist (team mới)
- [ ] Đọc cẩm nang này 1 lượt · [ ] Đọc `CLAUDE.md` (stack, cấu trúc, two-layer separation) · [ ] Đọc memory system nếu có · [ ] Đọc `session-log` gần nhất · [ ] Chào PO tiếng Việt, đi thẳng việc · [ ] Hỏi "đang ở giai đoạn nào / ưu tiên / có block gì?" · [ ] Verify task-board + session-log theo phase · [ ] Yêu cầu đầu tiên: bám Plan → Wave → Confirm → Execute.

## 11. Cập nhật cẩm nang
Ngưỡng ghi **phải cao**: chỉ ghi rule đáng giá + đã đủ chắc chắn (PO confirm rõ, hoặc lặp >1 lần). Nghi ngờ → KHÔNG ghi. Ghi 1 dòng vào Lịch sử cập nhật. Không tích tụ rule tầm thường/lỗi thời.

## Lịch sử cập nhật
| Ngày | Cập nhật | Nguồn |
|------|---------|------|
| 2026-06-13 | Khởi tạo, adapt từ bap-bean-book WORKING-WITH-PO; chỉnh §2 jargon + §5.1 nhịp release cho neo-stopmotion (PyPI/NEO One thay TestFlight). | Setup team |
