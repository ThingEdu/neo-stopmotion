import sys
from pathlib import Path
from loguru import logger


def configure_logging(log_dir: Path | None = None, debug: bool = False) -> None:
    """Configure loguru logger. Console + optional file."""
    logger.remove()
    level = "DEBUG" if debug else "INFO"
    logger.add(
        sys.stderr,
        level=level,
        format="<green>{time:HH:mm:ss}</green> <level>{level: <8}</level> <cyan>{name}</cyan> | {message}",
    )

    if log_dir is not None:
        log_dir.mkdir(parents=True, exist_ok=True)
        logger.add(
            log_dir / "neostopmotion_{time:YYYY-MM-DD}.log",
            rotation="10 MB",
            retention="7 days",
            level=level,
        )
