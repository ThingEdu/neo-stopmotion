# Session Log — Phase: phase-01-neo-device-polish

> Mới nhất trên cùng (đảo thời gian). Mỗi entry ≤60 dòng.

---

## Session 2026-06-14 — PHASE START: khởi tạo phase + Wave 1 structure

### Thay đổi (theo file)
| File | Loại | Mô tả |
|------|------|-------|
| `docs/04-phases/phase-01-neo-device-polish/session-log.md` | CREATED | File này — khởi tạo phase |
| `docs/04-phases/phase-01-neo-device-polish/task-board.md` | CREATED | Task board Wave 1 với T-001, T-002 |
| `docs/04-phases/phase-01-neo-device-polish/wave-1/T-001-gstreamer-autoplay.md` | CREATED | Task card: cài GStreamer H.264 codec trên NEO One |
| `docs/04-phases/phase-01-neo-device-polish/wave-1/T-002-desktop-launcher.md` | CREATED | Task card: tạo icon desktop launcher trên NEO One |
| `docs/04-phases/claude-active-phase.md` | UPDATED | Trỏ tới phase-01-neo-device-polish, wave-1 |

### Trạng thái hiện tại
- **Nhánh**: `feat/neo-device-polish` (tạo từ `feat-team-workflow-setup` — nhánh base hiện tại)
- **Wave**: Wave 1 — 0/2 task xong (cả 2 ở TODO)
- **scope**: app (scripts/install_on_neo.sh + môi trường thiết bị)
- **Blockers**: Không — đang chờ PO confirm wave structure trước khi sang Gate 3

### Quyết định của PO
| # | Quyết định | Ngày |
|---|-----------|------|
| 1 | Mở phase-01-neo-device-polish, làm 2 issue thiết bị trước | 2026-06-14 |
| 2 | Tên phase: neo-device-polish, nhánh: feat/neo-device-polish | 2026-06-14 |

### 3 việc kế tiếp
1. [ ] PO confirm wave structure (bảng T-001/T-002) → Gate 3
2. [ ] Giao T-001 cho devops: cài gstreamer1.0-libav + thêm vào install_on_neo.sh
3. [ ] Giao T-002 cho devops: tạo Desktop launcher + thêm vào install_on_neo.sh

### Câu hỏi cần PO
- Wave structure đã đúng chưa? Anh confirm để em sang Gate 3 giao việc cho agent.
- T-001 (GStreamer): QA sẽ verify trên thiết bị bằng cách chạy app sau fix, xác nhận phim tự play. Anh chấp nhận reproduce-first (QA chứng minh không play TRƯỚC fix)?
- T-002 (Desktop icon): Exec trong .desktop trỏ về `/usr/local/bin/neo-stopmotion` (system pip) hay `neo-stopmotion` (rely on PATH)? Đề xuất: `/usr/local/bin/neo-stopmotion` cho chắc.

---
