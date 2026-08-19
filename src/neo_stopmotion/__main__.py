import os
import sys

from neo_stopmotion.media_env import configure_media_backend

# Must run before Qt Multimedia is imported — the backend is picked at load time.
configure_media_backend(os.environ, sys.platform)

from neo_stopmotion.app import run  # noqa: E402


def main() -> None:
    sys.exit(run())


if __name__ == "__main__":
    main()
