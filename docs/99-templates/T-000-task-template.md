---
id: T-XXX
title: "[Tiêu đề ngắn]"
assignee: "[coordinator|ba|ux-designer|python-dev|firmware-dev|qa-tester|architect]"
status: "[TODO|IN_PROGRESS|BLOCKED|REVIEW|DONE]"
phase: "[tên phase]"
wave: "wave-N"
priority: "[P0|P1|P2]"
scope: "[app|firmware|both]"
ui: "[yes|no]"
design_required: "[yes|no]"
design_ref: "[đường dẫn design spec, hoặc N/A]"
dependencies: []
references:
  - "docs/01-specs/features/<key>/spec.md"
---

# T-XXX: [Tiêu đề]

## Mục tiêu
[1 câu]

## Phạm vi
### Trong phạm vi
- ...
### Ngoài phạm vi
- ...

## Câu hỏi làm rõ (bắt buộc nếu mơ hồ — tối thiểu 3)
1. ...
2. ...
3. ...

**Trả lời từ PO:**
| # | Câu hỏi | Trả lời | Ngày |
|---|---------|---------|------|

## Acceptance Criteria (kèm file/dòng/thay đổi)
- [ ] **AC1**: "..."
  - **File**: `src/neo_stopmotion/...py` hoặc `firmware/...`
  - **Vị trí**: dòng X-Y
  - **Thay đổi**: ...

## Test (bắt buộc — không có kết quả test = chưa xong)
### BA Test Scenarios (copy từ spec)
| TS-ID | Scenario | Priority | Cần test? |
|-------|----------|----------|-----------|
| TS-XX | ... | P0 | YES |

### Test File Mapping
| TS-ID | Test file | Method |
|-------|-----------|--------|
| TS-XX | `tests/unit/test_...py` | `test_...` |

### Lệnh
```bash
make test
make lint
# (nếu chạm export/capture) smoke:
NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion
# (firmware) pio run
```
Cổng chấp nhận:
- [ ] Mọi P0 có test, đã chạy PASS
- [ ] ruff + mypy PASS
- [ ] (firmware) pio run PASS + bước test on-device
- [ ] (both) giao thức UART app↔firmware khớp

## Rủi ro / Ghi chú
- ...

## Output Contract khi xong
- [ ] Code trong `src/` và/hoặc `firmware/`
- [ ] Test PASS
- [ ] Sẵn sàng cho architect review
- [ ] Đưa lên main qua `ship-to-main.sh` (không lẫn tầng team)
