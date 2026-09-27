"""Create a release-signed Android App Bundle from the Google Play Beta preset."""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
TOOLS_ROOT = Path(
    os.environ.get("EMBERFALL_ANDROID_TOOLS", PROJECT_ROOT.parent / ".android-game-tools")
).expanduser()
CREDENTIALS_PATH = Path(
    os.environ.get(
        "EMBERFALL_SIGNING_CREDENTIALS",
        TOOLS_ROOT / "release-signing" / "credentials.json",
    )
).expanduser()
DEFAULT_OUTPUT = PROJECT_ROOT / "build" / "emberfall-play-beta.aab"


def main() -> int:
    if not CREDENTIALS_PATH.is_file():
        print(
            f"Upload-key credentials were not found at {CREDENTIALS_PATH}. "
            "Create or configure a private upload key before exporting a Play release.",
            file=sys.stderr,
        )
        return 2

    if os.name != "nt" and CREDENTIALS_PATH.stat().st_mode & (stat.S_IRWXG | stat.S_IRWXO):
        print("Signing credentials must be readable only by the current user (chmod 600).", file=sys.stderr)
        return 2

    credentials = json.loads(CREDENTIALS_PATH.read_text(encoding="utf-8"))
    for field in ("keystore", "alias", "password"):
        if not credentials.get(field):
            print(f"Signing credentials are missing the {field!r} field.", file=sys.stderr)
            return 2

    env = os.environ.copy()
    env.update(
        {
            "ANDROID_HOME": str(TOOLS_ROOT / "sdk"),
            "ANDROID_SDK_ROOT": str(TOOLS_ROOT / "sdk"),
            "ANDROID_USER_HOME": str(TOOLS_ROOT / "android-user"),
            "ANDROID_AVD_HOME": str(TOOLS_ROOT / "avd"),
            "XDG_CONFIG_HOME": str(TOOLS_ROOT / "xdg-config"),
            "XDG_DATA_HOME": str(TOOLS_ROOT / "xdg-data"),
            "XDG_CACHE_HOME": str(TOOLS_ROOT / "xdg-cache"),
            "GRADLE_USER_HOME": str(TOOLS_ROOT / "gradle-home"),
            "GODOT_ANDROID_KEYSTORE_RELEASE_PATH": str(credentials["keystore"]),
            "GODOT_ANDROID_KEYSTORE_RELEASE_USER": str(credentials["alias"]),
            "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD": str(credentials["password"]),
        }
    )

    bundled_jdk = TOOLS_ROOT / "jdk17" / "root" / "usr" / "lib" / "jvm" / "java-17-openjdk-amd64"
    if bundled_jdk.is_dir():
        env["JAVA_HOME"] = str(bundled_jdk)
        env["PATH"] = str(bundled_jdk / "bin") + os.pathsep + env.get("PATH", "")

    godot = os.environ.get("GODOT_BIN") or shutil.which("godot")
    if not godot:
        print("Godot 4.7.2 was not found; set GODOT_BIN to the executable path.", file=sys.stderr)
        return 2

    output = Path(os.environ.get("EMBERFALL_BETA_AAB", DEFAULT_OUTPUT)).expanduser()
    output.parent.mkdir(parents=True, exist_ok=True)
    command = [
        godot,
        "--headless",
        "--path",
        str(PROJECT_ROOT),
        "--export-release",
        "Google Play Beta",
        str(output),
    ]
    result = subprocess.run(command, env=env, check=False)
    if result.returncode == 0:
        print(f"Created signed Play Beta bundle: {output}")
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
