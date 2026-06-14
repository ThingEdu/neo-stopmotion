import os
import sys

# NEO One (Allwinner sunxi) ships a V4L2 stateless H.264 decoder (v4l2slh264dec)
# that outranks the software decoder but fails buffer allocation under Qt's
# GStreamer backend, so SuccessPage video never autoplays. Force GStreamer to
# pick the software decoder (avdec_h264). Must run before Qt Multimedia loads.
if sys.platform.startswith("linux"):
    os.environ.setdefault("GST_PLUGIN_FEATURE_RANK", "v4l2slh264dec:NONE")

from neo_stopmotion.app import run  # noqa: E402


def main() -> None:
    sys.exit(run())


if __name__ == "__main__":
    main()
