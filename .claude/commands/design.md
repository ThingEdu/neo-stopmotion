---
description: Sinh mockup HTML cho màn hình QML để PO duyệt hướng thiết kế trước khi code.
---

# /design — Design Ideation Workflow

PO gọi lệnh này để xin mockup HTML nhanh cho một màn hình/feature UI của neo-stopmotion.

## Context
Arguments: `$ARGUMENTS` (PO mô tả muốn thiết kế gì — tiếng Việt tự do).

## Việc của Coordinator

1. **Parse yêu cầu** — màn/feature/component, ràng buộc (giữ X, đổi Y), số variant (mặc định 3).
2. **Hỏi làm rõ** chỉ khi thật sự mơ hồ. Còn lại tin brief của PO.
3. **Đọc design tokens** từ `docs/03-codebase/design/tokens.md` (nếu có).
4. **Sinh mockup HTML** standalone trong `docs/03-codebase/design/brand/html-mockups/`:
   - Tên: `<screen>-variant-<a/b/c>.html`.
   - Mỗi file: HTML self-contained, CSS inline, dùng design tokens.
   - **Khung desktop/kiosk** (không phải khung điện thoại) — đây là app trên màn hình trạm.
   - Nội dung mock tiếng Việt thực tế cho trẻ 6-14 (đếm frame, nút IO1/IO2, màn QR…).
   - Font hệ thống; chữ TO, nút LỚN, ít chữ, nhiều biểu tượng — phù hợp trẻ nhỏ.
5. **Archive bản cũ** — nếu trùng tên, chuyển bản cũ sang `html-mockups/archive/` với hậu tố `-v1`, `-v2`.
6. **Báo PO** (tiếng Việt, ngắn): đường dẫn (`open <path>`) + 1 dòng mô tả mỗi variant + hỏi hướng PO chọn.

## Ràng buộc
- **CHƯA code QML** — chỉ mockup; python-dev code sau khi PO chốt hướng.
- **Không bỏ bước file HTML** dù yêu cầu đơn giản (mockup trực quan > mô tả chữ).
- Tối đa 5 variant/lần.
- Ngôn ngữ: nội dung mockup tiếng Việt; CSS/cấu trúc tiếng Anh.

## Sau khi PO chốt
Gợi ý bước tiếp: "PO chốt [variant X]. Em fire ux-designer viết design spec formal (`docs/03-codebase/design/specs/`), rồi python-dev code QML. OK chứ?"

## Ví dụ
- `/design 3 variant màn success sau khi export (phim + QR + nút làm phim mới)`
- `/design Màn live preview với onion skin: bố cục đếm frame to ở góc`
