"""Regression tests for native page-size checks and release identity/listing gates."""
import contextlib
import copy
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
from android_beta_smoke import main as run_android_smoke, validate_art_report


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


class FakeAdb:
    """Scripted device observations; no APK, emulator or real adb is executed."""
    def __init__(self, scenario):
        self.scenario = scenario
        self.clock = 0.0
        self.launch = 0
        self.poll = 0
        self.calls = []

    def sleep(self, seconds):
        self.clock += seconds

    def run(self, command, **kwargs):
        self.calls.append(command[1:])
        args = command[1:]
        result, code, error = "", 0, ""
        if self.scenario == "missing_device":
            return subprocess.CompletedProcess(command, 1, "", "error: no devices/emulators found")
        if args[:3] == ["shell", "am", "start"]:
            self.launch += 1
            self.poll = 0
            result = "Error type 3\nError: Activity class does not exist" if self.scenario == "start_error" else "Starting: Intent"
        elif args[:2] == ["shell", "pidof"]:
            self.poll += 1
            missing = self.scenario == "not_started" or (self.scenario == "success" and self.launch == 1 and self.poll == 1) or (self.scenario == "process_lost" and self.poll > 1)
            if missing:
                code = 1  # Normal Android pidof absence: no stderr.
            else:
                result = "42" if self.launch > 1 or (self.scenario == "pid_changed" and self.poll > 1) else "41"
        elif args == ["logcat", "-d", "-s", "godot"]:
            if self.scenario == "not_started" or (self.scenario == "success" and self.launch == 1 and self.poll == 1):
                result = ""
            elif self.launch > 1:
                result = "ANDROID_BETA_PASS restart does not repeat"
            elif self.scenario == "success":
                result = "ANDROID_BETA_READY cooperative=true\nANDROID_BETA_PASS exact AFK ledger"
            elif self.scenario == "error_and_marker":
                result = "ERROR: runtime broke\nANDROID_BETA_PASS exact AFK ledger"
            elif self.scenario in ("process_lost", "pid_changed") and self.poll > 1:
                result = "ANDROID_BETA_READY cooperative=true\nANDROID_BETA_PASS exact AFK ledger"
            else:
                result = "ANDROID_BETA_READY cooperative=true"
        elif args == ["logcat", "-b", "all", "-d", "-v", "threadtime"]:
            result = "AndroidRuntime FATAL EXCEPTION\nActivityManager: Process exit; native DEBUG/ANR details"
        elif args[:4] == ["shell", "dumpsys", "activity", "exit-info"]:
            result = "ApplicationExitInfo reason=3 status=9 pid=41"
        elif args[:2] == ["exec-out", "screencap"]:
            result = b"\x89PNG\r\n\x1a\nfixture"
        return subprocess.CompletedProcess(command, code, result, error)


class AndroidRuntimeChecks(unittest.TestCase):
    def run_fixture(self, scenario, seconds=6):
        device = FakeAdb("process_lost" if scenario == "evidence_write_error" else scenario)
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            apk = folder / "fixture.apk"
            apk.write_bytes(b"QA APK fixture")
            output = folder / "evidence"
            argv = ["android_beta_smoke.py", "--apk", str(apk), "--output", str(output), "--timeout-seconds", str(seconds)]
            console = io.StringIO()
            original_write = Path.write_text

            def write_evidence(path, data, *args, **kwargs):
                if scenario == "evidence_write_error" and (path.name.startswith("failure-") or (path.name == "runtime-status.json" and '"status": "failed"' in data)):
                    raise OSError("No space left on evidence filesystem")
                return original_write(path, data, *args, **kwargs)

            with patch("sys.argv", argv), patch("android_beta_smoke.subprocess.run", side_effect=device.run), \
                    patch("android_beta_smoke.time.monotonic", side_effect=lambda: device.clock), \
                    patch("android_beta_smoke.time.sleep", side_effect=device.sleep), \
                    patch.dict("os.environ", {"EMBERFALL_SOURCE_COMMIT": "source-head", "GITHUB_SHA": "merge-head"}), \
                    patch.object(Path, "write_text", new=write_evidence), contextlib.redirect_stdout(console):
                status = run_android_smoke()
            device.console = console.getvalue()
            report = json.loads((output / "runtime-status.json").read_text())
            files = {path.name: path.read_bytes() for path in output.iterdir()}
        return status, report, files, device

    def test_live_process_start_grace_and_both_markers_pass(self):
        status, report, files, device = self.run_fixture("success")
        self.assertEqual(status, 0)
        self.assertEqual(report["status"], "passed")
        self.assertEqual(len(report["launches"]), 2)
        self.assertEqual(report["launches"][0]["pid_samples"][0]["pids"], [])
        self.assertTrue(all(launch["status"] == "marker_observed" for launch in report["launches"]))
        self.assertEqual(report["provenance"]["source_commit"], "source-head")
        self.assertEqual(report["provenance"]["github_sha"], "merge-head")
        self.assertEqual(len(report["apk"]["sha256"]), 64)
        self.assertIn("first-launch-all.log", files)
        self.assertIn(["logcat", "-b", "all", "-c"], device.calls)

    def test_observed_process_loss_fails_even_if_a_marker_was_buffered(self):
        status, report, files, device = self.run_fixture("process_lost", 900)
        self.assertEqual(status, 1)
        self.assertEqual(report["failure"]["kind"], "process_lost")
        self.assertLess(device.clock, 900)
        self.assertEqual(device.launch, 1)
        self.assertIn(b"ApplicationExitInfo reason=3", files["failure-exit-info.txt"])
        self.assertIn(b"FATAL EXCEPTION", files["failure-logcat-all.log"])

    def test_activity_error_with_zero_adb_exit_fails_before_waiting(self):
        status, report, files, device = self.run_fixture("start_error")
        self.assertEqual(status, 1)
        self.assertEqual(report["failure"]["kind"], "activity_start_failed")
        self.assertEqual(device.clock, 0)
        self.assertIn(b"Activity class does not exist", files["launch-1-start.txt"])

    def test_live_process_without_marker_still_times_out_at_original_deadline(self):
        status, report, files, device = self.run_fixture("timeout", 6)
        self.assertEqual(status, 1)
        self.assertEqual(report["failure"]["kind"], "marker_timeout")
        self.assertEqual(device.clock, 6)
        self.assertEqual(report["launches"][0]["marker_deadline_seconds"], 6)
        self.assertTrue(report["launches"][0]["process_observed"])

    def test_pidof_absence_during_grace_is_not_a_transport_error(self):
        status, report, files, device = self.run_fixture("not_started", 45)
        self.assertEqual(status, 1)
        self.assertEqual(report["failure"]["kind"], "process_not_started")
        self.assertEqual(device.clock, 30)
        self.assertFalse(report["launches"][0]["process_observed"])

    def test_runtime_error_precedes_marker_success(self):
        status, report, files, device = self.run_fixture("error_and_marker")
        self.assertEqual(status, 1)
        self.assertEqual(report["failure"]["kind"], "godot_runtime_error")
        self.assertEqual(device.launch, 1)

    def test_unrequested_process_restart_does_not_pass_from_old_marker(self):
        status, report, files, device = self.run_fixture("pid_changed")
        self.assertEqual(status, 1)
        self.assertEqual(report["failure"]["kind"], "unexpected_process_restart")
        self.assertIn("[41] -> [42]", report["failure"]["message"])

    def test_missing_device_preserves_original_failure_and_other_diagnostics(self):
        status, report, files, device = self.run_fixture("missing_device")
        self.assertEqual(status, 1)
        self.assertEqual(report["failure"]["kind"], "adb_command_failed")
        self.assertIn("install", report["failure"]["message"])
        self.assertIn("no devices/emulators found", report["failure"]["message"])
        self.assertEqual(len(report["diagnostic_errors"]), 5)
        for name in ("failure-logcat-all.log", "failure-exit-info.txt", "failure-activity.txt", "failure-meminfo.txt"):
            self.assertIn(b"Diagnostic unavailable", files[name])

    def test_evidence_write_errors_do_not_replace_original_process_failure(self):
        status, report, files, device = self.run_fixture("evidence_write_error", 900)
        self.assertEqual(status, 1)
        self.assertIn("ANDROID BETA RUNTIME FAILED: QA process disappeared", device.console)
        self.assertIn("ANDROID_RUNTIME_DIAGNOSTIC_UNAVAILABLE: No space left", device.console)
        self.assertLess(device.console.index("QA process disappeared"), device.console.index("No space left"))
        self.assertEqual(device.launch, 1)


class AndroidNativeArtReportChecks(unittest.TestCase):
    """Observer gates must reject old proxy receipts and incomplete native evidence."""
    def report(self):
        actions = ["Sword_Regular_C", "Spell_Simple_Shoot", "Spell_Simple_Enter", "Sword_Regular_C"]
        measurements = [{"region": region, "quality": quality, "frames": 30,
                         "median_frame_ms": 20., "p95_frame_ms": 25., "median_draw_calls": 30.}
                        for region in range(4) for quality in ["balanced", "battery"]]
        motion = []
        for region, action in enumerate(actions):
            required = ["Walk_Loop", "Hit_Chest", "Death01", action]
            bound = required + ["Sword_Idle"]
            motion.append({"region": region, "passed": True, "frames": 20,
                           "simulation_step_seconds": .05, "simulation_advanced_seconds": 1.,
                           "bone_changes": 10, "bone_name": "Head", "unique_rendered_frames": 4,
                           "skeleton_bones": 65, "native_clips": len(bound), "bound_native_clips": bound,
                           "required_native_clips": required, "visible_skinned_meshes": 12,
                           "visible_rigid_props": 2, "visible_triangles": 31058,
                           "weighted_figure_depth": .8, "captures": [0, 5, 11, 17],
                           "physical_device_performance": False})
        return {"schema": 2, "measurements": measurements, "motion": motion}

    def test_complete_bound_native_scene_receipt_passes(self):
        report = self.report()
        self.assertEqual(validate_art_report(report), report["motion"])

    def test_old_hidden_proxy_receipt_cannot_pass(self):
        report = self.report()
        report["schema"] = 1
        for row in report["motion"]:
            row.update(skeleton_bones=29, native_clips=9, source_depth=.8)
        with self.assertRaises(RuntimeError):
            validate_art_report(report)

    def test_missing_native_clip_binding_anatomy_or_visible_geometry_fails(self):
        mutations = [
            {"skeleton_bones": 29}, {"bone_name": "Bone3"},
            {"bound_native_clips": ["Walk_Loop", "Hit_Chest", "Death01", "Sword_Idle"], "native_clips": 4},
            {"required_native_clips": ["Walk_Loop", "Hit_Chest", "Death01", "Spell_Simple_Shoot"]},
            {"visible_skinned_meshes": 0}, {"visible_rigid_props": 0}, {"visible_triangles": 40001},
            {"weighted_figure_depth": .30}, {"weighted_figure_depth": float("nan")},
            {"physical_device_performance": True},
        ]
        for mutation in mutations:
            with self.subTest(mutation=mutation):
                report = self.report()
                report["motion"][0].update(mutation)
                with self.assertRaises(RuntimeError):
                    validate_art_report(report)

    def test_original_motion_sampling_and_progress_thresholds_are_required(self):
        for mutation in [{"bone_changes": 5}, {"unique_rendered_frames": 3}, {"frames": 19},
                         {"simulation_step_seconds": .1}, {"simulation_advanced_seconds": .8},
                         {"captures": [0, 5, 11]}, {"passed": False}]:
            with self.subTest(mutation=mutation):
                report = self.report()
                report["motion"][0].update(mutation)
                with self.assertRaises(RuntimeError):
                    validate_art_report(report)

    def test_duplicate_or_missing_scenarios_are_rejected(self):
        for key in ["measurements", "motion"]:
            report = self.report()
            report[key].append(copy.deepcopy(report[key][0]))
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                validate_art_report(report)


if __name__ == "__main__": unittest.main()
