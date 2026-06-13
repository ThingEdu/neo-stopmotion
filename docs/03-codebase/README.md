# 03-codebase

Ghi chú codebase theo thành phần + flow + design + devops. **Kiến trúc nguồn** nằm ở
`DOC/ARCHITECTURE.md` (tài liệu sản phẩm gốc) — đây chỉ bổ sung góc nhìn team/flow.

| Thư mục | Nội dung |
|---------|----------|
| `design/specs/` | Design spec QML (UX Designer) |
| `design/brand/` | Brand: logo Maker Việt, palette, mockup HTML (`/design`) |
| `devops/runbooks/` | Runbook deploy NEO One, publish PyPI, cài đặt ARM64 |

Kiến trúc 4 lớp (tóm tắt, chi tiết ở `DOC/ARCHITECTURE.md`):
`hardware/ → core/ → services/ → ui/ (QML)`, sự kiện qua `utils/signal_bus.py`.
