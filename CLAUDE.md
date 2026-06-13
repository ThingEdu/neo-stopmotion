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
- **`SESSION START`**: Coordinator đọc branch → mode (`docs/02-architecture/working-modes-policy.md` §5), đọc `docs/04-phases/claude-active-phase.md` → `session-log.md` → `task-board.md`, báo trạng thái + top 3 next actions + blockers, **chờ PO**.
- **`SESSION END`**: Coordinator soạn "State of the Union" (≤60 dòng) vào `session-log.md`, cập nhật `task-board.md`, đề xuất commit, STOP.
- Hook `SessionStart` (`.claude/hooks/session-init.cjs`) tự in con trỏ phase + nhắc luật two-layer.

## Process — Plan → Wave → Confirm → Execute
Kể cả khi PO nói "cứ làm đi": trình wave table → tạo `wave-N/T-XXX.md` (Goal/Scope/AC exact file+location+change/Testing/Output Contract) → cập nhật task-board + session-log → PO confirm → mới fire agent. **File repo là source of truth**, không phải `TaskCreate/TaskUpdate`.

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
