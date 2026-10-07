#!/usr/bin/env python3
"""Record 30 ordinary seconds with the original game HUD, simulation and sound.

This is a chronological prefix, not a completed dungeon or a performance test.
The underlying full-expedition capture tool remains available unchanged by default.
"""
from pathlib import Path
import sys

from capture_arcanist_quality import main


def prefix_arguments(arguments):
    arguments = list(arguments)
    if not any(item == "--prefix-seconds" or item.startswith("--prefix-seconds=")
               for item in arguments):
        arguments += ["--prefix-seconds", "30"]
    return arguments


if __name__ == "__main__":
    raise SystemExit(main(prefix_arguments(sys.argv[1:]),
                         additional_input_paths=(Path(__file__),)))
