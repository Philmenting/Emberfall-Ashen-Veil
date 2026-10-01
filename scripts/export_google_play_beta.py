"""Create and verify a release-signed Android App Bundle for Google Play Beta."""

from __future__ import annotations

import configparser
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
BUNDLETOOL = Path(
    os.environ.get(
        "BUNDLETOOL_JAR",
        TOOLS_ROOT / "temurin17" / "bundletool-all-1.18.3.jar",
    )
).expanduser()


def read_play_preset() -> dict[str, str]:
    config = configparser.ConfigParser(interpolation=None)
    if not config.read(PROJECT_ROOT / "export_presets.cfg", encoding="utf-8"):
        raise RuntimeError("Android export presets could not be read.")
    matches = [
        section
        for section in config.sections()
        if not section.endswith(".options")
        and config.get(section, "name", fallback="").strip('"') == "Google Play Beta"
    ]
    if len(matches) != 1:
        raise RuntimeError("Could not resolve one Google Play Beta export preset.")
    options_section = matches[0] + ".options"
    if options_section not in config:
        raise RuntimeError("The Google Play Beta export preset has no options section.")
    options = config[options_section]
    fields = {
        "package": "package/unique_name",
        "version_code": "version/code",
        "version_name": "version/name",
        "min_sdk": "gradle_build/min_sdk",
        "target_sdk": "gradle_build/target_sdk",
        "internet": "permissions/internet",
    }
    result = {field: options.get(key, "").strip('"') for field, key in fields.items()}
    if any(not value for value in result.values()):
        raise RuntimeError("The Google Play Beta preset is missing version or SDK metadata.")
    if result["internet"].lower() != "false":
        raise RuntimeError("The Google Play Beta preset must not request internet access.")
    return result


def bundled_java_home() -> Path | None:
    candidates = sorted((TOOLS_ROOT / "temurin17").glob("jdk-*/bin/java"))
    candidates.extend((TOOLS_ROOT / "android-studio" / "jbr" / "bin" / name for name in ("java", "java.exe")))
    for executable in candidates:
        if executable.is_file():
            return executable.parent.parent
    return None


def main() -> int:
    credentials_path = CREDENTIALS_PATH
    if not credentials_path.is_file():
        print(
            f"Upload-key credentials were not found at {credentials_path}. "
            "Configure a private Play upload key before exporting a release.",
            file=sys.stderr,
        )
        return 2
    if os.name != "nt" and credentials_path.stat().st_mode & (stat.S_IRWXG | stat.S_IRWXO):
        print("Signing credentials must be readable only by the current user (chmod 600).", file=sys.stderr)
        return 2

    try:
        credentials = json.loads(credentials_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"Upload-key credentials could not be read: {error}", file=sys.stderr)
        return 2
    if not isinstance(credentials, dict):
        print("Upload-key credentials must be a JSON object.", file=sys.stderr)
        return 2
    for field in ("keystore", "alias", "password"):
        if not credentials.get(field):
            print(f"Signing credentials are missing the {field!r} field.", file=sys.stderr)
            return 2

    keystore = Path(str(credentials["keystore"])).expanduser()
    if not keystore.is_file():
        print("The configured Play upload keystore does not exist.", file=sys.stderr)
        return 2
    if os.name != "nt" and keystore.stat().st_mode & (stat.S_IRWXG | stat.S_IRWXO):
        print("The Play upload keystore must be readable only by the current user (chmod 600).", file=sys.stderr)
        return 2
    if not BUNDLETOOL.is_file():
        print(f"Bundletool is missing: {BUNDLETOOL}", file=sys.stderr)
        return 2

    try:
        preset = read_play_preset()
    except (OSError, RuntimeError) as error:
        print(str(error), file=sys.stderr)
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
            "GODOT_ANDROID_KEYSTORE_RELEASE_PATH": str(keystore.resolve()),
            "GODOT_ANDROID_KEYSTORE_RELEASE_USER": str(credentials["alias"]),
            "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD": str(credentials["password"]),
        }
    )

    java_home = bundled_java_home()
    if java_home is not None:
        env["JAVA_HOME"] = str(java_home)
        env["PATH"] = str(java_home / "bin") + os.pathsep + env.get("PATH", "")

    godot = os.environ.get("GODOT_BIN") or shutil.which("godot")
    java = shutil.which("java", path=env.get("PATH"))
    jarsigner = shutil.which("jarsigner", path=env.get("PATH"))
    if not godot:
        print("Godot 4.7.2 was not found; set GODOT_BIN to the executable path.", file=sys.stderr)
        return 2
    if not java or not jarsigner:
        print("Java and jarsigner are required to verify the exported bundle.", file=sys.stderr)
        return 2

    version_slug = re.sub(r"[^0-9A-Za-z.-]+", "-", preset["version_name"])
    default_output = PROJECT_ROOT / "build" / f"emberfall-{version_slug}-play-beta.aab"
    output = Path(os.environ.get("EMBERFALL_BETA_AAB", default_output)).expanduser().resolve()
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
    if result.returncode:
        return result.returncode

    verifier = PROJECT_ROOT / "scripts" / "verify_android_aab.py"
    verify_command = [
        sys.executable,
        str(verifier),
        "--bundle",
        str(output),
        "--bundletool",
        str(BUNDLETOOL),
        "--java",
        java,
        "--jarsigner",
        jarsigner,
        "--package",
        preset["package"],
        "--version-code",
        preset["version_code"],
        "--version-name",
        preset["version_name"],
        "--min-sdk",
        preset["min_sdk"],
        "--target-sdk",
        preset["target_sdk"],
    ]
    verified = subprocess.run(verify_command, env=env, check=False)
    if verified.returncode:
        return verified.returncode
    print(f"Created and verified signed Play Beta bundle: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
