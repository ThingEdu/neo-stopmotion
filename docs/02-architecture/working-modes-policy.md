# Working Modes Policy — neo-stopmotion

> Quy định team vận hành trên mỗi loại nhánh. Companion: `branch-naming-convention.md`,
> `two-layer-separation.md`. **Status**: Active.

## Overview

| Branch | Goal | Commit Freedom | Quality Bar | Lên `main`? |
|--------|------|----------------|-------------|-------------|
| **team** | Giữ & cập nhật tầng team | Team commit/push tự do | Review-ready | **Không bao giờ** (chỉ là base) |
| **feat/** | Ship feature có spec | Team commit/push tự do | Production-ready | Code-only PR (PO merge) |
| **foundation/** | Trích asset sạch | Team commit/push tự do | Production-ready | Code-only PR |
| **lab/** | Thử nghiệm | Team commit/push tự do (force-push OK) | Functional | Không bao giờ |
| **fix/** | Hotfix ngoài phase | Team commit/push tự do | Build pass + verified | Code-only PR |
| **docs/** | Sửa policy/agents/tài liệu team | Team commit/push tự do | Review-ready | **Không lên main** (về `team`) |

> PO trao team toàn quyền commit/push trên nhánh non-main. **PO là người duy nhất
> merge vào `main`**, và chỉ qua **code-only PR** (`ship-to-main.sh`).

## 1. Feature (`feat/*`)
- Cut từ `team` → thừa hưởng tầng team.
- Spec phải có trong `docs/01-specs/features/<key>/` TRƯỚC khi code.
- Build + test pass mọi thành phần bị ảnh hưởng (app: pytest+ruff+mypy; firmware: pio build).
- Merge: **Architect PASS** → `ship-to-main.sh` → PR vào main (PO merge, squash).
- Cập nhật `task-board.md` + `session-log.md` mỗi session; có `wave-N/T-XXX.md`.

## 2. Lab (`lab/*`)
- Khám phá nhanh, không ràng buộc production. Force-push OK. Không enforce lint/test.
- KHÔNG hardcode secret. Lab **không bao giờ** merge; asset giá trị trích qua `foundation/*`.

## 3. Hotfix (`fix/*`)
- Bug ngoài phase. 1 fix / nhánh. Reproduce-first (viết test fail trước khi fix).
- Tạo `docs/04-phases/hotfixes/<name>/summary.md` + cập nhật `index.md`.
- Lên main: code-only PR, Architect review tuỳ scope/rủi ro.

## 4. Strategy/Docs (`docs/*`)
- Sửa CLAUDE.md, agents, policy, ADR, WORKING-WITH-PO. **Chỉ merge về `team`** (tầng team không lên main).

## 5. Branch Mode Resolution (SESSION START)
```
1. Đọc tên nhánh hiện tại
2. Khớp prefix (xem branch-naming-convention §4)
3. Declare: "[Coordinator] Active branch: <name> | Mode: <MODE>"
   main → STOP. team → TEAM-BASE. feat/fix/lab/foundation/docs → mode tương ứng.
```

## 6. Definition of Done

### Feature — Done khi:
- Mọi AC trong `T-XXX.md` đạt.
- App: `make test` + `make lint` PASS (test code compile + chạy, không chỉ build).
- Firmware: `pio run` PASS + bước test on-device.
- (scope both) giao thức UART app↔firmware khớp.
- Agent đã đọc & xác minh trạng thái code hiện tại khớp giả định spec trước khi code.
- (design_required) design spec đã có + PO duyệt TRƯỚC khi code.
- Không TODO/FIXME thiếu task; mọi issue phát hiện đều có task card.
- Flow doc cập nhật; task-board + session-log cập nhật.
- **Architect PASS** + `check-no-team-files.sh` PASS.
- PR mở qua `ship-to-main.sh` kèm test plan tiếng Việt cho PO.

### Hotfix — Done khi: build pass, fix verified (reproduce test PASS), hotfix folder + index cập nhật, PR ready.

## 7. Prohibited (mọi mode)
- Làm trực tiếp / push trực tiếp lên `main`.
- **`git merge` thẳng nhánh ta vào main** (luôn dùng `ship-to-main.sh`).
- Force-push trên nhánh non-`lab/*`.
- Commit secret (`.env`, token, credentials).
- Feature: code khi chưa có spec; nhảy từ plan sang code không có wave/task; merge khi chưa Architect PASS.

## 8. Checklists

### Trước khi commit
```
□ Không secret · □ Không file ngoài scope · □ build/test pass (feat/foundation) · □ mọi issue có task card
```
### Trước khi mở PR lên main
```
□ Mode cho phép PR (không phải lab) · □ Architect PASS · □ ship-to-main.sh đã chạy · □ check-no-team-files.sh PASS · □ PR body có test plan tiếng Việt
```

## Decision Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-06-13 | Layer "two-layer separation" lên quy ước bap-bean-book | main dùng chung với team khác — tầng team không được làm bẩn main |
