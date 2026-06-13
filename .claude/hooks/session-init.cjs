/**
 * session-init — In context phiên làm việc cho neo-stopmotion team.
 *
 * Chạy ở SessionStart. Đọc con trỏ phase đang hoạt động + nhắc luật two-layer
 * separation (tầng team không bao giờ vào main).
 */

const { readFileSync } = require("fs");
const { join } = require("path");

const root = process.cwd();

function tryRead(p) {
  try {
    return readFileSync(join(root, p), "utf8");
  } catch {
    return null;
  }
}

function field(text, key) {
  if (!text) return null;
  const m = text.match(new RegExp(`${key}\\s*:\\s*"?([^"\\n]+)"?`));
  return m ? m[1].trim() : null;
}

const activePhase = tryRead("docs/04-phases/claude-active-phase.md");
const phasePath = field(activePhase, "active_phase_path");
const wave = field(activePhase, "active_wave");

console.log("[neo-team] ══════════════════════════════════════");
if (phasePath) {
  console.log(`[neo-team] Active phase: ${phasePath}${wave ? ` | wave: ${wave}` : ""}`);
} else {
  console.log("[neo-team] Chưa có phase hoạt động (xem docs/04-phases/claude-active-phase.md)");
}
console.log("[neo-team] LUẬT: tầng team (docs/ .claude/ CLAUDE.md) KHÔNG vào main.");
console.log("[neo-team] Đưa code lên main: docs/02-architecture/ops/ship-to-main.sh");
console.log("[neo-team] PO gõ 'SESSION START' để Coordinator báo cáo trạng thái.");
console.log("[neo-team] ══════════════════════════════════════");

process.exit(0);
