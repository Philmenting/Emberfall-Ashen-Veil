"""Build an isolated, debuggable x86_64 offline QA APK without changing the release project."""
import argparse
import configparser
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene", default="res://Main.tscn", help="A QA fixture or the actual shipping main scene")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--architecture", choices=["x86_64","arm64-v8a"], default="x86_64", help="ARM64 for real Android phones; x86_64 for CI emulators")
    args = parser.parse_args()
    scene = ROOT / args.scene.removeprefix("res://")
    if not args.scene.startswith("res://") or not scene.resolve().is_relative_to(ROOT) or not scene.is_file():
        parser.error("QA scene must be a scene inside this repository")
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    godot = os.environ.get("GODOT_BIN") or shutil.which("godot")
    if not godot:
        parser.error("Set GODOT_BIN to Godot 4.7.2")
    with tempfile.TemporaryDirectory(prefix="emberfall-offline-qa-") as temporary:
        stage = Path(temporary) / "project"
        shutil.copytree(ROOT, stage, ignore=shutil.ignore_patterns(".git", ".godot", "android", "build", "docs", "server", "__pycache__"))
        project = stage / "project.godot"
        project.write_text(project.read_text().replace('run/main_scene="res://Main.tscn"', f'run/main_scene="{args.scene}"'))
        config = configparser.ConfigParser(interpolation=None)
        config.read(stage / "export_presets.cfg")
        config["preset.0"] = dict(config["preset.3"])
        config["preset.0.options"] = dict(config["preset.3.options"])
        for section in list(config.sections()):
            if section not in ("preset.0", "preset.0.options"): config.remove_section(section)
        config["preset.0"]["name"] = '"Android Offline QA"'
        # Exercise the same runtime art/resources as the shipping preset while
        # retaining QA scenes. Historical painted actor resources stay excluded.
        excludes = config["preset.0"]["exclude_filter"].strip('"').split(",")
        config["preset.0"]["exclude_filter"] = '"' + ",".join(value for value in excludes if value != "tests/*") + '"'
        options = config["preset.0.options"]
        options["architectures/arm64-v8a"] = "true" if args.architecture=="arm64-v8a" else "false"
        options["architectures/x86_64"] = "true" if args.architecture=="x86_64" else "false"
        options["package/unique_name"] = '"com.philmenting.emberfallashenveil.betaqa"'
        options["package/name"] = '"Emberfall Beta QA"'
        with (stage / "export_presets.cfg").open("w") as stream: config.write(stream, space_around_delimiters=False)
        for arguments in [["--editor", "--import", "--quit"], ["--export-debug", "Android Offline QA", str(output)]]:
            result = subprocess.run([godot, "--headless", "--path", str(stage), *arguments], check=False, timeout=300)
            if result.returncode: return result.returncode
        if not output.is_file(): raise RuntimeError("QA export returned without producing an APK")
    print(f"Offline QA artifact only: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
