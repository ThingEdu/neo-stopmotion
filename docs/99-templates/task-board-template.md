# Task Board — Phase: [Tên phase]

> **Cập nhật**: YYYY-MM-DD

## Tổng quan
| Metric | Count |
|--------|-------|
| Tổng task | X |
| ⚪ TODO | X |
| 🔵 IN_PROGRESS | X |
| 🔴 BLOCKED | X |
| 🟣 REVIEW | X |
| 🟢 DONE | X |

---

## Wave 1: [Mô tả]
| ID | Task | Owner | Status | Scope | Deps | Notes |
|----|------|-------|--------|-------|------|-------|
| T-001 | ... | ba | ⚪ TODO | app | - | |
| T-002 | ... | python-dev | 🔵 IN_PROGRESS | app | T-001 | |
| T-003 | ... | firmware-dev | 🔴 BLOCKED | firmware | - | chờ protocol |
| T-004 | ... | architect | 🟣 REVIEW | both | T-002,T-003 | |

---

## Blocked
| ID | Task | Bị chặn bởi | Cần làm gì | Owner |
|----|------|------------|-----------|-------|
| T-003 | ... | thiếu chốt giao thức UART | BA chốt với PO | ba |

## Legend
⚪ TODO · 🔵 IN_PROGRESS · 🔴 BLOCKED · 🟣 REVIEW · 🟢 DONE

## WIP
| Loại | Đang dở | Limit | Trạng thái |
|------|---------|-------|-----------|
| Feature | 1 | 3 | OK |
