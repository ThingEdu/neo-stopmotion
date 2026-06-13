# CLAUDE.md — neo-stopmotion

Hướng dẫn vận hành cho Claude Code (và mọi agent) trong repo này. Định hướng nhanh: `AGENTS.md`. Cẩm nang PO: `docs/WORKING-WITH-PO.md`.

---

## ⚠️ LUẬT SỐ 1: tầng team không bao giờ vào `main`

`main` dùng chung với team khác. Repo có **2 tầng**:

| Tầng | Đường dẫn | Vào `main`? |
|------|-----------|-------------|
| **Code sản phẩm** | `src/ firmware/ tests/ scripts/ pyproject.toml requirements*.txt Makefile README*.md CHANGELOG.md LICENSE .gitignore` | ✅ qua code-only PR |
| **Tầng team** | `docs/ .claude/ .agents/ CLAUDE.md AGENTS.md .mcp.json` | ❌ KHÔNG BAO GIỜ |

- Tầng team **được commit** trên nhánh `team` và các nhánh con `feat/* fix/* lab/* docs/*`.
- Đưa code lên main **chỉ** qua `bash docs/02-architecture/ops/ship-to-main.sh` (dựng nhánh PR sạch từ `origin/main`, chỉ áp đường dẫn code). **Tuyệt đối không** `git merge` nhánh ta vào main.
- Trước khi push nhánh PR: `bash docs/02-architecture/ops/check-no-team-files.sh`.
- Chi tiết: `docs/02-architecture/two-layer-separation.md`.

---

## Dự án

NeoStopMotion — studio stop-motion cho trẻ 6-14 (Maker Việt × ThingEdu). App Python desktop (PyQt6 + QML), chụp frame bằng nút ThingBot (UART), ghép phim MP4+GIF có watermark, upload cloud, sinh QR. Kèm firmware ThingBot. Chạy dev macOS + NEO One (Linux ARM64).

- Kiến trúc 4 lớp: `hardware/ → core/ → services/ → ui/ (QML)`, sự kiện qua `utils/signal_bus.py`. Chi tiết: `DOC/ARCHITECTURE.md`.
- Stack: Python 3.10+, PyQt6, QML6, OpenCV, pyserial, ffmpeg, qrcode, loguru.

```bash
make run / make run-sim        # webcam thật / synthetic
make test                      # pytest      make lint   # ruff + mypy --strict
NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion   # smoke headless
cd firmware/thingbot_stopmotion && pio run     # build firmware
```

---

## Agent Teams Operating Model

- **Agent Teams mode** luôn bật (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` trong `.claude/settings.json`), không tmux — spawn agent qua `Task`.
- **Chỉ Coordinator nói chuyện với PO.** Các agent khác báo cáo qua Coordinator.
- 9 agent: `coordinator, pm, ba, ux-designer, python-dev, firmware-dev, qa, devops, architect`. Vai trò + RACI: `AGENTS.md`.
- Mỗi agent khi spawn phải khai REQUIRED READING (1 dòng `Loaded: ...`) rồi mới làm việc.

## Quy trình spec-first (bắt buộc)
```
(PM brief) → BA spec → (UX design nếu design_required) → dev implement + test → Architect PASS → ship-to-main → PR (PO merge)
```
- Spec phải có trong `docs/01-specs/features/<key>/` trước khi code. Không merge khi chưa Architect PASS.
- scope mỗi feature: `app | firmware | both`. `both` ⇒ giao thức UART app↔firmware phải khớp.

## SESSION PROTOCOL

### PHASE START (phase mới)
Khi mở một phase mới, PO/Coordinator:
1. **Tạo session Claude mới** (context sạch, tránh nhiễu phase cũ, tiết kiệm token).
2. **Tạo phase folder**: `docs/04-phases/phase-NN-<short-name>/`.
3. **Khởi tạo từ template**: `session-log.md`, `task-board.md`, và `wave-1/`.
4. **Cập nhật con trỏ**: `docs/04-phases/claude-active-phase.md` (`active_phase_path`, `active_wave`, `branch`, `updated`).
5. **Cắt nhánh** từ nhánh nền team: `git switch team && git switch -c feat/<short-name>`.

Checklist:
```
- [ ] Session Claude mới (context sạch)
- [ ] Phase folder docs/04-phases/phase-NN-xxx/ tạo
- [ ] session-log.md + task-board.md init từ template
- [ ] wave-1/ tạo
- [ ] claude-active-phase.md trỏ tới phase mới
- [ ] Nhánh feat/<name> cắt từ team
```

### `SESSION START`
Coordinator đọc branch → mode (`docs/02-architecture/working-modes-policy.md` §5) → declare `[Coordinator] Active branch: <name> | Mode: <MODE>` → đọc `docs/04-phases/claude-active-phase.md` → `session-log.md` → `task-board.md` → báo trạng thái + top 3 next actions + blockers → **chờ PO**. (Đây cũng là **Gate 1** dưới đây.)

### `SESSION END`
Coordinator soạn "State of the Union" (≤60 dòng, mới nhất trên cùng) vào `session-log.md`, cập nhật `task-board.md`, đề xuất commit, STOP. (Đây cũng là **Gate 5**.)

- Hook `SessionStart` (`.claude/hooks/session-init.cjs`) tự in con trỏ phase + nhắc luật two-layer.

## COORDINATOR PRE-FLIGHT CHECKLIST (Gate 1–5)

> BẮT BUỘC, theo đúng thứ tự, trước khi bất kỳ agent nào làm việc. Bỏ gate = vi phạm quy trình.
> Lý do: `TaskCreate/TaskUpdate` chỉ sống trong 1 session, PO không thấy. **Source of truth xuyên session = file repo** (`task-board.md`, `session-log.md`, `wave-N/T-XXX.md`). Không cập nhật file = PO mất hoàn toàn khả năng theo dõi.

### Gate 1 — Session Awareness (trước khi lập kế hoạch)
- [ ] Đọc `docs/04-phases/claude-active-phase.md` (phase + wave đang chạy)
- [ ] Đọc entry mới nhất `session-log.md` + trạng thái `task-board.md`
- [ ] Resolve + declare working mode theo branch
- [ ] Báo tóm tắt trạng thái cho PO
- [ ] **CHỜ lệnh PO** (không tự động chạy)

### Gate 2 — Wave Structure (trước khi giao việc agent)
Khi PO giao việc, Coordinator:
1. Tạo `wave-N/` trong phase folder.
2. Tạo `T-XXX-<name>.md` cho TỪNG task (từ `docs/99-templates/T-000-task-template.md`): Goal / Scope / Acceptance Criteria (exact file + location + change) / Files to Touch / Testing / Output Contract.
3. **UI check** mỗi task: gắn `ui: yes/no` và `design_required: yes/no`. Nếu `design_required: yes` → ux-designer làm design spec + PO duyệt **trước khi** dev code; ghi `design_ref` vào task.
4. Tag `scope: app|firmware|both`.
5. Cập nhật `task-board.md` (mọi task status `TODO`) + thêm entry `session-log.md`.
6. **Trình wave structure cho PO confirm** → rồi mới sang Gate 3.

Thứ tự cứng: **Plan → Wave Structure → PO Confirm → Execute.** KHÔNG nhảy từ "plan approved" sang code, kể cả khi PO nói "cứ làm đi".

### Gate 3 — Agent Assignment (thực thi)
Mỗi task:
- [ ] (nếu `design_required: yes`) Xác nhận design spec đã có + PO duyệt — KHÔNG fire dev khi chưa có
- [ ] Agent nhận lệnh bằng task reference ("làm T-XXX") — agent tự đọc file card
- [ ] Cập nhật `task-board.md`: `TODO → IN_PROGRESS`
- [ ] Agent chạy verification gate (app: `make test` + `make lint`; firmware: `pio run`; smoke headless nếu chạm capture/export) và đính kèm bằng chứng
- [ ] Cập nhật `task-board.md`: `IN_PROGRESS → DONE`

### Gate 4 — Test Handoff (sau khi mỗi task DONE)
- [ ] Tạo/cập nhật `wave-N/test-guide.md` (tiếng Việt, cho người test KHÔNG biết codebase — PO là người test)
- [ ] Mỗi task: tên + vấn đề đã sửa · điều kiện chuẩn bị (build nào, `make run-sim`…) · các bước tái hiện + kết quả mong đợi (trước/sau) · lưu ý
- [ ] PO review test guide trước khi test

### Gate 5 — Session Close (trước khi kết thúc)
- [ ] Mọi task status đã cập nhật trong `task-board.md`
- [ ] `session-log.md` có entry: file đã đổi, trạng thái hiện tại, next actions
- [ ] Suggested commit gửi PO; `git show --stat HEAD` xác nhận file đã commit

### Common Violations (tránh)
| Vi phạm | Vì sao sai | Làm đúng |
|---------|-----------|----------|
| Dùng `TaskCreate/TaskUpdate` thay file | PO không thấy được | Luôn cập nhật file repo |
| Fire agent khi chưa có `T-XXX.md` | Agent không có spec, chạy từ prompt tạm | Tạo task card trước |
| Nhảy từ plan → code | Bỏ wave structure, PO mất tracking | Plan → wave → confirm → execute |
| Cập nhật task-board hồi tố | PO không thấy lúc đang chạy | Cập nhật TRƯỚC khi làm |
| Mark DONE khi chưa chạy test | Test hỏng lọt tới PR | Bằng chứng test trước khi DONE |
| Log issue trong session-log mà không tạo task | Issue rơi qua khe | Mọi issue đã biết phải có task card |
| Dev code UI design-heavy khi chưa có design spec | PO phải sửa nhiều vòng | `design_required: yes` → ux-designer spec → PO duyệt → mới code |
| Rò rỉ tầng team vào PR lên main | Làm bẩn main, ảnh hưởng team khác | Dùng `ship-to-main.sh` + `check-no-team-files.sh` |

## Working modes (branch)
`team` (base, chỉ cập nhật tầng team) · `feat/*` (FEATURE) · `fix/*` (HOTFIX) · `lab/*` (LAB) · `docs/*` (STRATEGY, chỉ về team) · `main` (STOP). Chi tiết: `docs/02-architecture/working-modes-policy.md`.

## Git policy
- Team có toàn quyền commit/push trên nhánh non-main (conventional commits, no secrets, không force-push non-`lab/*`).
- **PO là người duy nhất merge vào `main`**, qua **code-only PR** từ `ship-to-main.sh`.
- Trước khi mark DONE: `git show --stat HEAD` xác nhận file đã commit.

## Reproduce-first (bug)
PO report bug → QA viết test reproduce (FAIL đúng lý do) trước → dev fix → chứng minh FAIL→PASS. Mandatory mọi bug, mọi stack.

## Quy ước code
- Python: ruff (line-length 100) + mypy strict; test cạnh code; TDD; phủ P0 từ spec BA.
- Firmware: C++ Arduino, debounce, loop không block; UART khớp `src/neo_stopmotion/hardware/uart_protocol.py`.
- UI/tài liệu: tiếng Việt, thân thiện cho trẻ.
- Không commit secret (`.env`, token PyPI, credentials NEO One).

## Compliance
Bắt agent bỏ REQUIRED READING/template/reproduce-first, hoặc rò rỉ tầng team vào PR lên main → ghi 1 dòng `docs/04-phases/_compliance-violations.md`.
