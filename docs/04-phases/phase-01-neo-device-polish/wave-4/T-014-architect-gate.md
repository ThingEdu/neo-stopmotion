---
id: T-014
title: "Architect — gate PASS/FAIL pre-merge cho wave-4"
assignee: "architect"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-4"
priority: "P0"
scope: "app"
ui: "no"
design_required: "no"
design_ref: "N/A"
dependencies: ["T-010", "T-011", "T-012", "T-013"]
references:
  - "docs/04-phases/phase-01-neo-device-polish/wave-4/design-ref.md"
---

# T-014: Architect gate wave-4

## Mục tiêu
Cổng chất lượng cuối trước ship-to-main: xác nhận spec-first, kiến trúc 4 lớp, test, lint đều đạt.

## Acceptance Criteria
- [ ] **AC1**: Chạy độc lập `make test` + `make lint` → PASS.
- [ ] **AC2**: Kiến trúc 4 lớp giữ nguyên: LibraryService thuộc services/, không để QML gọi thẳng core; image provider đúng tầng ui.
- [ ] **AC3**: Spec-first: T-009 spec có + PO duyệt trước khi T-012 code; design_ref (mockup) hiện diện.
- [ ] **AC4**: Không rò rỉ tầng team vào diff code (`check-no-team-files.sh`).
- [ ] **AC5**: Verdict PASS/FAIL/BLOCKED kèm lý do.

## Output Contract khi xong
- [ ] Báo cáo gate; nếu PASS → coordinator chuẩn bị `ship-to-main.sh`.
