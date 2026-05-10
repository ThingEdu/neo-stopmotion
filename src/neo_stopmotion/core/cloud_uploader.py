"""Public file-sharing upload — catbox.moe with 0x0.st fallback.

No auth, no setup. Uploads via multipart POST and returns a public URL.
- catbox.moe: permanent files up to 200MB (primary). Free, no expiry.
- 0x0.st: 30-day temp files (fallback when catbox is unreachable).

Both services are operated by third parties, so:
- Uploads contain whatever the user captured. Don't enable auto-upload of
  sensitive content without consent (this app is for kids' film share with
  their own parents — consent is implicit per the trạm flow).
- Services may rate-limit or go down. We catch errors and raise UploadError
  so the caller can fall back to local-only sharing.
"""
from __future__ import annotations
from pathlib import Path
import requests
from loguru import logger


class UploadError(RuntimeError):
    pass


class CloudUploader:
    """Upload a file to a public sharing service. Returns the share URL."""

    USER_AGENT = "NeoStopMotion/1.0 (+https://github.com/makerviet/neostopmotion)"
    CATBOX_URL = "https://catbox.moe/user/api.php"
    OX0_URL = "https://0x0.st"

    def __init__(self, timeout_seconds: float = 120.0) -> None:
        self.timeout = timeout_seconds

    def upload(self, file_path: Path) -> str:
        path = Path(file_path)
        if not path.exists():
            raise UploadError(f"File not found: {path}")
        size_mb = path.stat().st_size / (1024 * 1024)
        logger.info(f"Uploading {path.name} ({size_mb:.2f} MB) to public share...")

        for attempt_name, fn in (
            ("catbox.moe", self._upload_catbox),
            ("0x0.st", self._upload_0x0st),
        ):
            try:
                url = fn(path)
                logger.info(f"{attempt_name} upload OK: {url}")
                return url
            except Exception as e:
                logger.warning(f"{attempt_name} upload failed: {e}")

        raise UploadError("All upload services failed")

    def _upload_catbox(self, path: Path) -> str:
        with path.open("rb") as f:
            response = requests.post(
                self.CATBOX_URL,
                data={"reqtype": "fileupload"},
                files={"fileToUpload": (path.name, f)},
                headers={"User-Agent": self.USER_AGENT},
                timeout=self.timeout,
            )
        response.raise_for_status()
        url = response.text.strip()
        if not url.startswith("https://files.catbox.moe/"):
            raise UploadError(f"Unexpected catbox response: {url[:200]}")
        return url

    def _upload_0x0st(self, path: Path) -> str:
        with path.open("rb") as f:
            response = requests.post(
                self.OX0_URL,
                files={"file": (path.name, f)},
                headers={"User-Agent": self.USER_AGENT},
                timeout=self.timeout,
            )
        response.raise_for_status()
        url = response.text.strip()
        if not url.startswith("http"):
            raise UploadError(f"Unexpected 0x0.st response: {url[:200]}")
        return url


def generate_qr(url: str, output_path: Path, box_size: int = 12) -> Path:
    """Generate a PNG QR code for `url` at `output_path`."""
    import qrcode

    qr = qrcode.QRCode(
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=box_size,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    img.save(str(output_path))
    return output_path
