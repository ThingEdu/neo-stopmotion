"""ffmpeg-based video exporter for stop-motion frame sequences."""
from __future__ import annotations
import subprocess
from pathlib import Path
from loguru import logger


class ExportError(RuntimeError):
    pass


class VideoExporter:
    def __init__(
        self,
        fps: int = 10,
        ffmpeg: str = "ffmpeg",
        codec: str = "libx264",
        pix_fmt: str = "yuv420p",
        gif_scale_width: int = 640,
    ) -> None:
        self.fps = fps
        self.ffmpeg = ffmpeg
        self.codec = codec
        self.pix_fmt = pix_fmt
        self.gif_scale_width = gif_scale_width

    def export_mp4(self, frames_dir: Path, output_path: Path) -> Path:
        cmd = [
            self.ffmpeg, "-y",
            "-framerate", str(self.fps),
            "-i", str(frames_dir / "frame_%04d.png"),
            "-c:v", self.codec,
            "-pix_fmt", self.pix_fmt,
            "-vf", "scale=1280:720:force_original_aspect_ratio=decrease,"
                   "pad=1280:720:(ow-iw)/2:(oh-ih)/2",
            str(output_path),
        ]
        logger.info(f"ffmpeg MP4: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True)
        if result.returncode != 0:
            raise ExportError(
                f"ffmpeg MP4 failed: {result.stderr.decode(errors='ignore')[:500]}"
            )
        return output_path

    def export_gif(self, frames_dir: Path, output_path: Path) -> Path:
        palette = output_path.parent / "_palette.png"
        try:
            cmd1 = [
                self.ffmpeg, "-y",
                "-framerate", str(self.fps),
                "-i", str(frames_dir / "frame_%04d.png"),
                "-vf", f"scale={self.gif_scale_width}:-1:flags=lanczos,palettegen",
                str(palette),
            ]
            r1 = subprocess.run(cmd1, capture_output=True)
            if r1.returncode != 0:
                raise ExportError(
                    f"ffmpeg palettegen failed: {r1.stderr.decode(errors='ignore')[:500]}"
                )
            cmd2 = [
                self.ffmpeg, "-y",
                "-framerate", str(self.fps),
                "-i", str(frames_dir / "frame_%04d.png"),
                "-i", str(palette),
                "-filter_complex",
                f"scale={self.gif_scale_width}:-1:flags=lanczos[x];[x][1:v]paletteuse",
                str(output_path),
            ]
            r2 = subprocess.run(cmd2, capture_output=True)
            if r2.returncode != 0:
                raise ExportError(
                    f"ffmpeg paletteuse failed: {r2.stderr.decode(errors='ignore')[:500]}"
                )
            return output_path
        finally:
            if palette.exists():
                palette.unlink()
