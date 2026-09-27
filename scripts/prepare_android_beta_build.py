"""Update Godot's generated Android Gradle template to the API 36-supported AGP."""

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG = PROJECT_ROOT / "android" / "build" / "config.gradle"
OLD_PLUGIN = "androidGradlePlugin: '8.6.1'"
PLAY_PLUGIN = "androidGradlePlugin: '8.10.1'"


def main() -> None:
    if not CONFIG.is_file():
        raise SystemExit(
            "Godot Android Gradle template is missing. Install it as part of an Android export first."
        )

    content = CONFIG.read_text(encoding="utf-8")
    if PLAY_PLUGIN in content:
        print("Godot Android template already uses Android Gradle Plugin 8.10.1.")
        return
    if content.count(OLD_PLUGIN) != 1:
        raise SystemExit(
            "Unexpected Godot Android Gradle template version; refusing an unverified replacement."
        )

    CONFIG.write_text(content.replace(OLD_PLUGIN, PLAY_PLUGIN, 1), encoding="utf-8")
    print("Updated generated template to Android Gradle Plugin 8.10.1 for API 36.")


if __name__ == "__main__":
    main()
