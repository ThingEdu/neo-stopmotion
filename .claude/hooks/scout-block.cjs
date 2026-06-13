/**
 * scout-block — Chặn đọc vào các thư mục tốn token vô ích (kế thừa từ ClaudeKit,
 * chỉnh cho dự án Python/Qt).
 */

const BLOCKED_DIRS = [
  "node_modules",
  "__pycache__",
  ".git",
  ".venv",
  "dist",
  "build",
  ".mypy_cache",
  ".pytest_cache",
  ".ruff_cache",
  "*.egg-info",
  ".pio",          // PlatformIO build
];

let input = {};
try {
  input = JSON.parse(require("fs").readFileSync(0, "utf8") || "{}");
} catch {
  process.exit(0);
}

const ti = input.tool_input ?? {};
const target = ti.command ?? ti.path ?? ti.pattern ?? ti.file_path ?? "";

function hits(target, dir) {
  if (dir.startsWith("*")) {
    // suffix pattern like *.egg-info
    const suf = dir.slice(1);
    return new RegExp(`(^|[\\s/])[^\\s/]*${suf.replace(/\./g, "\\.")}([/\\s]|$)`).test(target);
  }
  // match dir as a full path segment (start, after slash, or after whitespace)
  const d = dir.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(`(^|[\\s/])${d}([/\\s]|$)`).test(target);
}

const blocked = BLOCKED_DIRS.some((d) => hits(target, d));

if (blocked) {
  console.error(`[scout-block] Chặn truy cập tốn token: ${target}`);
  process.exit(2); // non-zero = block tool call
}

process.exit(0);
