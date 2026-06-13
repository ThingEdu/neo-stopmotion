# Repository Guidelines — neo-stopmotion (team layer)

Định hướng nhanh cho mọi agent (Claude Code, Codex, hoặc người). Quy trình đầy đủ: `CLAUDE.md`.

> ⚠️ File này thuộc **tầng team** — KHÔNG merge vào `main`. Xem `docs/02-architecture/two-layer-separation.md`.

## Cấu trúc & module

- `src/neo_stopmotion/` — app Python (PyQt6/QML). Kiến trúc 4 lớp: `hardware/ → core/ → services/ → ui/`, sự kiện qua `utils/signal_bus.py`.
- `firmware/thingbot_stopmotion/` — firmware ThingBot (Arduino C++/PlatformIO), giao thức UART.
- `tests/` — pytest (unit cạnh code nó kiểm).
- `scripts/` — `install_on_neo.sh` (cài NEO One ARM64), `publish.sh` (PyPI).
- `DOC/` — tài liệu sản phẩm gốc (ARCHITECTURE, USER_GUIDE, SYSTEM_GUIDE, EXPERIENCE_GUIDE).
- `docs/` — tầng team (governance, spec, phase, template). Không lên main.

## Build / Test / Dev

```bash
make run        # webcam thật        make run-sim   # synthetic (không cần webcam)
make test       # pytest             make lint      # ruff + mypy --strict
NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion   # smoke headless
cd firmware/thingbot_stopmotion && pio run    # build firmware
```

## Coding style
- Python: ruff (line-length 100), mypy strict; test cạnh code; TDD.
- Firmware: C++ Arduino, debounce nút, loop không block; giao thức UART khớp `src/neo_stopmotion/hardware/uart_protocol.py`.
- Tài liệu/UI: tiếng Việt, thân thiện cho trẻ 6-14.
- Mọi stack: test phủ P0 từ spec của BA; architect chạy test độc lập trước khi PASS.

## Agent Teams Operating Model
- Chạy **Agent Teams mode** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, trong `.claude/settings.json`), không tmux — spawn agent qua `Task` tool trong cùng session.
- **Chỉ Coordinator nói chuyện với PO.** Các agent khác (`pm, ba, ux-designer, python-dev, firmware-dev, qa, devops, architect`) báo cáo qua Coordinator.
- Task code theo đúng agent (app Python → `python-dev`, firmware → `firmware-dev`, hạ tầng/PyPI/NEO One → `devops`).
- Feature cross-stack: (PM brief) → BA spec → (UX design nếu cần) → dev implement → Architect review trước merge.
- Tracking sống ở `docs/04-phases/<phase>/{task-board.md, session-log.md, wave-N/T-XXX.md}`. `TaskCreate/TaskUpdate` chỉ là scratch trong session; **file repo là source of truth**.

## UI Design Workflow
- Tag task: `ui: yes/no`, `design_required: yes/no`. Chỉ chạy design step khi `design_required: yes`.
- Artifact design: `docs/03-codebase/design/specs/` (từ `docs/99-templates/design-spec-template.md`). Brand ở `docs/03-codebase/design/brand/`.

## Coordinator Startup (SESSION START)
1. Đọc `CLAUDE.md`, rồi `docs/04-phases/claude-active-phase.md`.
2. Resolve working mode theo branch prefix (`docs/02-architecture/branch-naming-convention.md`).
3. Đọc `session-log.md` + `task-board.md` của phase.
4. Báo trạng thái, top 3 next actions, blockers; **chờ PO**.

## Commit & PR
- Commit: conventional, imperative, scoped — `feat(core): ...`, `fix(ui): ...`, `feat(firmware): ...`, `docs: ...`. Kèm `Refs: T-XXX`.
- Nhánh: `<type>/<short-name>`; cut từ `team` (xem `branch-naming-convention.md`).
- Team có toàn quyền commit/push trên nhánh non-main. **PO là người duy nhất merge vào `main`** — và CHỈ qua **code-only PR** (`docs/02-architecture/ops/ship-to-main.sh`). KHÔNG `git merge` thẳng vào main.

## Bảo mật
- Không commit secret (`.env`, token PyPI, credentials NEO One). Ship `.env.example`.
- Sản phẩm cho trẻ em — không telemetry bên thứ ba nếu PO chưa duyệt.
