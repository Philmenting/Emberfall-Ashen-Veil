"""Build isolated, debuggable offline QA APKs without changing the release project."""
import argparse
import configparser
from dataclasses import dataclass
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ARCHITECTURES = ("x86_64", "arm64-v8a")


@dataclass(frozen=True)
class QaPackage:
    scene: str
    output: Path
    architecture: str


def set_main_scene(project: Path, scene: str) -> None:
    text, count = re.subn(r'^run/main_scene=.*$', f'run/main_scene="{scene}"', project.read_text(), flags=re.MULTILINE)
    if count != 1:
        raise ValueError("The staging project must have exactly one run/main_scene")
    project.write_text(text)


def prepare_stage(root: Path, stage: Path, scene: str) -> configparser.ConfigParser:
    # Keep runtime assets, autoloads and QA fixtures. These directories contain
    # editor caches, development sources or historical evidence, not game data.
    shutil.copytree(root, stage, ignore=shutil.ignore_patterns(
        ".git", ".godot", "android", "build", "docs", "server", "art-source", "tools", ".github", ".impeccable", "__pycache__"))
    project = stage / "project.godot"
    set_main_scene(project, scene)
    # The CI native abort happened during a second cold font import, in a worker
    # allocation/COW path. Serialise the actual importer, rather than retrying a
    # crashed process or omitting the fonts. This is an editor-only staging
    # setting; the shipping project's runtime threading stays unchanged.
    text = project.read_text()
    section = re.search(r'^\[editor\]\s*\n(.*?)(?=^\[|\Z)', text, flags=re.MULTILINE | re.DOTALL)
    setting = "import/use_multiple_threads=false\n"
    if section:
        body = re.sub(r'^import/use_multiple_threads=.*\n?', "", section.group(1), flags=re.MULTILINE)
        text = text[:section.start(1)] + setting + body + text[section.end(1):]
    else:
        text += "\n[editor]\n\n" + setting
    project.write_text(text)
    config = configparser.ConfigParser(interpolation=None)
    config.read(stage / "export_presets.cfg")
    config["preset.0"] = dict(config["preset.3"])
    config["preset.0.options"] = dict(config["preset.3.options"])
    for name in list(config.sections()):
        if name not in ("preset.0", "preset.0.options"):
            config.remove_section(name)
    config["preset.0"]["name"] = '"Android Offline QA"'
    # Inherit the closed-beta include_filter verbatim, including FileAccess JSON
    # and source licences. Retain QA scenes but keep historical actor exclusions.
    excludes = config["preset.0"]["exclude_filter"].strip('"').split(",")
    config["preset.0"]["exclude_filter"] = '"' + ",".join(value for value in excludes if value != "tests/*") + '"'
    options = config["preset.0.options"]
    options["package/unique_name"] = '"com.philmenting.emberfallashenveil.betaqa"'
    options["package/name"] = '"Emberfall Beta QA"'
    if options.get("permissions/internet") != "false":
        raise ValueError("The closed-beta QA preset must remain offline")
    return config


def write_preset(stage: Path, config: configparser.ConfigParser, architecture: str) -> None:
    options = config["preset.0.options"]
    for candidate in ARCHITECTURES:
        options[f"architectures/{candidate}"] = "true" if candidate == architecture else "false"
    with (stage / "export_presets.cfg").open("w") as stream:
        config.write(stream, space_around_delimiters=False)


def run_godot(godot: str, stage: Path, arguments: list[str]) -> int:
    result = subprocess.run([godot, "--headless", "--path", str(stage), *arguments], check=False, timeout=300,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    print(result.stdout, end="", flush=True)
    # Godot can report script/import errors while still exiting zero. A crashed
    # import fails this build immediately; no export, retry or emulator follows.
    if result.returncode or "SCRIPT ERROR:" in result.stdout or re.search(r"^ERROR:", result.stdout, re.MULTILINE):
        return result.returncode or 1
    return 0


def build_packages(root: Path, godot: str, packages: list[QaPackage]) -> int:
    with tempfile.TemporaryDirectory(prefix="emberfall-offline-qa-") as temporary:
        stage = Path(temporary) / "project"
        config = prepare_stage(root, stage, packages[0].scene)
        write_preset(stage, config, packages[0].architecture)
        print(f"Importing the isolated QA project once for {len(packages)} package(s), with serial asset imports.", flush=True)
        status = run_godot(godot, stage, ["--editor", "--import", "--quit"])
        if status:
            return status
        for package in packages:
            set_main_scene(stage / "project.godot", package.scene)
            write_preset(stage, config, package.architecture)
            print(f"Exporting {package.scene} ({package.architecture}) to {package.output}", flush=True)
            status = run_godot(godot, stage, ["--export-debug", "Android Offline QA", str(package.output)])
            if status:
                return status
            if not package.output.is_file():
                raise RuntimeError("QA export returned without producing an APK")
            print(f"Offline QA artifact only: {package.output}", flush=True)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene", help="A QA fixture or the actual shipping main scene (single package)")
    parser.add_argument("--output", type=Path, help="Output APK (single package)")
    parser.add_argument("--architecture", choices=ARCHITECTURES, help="ARM64 for phones; x86_64 for CI emulators")
    parser.add_argument("--package", nargs=3, action="append", metavar=("SCENE", "OUTPUT", "ARCHITECTURE"),
                        help="Repeat to export several packages from one isolated import")
    args = parser.parse_args()
    if args.package:
        if args.scene or args.output or args.architecture:
            parser.error("Use --package or the single-package options, not both")
        packages = [QaPackage(scene, Path(output).resolve(), architecture) for scene, output, architecture in args.package]
    else:
        if not args.output:
            parser.error("Provide --output or at least one --package")
        packages = [QaPackage(args.scene or "res://Main.tscn", args.output.resolve(), args.architecture or "x86_64")]
    for package in packages:
        scene = ROOT / package.scene.removeprefix("res://")
        if not package.scene.startswith("res://") or '"' in package.scene or not scene.resolve().is_relative_to(ROOT) or not scene.is_file():
            parser.error("QA scene must be a scene inside this repository")
        if package.architecture not in ARCHITECTURES:
            parser.error(f"Unsupported QA architecture: {package.architecture}")
        package.output.parent.mkdir(parents=True, exist_ok=True)
    if len({package.output for package in packages}) != len(packages):
        parser.error("Each QA package must have a distinct output")
    godot = os.environ.get("GODOT_BIN") or shutil.which("godot")
    if not godot:
        parser.error("Set GODOT_BIN to Godot 4.7.2")
    return build_packages(ROOT, godot, packages)


if __name__ == "__main__":
    raise SystemExit(main())
