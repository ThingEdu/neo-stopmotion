---
id: T-013
title: "QA — test toàn bộ redesign + phím tắt + Thư viện phim + test guide PO"
assignee: "qa"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-4"
priority: "P0"
scope: "app"
ui: "yes"
design_required: "no"
design_ref: "N/A"
dependencies: ["T-010", "T-011", "T-012"]
references:
  - "docs/04-phases/phase-01-neo-device-polish/wave-4/design-ref.md"
---

# T-013: QA verification + test guide

## Mục tiêu
Kiểm chứng tất cả tính năng + phím tắt hoạt động đúng, UI bám sát mockup, không hồi quy. Viết test-guide tiếng Việt cho PO test GUI.

## Phạm vi
- Chạy `make test` + `make lint` + smoke headless → báo PASS/FAIL kèm artifact.
- Đối chiếu **ảnh chụp GUI ↔ mockup** (Capture B, camera picker, delete dialog, success, library): chấm fidelity, liệt kê sai khác.
- Test **từng phím tắt** theo bản đồ T-011 (mỗi phím × mỗi màn) → bảng PASS/FAIL.
- Test luồng Thư viện: vào (`G`), chọn (`◀▶▲▼`), xem (`Enter`), lưu (`S`), chép link (`L`), xoá (`Del`), thoát (`Esc`).
- Test hồi quy luồng cũ: chụp → xoá → tạo phim → success.
- Viết `wave-4/test-guide.md` cho PO (người test không biết codebase).

## Acceptance Criteria
- [ ] **AC1**: make test + lint PASS (đính kèm output).
- [ ] **AC2**: Bảng kiểm phím tắt: mọi phím × màn PASS hoặc ghi rõ FAIL.
- [ ] **AC3**: Bảng đối chiếu mockup ↔ GUI cho 5 màn; sai khác lớn → tạo issue.
- [ ] **AC4**: `wave-4/test-guide.md` đầy đủ (chuẩn bị, bước, kết quả mong đợi trước/sau).
- [ ] **AC5**: Không product code thay đổi bởi QA (review-only).

## Output Contract khi xong
- [ ] Báo cáo PASS/FAIL kèm artifact + bảng phím tắt + bảng fidelity.
- [ ] `wave-4/test-guide.md`.
