"""Regression tests for native page-size checks and release identity/listing gates."""
import contextlib
import configparser
import io
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from android_native_check import verify_elf, verify_bundle_native
from check_play_release import validate
from export_android_qa import QaPackage, build_packages, prepare_stage, write_preset


def elf(alignment=16384, address=16384):
    data = bytearray(256)
    data[:6] = b"\x7fELF\x02\x01"
    struct.pack_into("<Q", data, 32, 64)
    struct.pack_into("<HH", data, 54, 56, 1)
    struct.pack_into("<I", data, 64, 1)
    struct.pack_into("<QQ", data, 72, 0, address)
    struct.pack_into("<Q", data, 112, alignment)
    return bytes(data)


class ReleaseChecks(unittest.TestCase):
    def test_16kb_segment_passes(self):
        self.assertEqual(verify_elf(elf(), "good.so"), 1)

    def test_4kb_and_misaligned_segments_fail(self):
        for data in [elf(4096, 4096), elf(address=4096), b"corrupt"]:
            with self.assertRaises(ValueError): verify_elf(data, "bad.so")

    def test_missing_arm64_library_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            bundle = Path(directory) / "app.aab"
            with zipfile.ZipFile(bundle, "w") as archive: archive.writestr("base/lib/x86_64/engine.so", elf())
            with self.assertRaises(ValueError): verify_bundle_native(bundle)
            with zipfile.ZipFile(bundle, "a") as archive: archive.writestr("base/lib/arm64-v8a/engine.so", elf())
            self.assertEqual(verify_bundle_native(bundle), 1)

    def test_current_release_identity_and_store_limits(self):
        self.assertEqual(validate(ROOT), [])

    def test_missing_publication_details_never_report_ready(self):
        with tempfile.TemporaryDirectory() as directory:
            stage = Path(directory)
            for name in ["export_presets.cfg", "scripts/release_info.gd", "docs/play/store.json", "docs/play/assets/feature-graphic.png", "docs/play/assets/icon-512.png"]:
                target = stage / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes((ROOT / name).read_bytes())
            store = json.loads((stage / "docs/play/store.json").read_text())
            for field in ["developer_name", "support_email", "privacy_policy_url", "play_app_created", "device_test_report"]: store[field] = None
            (stage / "docs/play/store.json").write_text(json.dumps(store))
            self.assertEqual(len(validate(stage, strict=True)), 5)
            config = (stage / "export_presets.cfg").read_text().replace("permissions/internet=false", "permissions/internet=true")
            (stage / "export_presets.cfg").write_text(config)
            self.assertTrue(any("permissions/internet" in problem for problem in validate(stage)))


class QaExportChecks(unittest.TestCase):
    def make_project(self, root: Path, editor_settings="") -> None:
        root.mkdir()
        (root / "project.godot").write_text(
            'config_version=5\n[application]\nrun/main_scene="res://Main.tscn"\n' + editor_settings)
        (root / "export_presets.cfg").write_bytes((ROOT / "export_presets.cfg").read_bytes())
        for name in ("Main.tscn", "tests/android_beta_flow.tscn", "tests/android_art_flow.tscn",
                     "tests/android_success_flow.tscn", "tests/android_device_probe.tscn",
                     "assets/fonts/Lora.ttf", "assets/fonts/Cinzel.ttf", "assets/models/nyra052/arcanist.glb",
                     "assets/models/nyra052/staff-grip053.glb", "assets/models/nyra052/death-grounding.json",
                     "assets/models/nyra052/staff-grip053.json", "assets/models/nyra052/BASE-LICENSE.txt",
                     "docs/history.png", "art-source/nyra052/source.blend", ".godot/imported/stale.scn"):
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(name.encode())

    def test_serial_import_isolated_from_shipping_settings_and_assets(self):
        with tempfile.TemporaryDirectory() as directory:
            root, stage = Path(directory) / "source", Path(directory) / "qa"
            self.make_project(root)
            original = {p.relative_to(root): p.read_bytes() for p in root.rglob("*") if p.is_file()}
            config = prepare_stage(root, stage, "res://tests/android_beta_flow.tscn")
            write_preset(stage, config, "x86_64")
            staged = (stage / "project.godot").read_text()
            self.assertIn("[editor]\n\nimport/use_multiple_threads=false", staged)
            self.assertIn('run/main_scene="res://tests/android_beta_flow.tscn"', staged)
            for name in original:
                if name.parts[0] in ("docs", "art-source", ".godot"):
                    self.assertFalse((stage / name).exists())
                elif name.name not in ("project.godot", "export_presets.cfg"):
                    self.assertEqual((stage / name).read_bytes(), original[name])
                self.assertEqual((root / name).read_bytes(), original[name])

    def test_existing_editor_section_keeps_other_settings(self):
        with tempfile.TemporaryDirectory() as directory:
            root, stage = Path(directory) / "source", Path(directory) / "qa"
            self.make_project(root, "\n[editor]\nimport/use_multiple_threads=true\nversion_control/autoload_on_startup=false\n\n[rendering]\nrenderer/rendering_method=\"gl_compatibility\"\n")
            prepare_stage(root, stage, "res://Main.tscn")
            text = (stage / "project.godot").read_text()
            self.assertEqual(text.count("[editor]"), 1)
            self.assertEqual(text.count("import/use_multiple_threads="), 1)
            self.assertIn("import/use_multiple_threads=false", text)
            self.assertIn("version_control/autoload_on_startup=false", text)
            self.assertIn('[rendering]\nrenderer/rendering_method="gl_compatibility"', text)

    def test_qa_preserves_runtime_json_licences_and_offline_filter(self):
        with tempfile.TemporaryDirectory() as directory:
            root, stage = Path(directory) / "source", Path(directory) / "qa"
            self.make_project(root)
            config = prepare_stage(root, stage, "res://Main.tscn")
            for required in ("death-grounding.json", "staff-grip053.json", "*LICENSE.txt"):
                self.assertIn("assets/models/nyra052/" + required, config["preset.0"]["include_filter"])
            self.assertNotIn("tests/*", config["preset.0"]["exclude_filter"])
            self.assertIn("assets/characters/*", config["preset.0"]["exclude_filter"])
            self.assertEqual(config["preset.0.options"]["permissions/internet"], "false")
            original = configparser.ConfigParser(interpolation=None)
            original.read(root / "export_presets.cfg")
            for option in ("version/code", "version/name", "screen/immersive_mode", "permissions/vibrate"):
                self.assertEqual(config["preset.0.options"][option], original["preset.3.options"][option])
            self.assertEqual(set(config.sections()), {"preset.0", "preset.0.options"})

    def test_all_four_packages_share_one_import_and_use_their_actual_scene_architecture(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "source"
            self.make_project(root)
            requests = [("android_beta_flow", "x86_64"), ("android_success_flow", "x86_64"),
                        ("android_art_flow", "x86_64"), ("android_device_probe", "arm64-v8a")]
            packages = [QaPackage(f"res://tests/{name}.tscn", Path(directory) / f"{name}.apk", arch) for name, arch in requests]
            observed = []

            def capture(command, **kwargs):
                stage = Path(command[command.index("--path") + 1])
                if "--export-debug" in command:
                    text = (stage / "project.godot").read_text()
                    config = configparser.ConfigParser(interpolation=None)
                    config.read(stage / "export_presets.cfg")
                    active = [arch for arch in ("x86_64", "arm64-v8a") if config["preset.0.options"][f"architectures/{arch}"] == "true"]
                    observed.append((text.split('run/main_scene="')[1].split('"')[0], active))
                    Path(command[-1]).write_bytes(b"export fixture")
                return subprocess.CompletedProcess(command, 0, "")

            with patch("export_android_qa.subprocess.run", side_effect=capture) as engine, contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(build_packages(root, "godot", packages), 0)
            self.assertEqual(len(engine.call_args_list), 5)
            self.assertEqual(sum("--import" in call.args[0] for call in engine.call_args_list), 1)
            self.assertEqual(observed, [(package.scene, [package.architecture]) for package in packages])
            self.assertIn('run/main_scene="res://Main.tscn"', (root / "project.godot").read_text())

    def test_crash_and_zero_exit_import_errors_stop_before_export_without_retry(self):
        for status, log in ((-4, "native signal 4"), (0, "ERROR: Parameter mem is null.\n"),
                            (0, "SCRIPT ERROR: Parse Error: missing resource\n")):
            with self.subTest(status=status, log=log), tempfile.TemporaryDirectory() as directory:
                root = Path(directory) / "source"
                self.make_project(root)
                package = QaPackage("res://Main.tscn", Path(directory) / "qa.apk", "x86_64")
                with patch("export_android_qa.subprocess.run", return_value=subprocess.CompletedProcess([], status, log)) as engine, contextlib.redirect_stdout(io.StringIO()):
                    self.assertNotEqual(build_packages(root, "godot", [package]), 0)
                self.assertEqual(engine.call_count, 1)
                self.assertFalse(package.output.exists())

    def test_export_error_stops_remaining_packages(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "source"
            self.make_project(root)
            packages = [QaPackage("res://Main.tscn", Path(directory) / f"qa-{i}.apk", "x86_64") for i in range(2)]
            with patch("export_android_qa.subprocess.run", side_effect=[
                    subprocess.CompletedProcess([], 0, ""), subprocess.CompletedProcess([], 0, "ERROR: missing runtime JSON\n")]) as engine, contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(build_packages(root, "godot", packages), 1)
            self.assertEqual(engine.call_count, 2)
            self.assertFalse(packages[1].output.exists())

    def test_export_success_without_artifact_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "source"
            self.make_project(root)
            package = QaPackage("res://Main.tscn", Path(directory) / "qa.apk", "x86_64")
            with patch("export_android_qa.subprocess.run", return_value=subprocess.CompletedProcess([], 0, "")), contextlib.redirect_stdout(io.StringIO()):
                with self.assertRaisesRegex(RuntimeError, "without producing an APK"):
                    build_packages(root, "godot", [package])


if __name__ == "__main__": unittest.main()
