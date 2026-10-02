"""Update Godot's generated Android template for API 36 and CI dependency access."""

import argparse
from pathlib import Path
import zipfile

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG = PROJECT_ROOT / "android" / "build" / "config.gradle"
OLD_PLUGIN = "androidGradlePlugin: '8.6.1'"
PLAY_PLUGIN = "androidGradlePlugin: '8.10.1'"
# Published by the mirror operator: https://storage-download.googleapis.com/maven-central/index.html
CENTRAL_MIRROR = "https://maven-central.storage-download.googleapis.com/maven2/"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", type=Path, help="Install the official Godot 4.7.2 android_source.zip without launching an editor loop.")
    parser.add_argument("--central-mirror", choices=[CENTRAL_MIRROR], help="Use the documented Google-hosted Maven Central mirror in CI.")
    args = parser.parse_args()
    if args.template:
        if CONFIG.exists():
            raise SystemExit("Android template already exists; refusing to overwrite local build configuration.")
        with zipfile.ZipFile(args.template) as archive:
            for entry in archive.infolist():
                if Path(entry.filename).is_absolute() or ".." in Path(entry.filename).parts:
                    raise SystemExit("Unexpected path in Android template.")
            archive.extractall(CONFIG.parent)
        CONFIG.parent.joinpath(".gdignore").touch()
        CONFIG.parent.parent.joinpath(".build_version").write_text("4.7.2.stable\n", encoding="ascii")
        CONFIG.parent.joinpath("gradlew").chmod(0o755)
        print("Installed Godot 4.7.2 Android source template.")
    if not CONFIG.is_file():
        raise SystemExit("Godot Android Gradle template is missing. Install it as part of an Android export first.")
    content = CONFIG.read_text(encoding="utf-8")
    if PLAY_PLUGIN not in content:
        if content.count(OLD_PLUGIN) != 1:
            raise SystemExit("Unexpected Godot Android Gradle template version; refusing an unverified replacement.")
        CONFIG.write_text(content.replace(OLD_PLUGIN, PLAY_PLUGIN, 1), encoding="utf-8")
    print("Godot Android template uses Android Gradle Plugin 8.10.1 for API 36.")
    if args.central_mirror:
        replacement = 'maven { url "' + args.central_mirror + '" }'
        for name in ("settings.gradle", "build.gradle"):
            path = CONFIG.parent / name
            original = path.read_text(encoding="utf-8")
            if replacement in original:
                continue
            if original.count("mavenCentral()") != 1:
                raise SystemExit(f"Unexpected Maven repository configuration in {name}.")
            path.write_text(original.replace("mavenCentral()", replacement, 1), encoding="utf-8")
        print("CI uses the Google-hosted Maven Central mirror; Google's Android repository is unchanged.")


if __name__ == "__main__":
    main()
