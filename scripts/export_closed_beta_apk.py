"""Export and verify the signed ARM64 APK used for manual closed-beta testing."""

from __future__ import annotations

import configparser
import hashlib
import json
import os
from pathlib import Path
import re
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


def read_preset() -> dict[str, str]:
    config = configparser.ConfigParser(interpolation=None)
    preset_path = PROJECT_ROOT / "export_presets.cfg"
    if not config.read(preset_path, encoding="utf-8"):
        raise RuntimeError("Android export presets could not be read.")
    matches = [
        section
        for section in config.sections()
        if not section.endswith(".options")
        and config.get(section, "name", fallback="").strip('"') == "Android Closed Beta APK"
    ]
    if len(matches) != 1:
        raise RuntimeError("Could not resolve one Android Closed Beta APK export preset.")
    options_name = matches[0] + ".options"
    if options_name not in config:
        raise RuntimeError("The closed-beta APK preset has no options section.")
    options = config[options_name]
    result = {
        "export_path": config.get(matches[0], "export_path", fallback="").strip('"'),
        "package": options.get("package/unique_name", "").strip('"'),
        "version_code": options.get("version/code", "").strip('"'),
        "version_name": options.get("version/name", "").strip('"'),
        "min_sdk": options.get("gradle_build/min_sdk", "24").strip('"'),
        "target_sdk": options.get("gradle_build/target_sdk", "36").strip('"'),
        "internet": options.get("permissions/internet", "").strip('"').lower(),
        "gradle": options.get("gradle_build/use_gradle_build", "").strip('"').lower(),
    }
    if any(not result[key] for key in ("export_path", "package", "version_code", "version_name")):
        raise RuntimeError("The closed-beta APK preset is missing package or version metadata.")
    if result["internet"] != "false" or result["gradle"] != "false":
        raise RuntimeError("The closed-beta APK must be offline and use Godot's direct APK exporter.")
    return result


def require_private_file(path: Path, label: str) -> None:
    if not path.is_file():
        raise RuntimeError(f"{label} was not found.")
    if os.name != "nt" and path.stat().st_mode & (stat.S_IRWXG | stat.S_IRWXO):
        raise RuntimeError(f"{label} must be readable only by the current user (chmod 600).")


def bundled_java_home() -> Path | None:
    candidates = sorted((TOOLS_ROOT / "temurin17").glob("jdk-*/bin/java"))
    candidates.extend((TOOLS_ROOT / "android-studio" / "jbr" / "bin" / name for name in ("java", "java.exe")))
    for executable in candidates:
        if executable.is_file():
            return executable.parent.parent
    return None


def main() -> int:
    try:
        require_private_file(CREDENTIALS_PATH, "Upload-key credentials")
        credentials = json.loads(CREDENTIALS_PATH.read_text(encoding="utf-8"))
        if not isinstance(credentials, dict) or any(
            not credentials.get(field) for field in ("keystore", "alias", "password")
        ):
            raise RuntimeError("Upload-key credentials are incomplete.")
        keystore = Path(str(credentials["keystore"])).expanduser()
        require_private_file(keystore, "Play upload keystore")
        preset = read_preset()
    except (OSError, json.JSONDecodeError, RuntimeError) as error:
        print(str(error), file=sys.stderr)
        return 2

    sdk = TOOLS_ROOT / "sdk"
    build_tools = sdk / "build-tools" / "36.1.0"
    apksigner = build_tools / ("apksigner.bat" if os.name == "nt" else "apksigner")
    aapt = build_tools / ("aapt.exe" if os.name == "nt" else "aapt")
    if not apksigner.is_file() or not aapt.is_file():
        print("Android SDK Build-Tools 36.1.0 are required.", file=sys.stderr)
        return 2

    godot = os.environ.get("GODOT_BIN") or shutil.which("godot")
    if not godot:
        print("Godot 4.7.2 was not found; set GODOT_BIN to the executable path.", file=sys.stderr)
        return 2

    env = os.environ.copy()
    env.update(
        {
            "ANDROID_HOME": str(sdk),
            "ANDROID_SDK_ROOT": str(sdk),
            "ANDROID_USER_HOME": str(TOOLS_ROOT / "android-user"),
            "ANDROID_AVD_HOME": str(TOOLS_ROOT / "avd"),
            "XDG_CONFIG_HOME": str(TOOLS_ROOT / "xdg-config"),
            "XDG_DATA_HOME": str(TOOLS_ROOT / "xdg-data"),
            "XDG_CACHE_HOME": str(TOOLS_ROOT / "xdg-cache"),
            "GODOT_ANDROID_KEYSTORE_RELEASE_PATH": str(keystore.resolve()),
            "GODOT_ANDROID_KEYSTORE_RELEASE_USER": str(credentials["alias"]),
            "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD": str(credentials["password"]),
        }
    )
    java_home = bundled_java_home()
    if java_home is not None:
        env["JAVA_HOME"] = str(java_home)
        env["PATH"] = str(java_home / "bin") + os.pathsep + env.get("PATH", "")

    configured_output = os.environ.get("EMBERFALL_CLOSED_BETA_APK")
    output = Path(configured_output).expanduser() if configured_output else PROJECT_ROOT / preset["export_path"]
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [godot, "--headless", "--path", str(PROJECT_ROOT), "--export-release", "Android Closed Beta APK", str(output)],
        env=env,
        check=False,
    )
    if result.returncode:
        return result.returncode
    if not output.is_file():
        print("Godot reported success but the closed-beta APK is missing.", file=sys.stderr)
        return 2

    signed = subprocess.run([str(apksigner), "verify", "--verbose", str(output)], env=env, check=False)
    if signed.returncode:
        return signed.returncode
    manifest = subprocess.run(
        [str(aapt), "dump", "badging", str(output)],
        env=env,
        check=False,
        capture_output=True,
        text=True,
    )
    if manifest.returncode:
        print("Android manifest could not be inspected.", file=sys.stderr)
        return manifest.returncode
    expected_package = (
        f"package: name='{preset['package']}' versionCode='{preset['version_code']}' "
        f"versionName='{preset['version_name']}'"
    )
    if expected_package not in manifest.stdout:
        print("APK package or version metadata does not match the closed-beta preset.", file=sys.stderr)
        return 2
    if f"sdkVersion:'{preset['min_sdk']}'" not in manifest.stdout:
        print("APK minimum SDK does not match the closed-beta preset.", file=sys.stderr)
        return 2
    if f"targetSdkVersion:'{preset['target_sdk']}'" not in manifest.stdout:
        print("APK target SDK does not match the closed-beta preset.", file=sys.stderr)
        return 2
    if "android.permission.INTERNET" in manifest.stdout:
        print("The offline closed-beta APK unexpectedly requests internet access.", file=sys.stderr)
        return 2
    orientation = subprocess.run(
        [str(aapt), "dump", "xmltree", str(output), "AndroidManifest.xml"],
        env=env,
        check=False,
        capture_output=True,
        text=True,
    )
    if orientation.returncode or not re.search(
        r"android:screenOrientation\([^)]*\)=\(type 0x10\)0x0(?:\s|$)", orientation.stdout
    ):
        print("APK manifest does not enforce the requested landscape orientation.", file=sys.stderr)
        return 2

    digest = hashlib.sha256()
    with output.open("rb") as apk:
        for chunk in iter(lambda: apk.read(1024 * 1024), b""):
            digest.update(chunk)
    checksum_path = output.with_suffix(output.suffix + ".sha256")
    checksum_path.write_text(f"{digest.hexdigest()}  {output.name}\n", encoding="ascii")
    print(f"Created and verified signed closed-beta APK: {output}")
    print(f"SHA-256: {checksum_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
