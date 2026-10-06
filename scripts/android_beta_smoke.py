"""Run the isolated Android AFK/restart fixture; this never clears the shipping app's data."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import time

PACKAGE = "com.philmenting.emberfallashenveil.betaqa"
START_GRACE_SECONDS = 30


class QaFailure(RuntimeError):
    def __init__(self, kind, message):
        super().__init__(message)
        self.kind = kind


class RuntimeMonitor:
    """Observe the dedicated QA process; diagnostic failures never replace its failure."""
    def __init__(self, args):
        self.args = args
        self.phase = None
        self.phase_started = None
        self.last_pids = set()
        digest = None
        if args.apk.is_file():
            with args.apk.open("rb") as stream:
                digest = hashlib.file_digest(stream, "sha256").hexdigest()
        self.report = {
            "schema": 1, "status": "running", "package": PACKAGE,
            "fixture": "art" if args.art_only else "success" if args.success_only else "afk",
            "started_at": datetime.now(timezone.utc).isoformat(),
            "apk": {"path": str(args.apk.resolve()), "sha256": digest},
            "provenance": {
                "source_commit": os.environ.get("EMBERFALL_SOURCE_COMMIT"),
                "github_sha": os.environ.get("GITHUB_SHA"),
                "github_head_ref": os.environ.get("GITHUB_HEAD_REF"),
                "github_run_id": os.environ.get("GITHUB_RUN_ID"),
                "github_run_attempt": os.environ.get("GITHUB_RUN_ATTEMPT"),
                "observer_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            },
            "launches": [], "diagnostic_errors": [],
        }
        self.save()

    def save(self):
        (self.args.output / "runtime-status.json").write_text(json.dumps(self.report, indent=2))

    def adb(self, *arguments, timeout=60):
        result = subprocess.run([self.args.adb, *arguments], capture_output=True, text=True, timeout=timeout)
        if result.returncode:
            raise QaFailure("adb_command_failed", "adb " + " ".join(arguments[:5]) + ": " + (result.stdout + result.stderr)[-3000:])
        return result.stdout

    def diagnostic(self, filename, *arguments):
        try:
            text = self.adb(*arguments, timeout=30)
        except (RuntimeError, subprocess.TimeoutExpired, OSError) as error:
            text = "Diagnostic unavailable: " + str(error)
            self.report["diagnostic_errors"].append({"file": filename, "message": str(error)})
        (self.args.output / filename).write_text(text)

    def launch(self):
        self.last_pids = set()
        self.phase_started = time.monotonic()
        self.phase = {"number": len(self.report["launches"]) + 1, "status": "starting", "process_observed": False,
                      "started_at": datetime.now(timezone.utc).isoformat(), "pid_samples": []}
        self.report["launches"].append(self.phase)
        self.save()
        text = self.adb("shell", "am", "start", "-n", PACKAGE + "/com.godot.game.GodotAppLauncher")
        (self.args.output / f"launch-{self.phase['number']}-start.txt").write_text(text)
        # ActivityManager sometimes reports an intent/Activity error with exit 0.
        if re.search(r"^\s*(?:Error(?:\s+type\s+\d+)?\s*:|Exception|SecurityException)", text, re.MULTILINE | re.IGNORECASE):
            raise QaFailure("activity_start_failed", text[-3000:])

    def process_ids(self):
        result = subprocess.run([self.args.adb, "shell", "pidof", PACKAGE], capture_output=True, text=True, timeout=30)
        # Android's pidof uses status 1 and empty stdout/stderr for no process.
        # A disconnected device also returns 1, but has an explanatory stderr.
        if result.returncode == 1 and not result.stdout.strip() and not result.stderr.strip():
            return set()
        if result.returncode:
            raise QaFailure("adb_command_failed", "adb shell pidof: " + (result.stdout + result.stderr)[-3000:])
        values = result.stdout.split()
        if not all(value.isdecimal() for value in values):
            raise QaFailure("invalid_pid_response", "Unexpected pidof response: " + result.stdout[:300])
        return {int(value) for value in values}

    def await_marker(self, marker, filename):
        timeout = self.args.timeout_seconds or (900 if self.args.art_only else 300)
        deadline = time.monotonic() + timeout
        self.phase.update({"marker": marker, "log_file": filename, "all_log_file": Path(filename).stem + "-all.log",
                           "marker_deadline_seconds": timeout, "start_grace_seconds": START_GRACE_SECONDS})
        while time.monotonic() < deadline:
            pids = self.process_ids()
            elapsed = round(time.monotonic() - self.phase_started, 3)
            self.phase["pid_samples"].append({"elapsed_seconds": elapsed, "pids": sorted(pids)})
            log = self.adb("logcat", "-d", "-s", "godot", timeout=30)
            (self.args.output / filename).write_text(log)
            # All buffers retain AndroidRuntime/native DEBUG crashes, ANR and
            # low-memory-killer events which the godot-only filter cannot see.
            self.diagnostic(self.phase["all_log_file"], "logcat", "-b", "all", "-d", "-v", "threadtime")
            self.save()
            if "ANDROID_BETA_FAIL" in log or "ANDROID_ART_FAIL" in log or "ANDROID_SUCCESS_FAIL" in log:
                raise QaFailure("fixture_failed", log[-4000:])
            if "ERROR:" in log or "shader failed to compile" in log.lower():
                raise QaFailure("godot_runtime_error", "Godot reported a runtime or shader error; see " + str(self.args.output / filename))
            if not pids and self.phase["process_observed"]:
                raise QaFailure("process_lost", f"QA process disappeared before completing {marker} (last PID(s): {sorted(self.last_pids)}); see failure-logcat-all.log and failure-exit-info.txt")
            if pids and self.last_pids and pids.isdisjoint(self.last_pids):
                raise QaFailure("unexpected_process_restart", f"QA process changed PID before completing {marker}: {sorted(self.last_pids)} -> {sorted(pids)}")
            if pids:
                self.phase["process_observed"] = True
                self.phase["status"] = "running"
                self.last_pids = pids
                if marker in log:
                    self.phase.update({"status": "marker_observed", "elapsed_seconds": elapsed})
                    self.save()
                    print(f"ANDROID_RUNTIME_MARKER verified launch={self.phase['number']} elapsed_seconds={elapsed} pids={sorted(pids)} marker={marker}", flush=True)
                    return log
            elif elapsed >= START_GRACE_SECONDS:
                raise QaFailure("process_not_started", f"QA process did not appear within {START_GRACE_SECONDS}s after Activity start; see launch-{self.phase['number']}-start.txt and failure-exit-info.txt")
            time.sleep(3)
        raise QaFailure("marker_timeout", f"Timed out waiting for {marker}; see {self.args.output / filename}")

    def finish(self, status, error=None):
        self.report.update({"status": status, "finished_at": datetime.now(timezone.utc).isoformat()})
        if error is not None:
            self.report["failure"] = {"kind": getattr(error, "kind", "qa_check_failed"), "message": str(error)}
            if self.phase:
                self.phase.update({"status": "failed", "elapsed_seconds": round(time.monotonic() - self.phase_started, 3)})
        self.save()

    def failure_diagnostics(self):
        # Each read is independent: loss of the device must not hide the first
        # fixture/process failure or prevent the other available evidence.
        for filename, arguments in [
                ("failure-logcat-all.log", ("logcat", "-b", "all", "-d", "-v", "threadtime")),
                ("failure-exit-info.txt", ("shell", "dumpsys", "activity", "exit-info", PACKAGE)),
                ("failure-activity.txt", ("shell", "dumpsys", "activity", "top")),
                ("failure-meminfo.txt", ("shell", "dumpsys", "meminfo", PACKAGE))]:
            self.diagnostic(filename, *arguments)
        try:
            capture = subprocess.run([self.args.adb, "exec-out", "screencap", "-p"], capture_output=True, timeout=30)
            if capture.returncode == 0 and capture.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
                (self.args.output / "failure-screen.png").write_bytes(capture.stdout)
            else:
                self.report["diagnostic_errors"].append({"file": "failure-screen.png", "message": "screencap unavailable"})
        except (subprocess.TimeoutExpired, OSError) as error:
            self.report["diagnostic_errors"].append({"file": "failure-screen.png", "message": str(error)})
        self.save()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("build/android-beta-runtime"))
    parser.add_argument("--skip-install", action="store_true", help="Use the already installed fixture on a slow local emulator")
    parser.add_argument("--art-only", action="store_true", help="Verify the four-region Android graphics fixture instead of AFK reconciliation")
    parser.add_argument("--success-only", action="store_true", help="Verify the first descent, relic equip and oath checkpoint")
    parser.add_argument("--timeout-seconds", type=int, help="Override the per-launch marker deadline for slow software emulators")
    args = parser.parse_args()
    if args.art_only and args.success_only: parser.error("Choose one QA fixture")
    if args.timeout_seconds is not None and not 1 <= args.timeout_seconds <= 1800:
        parser.error("--timeout-seconds must be between 1 and 1800")
    args.output.mkdir(parents=True, exist_ok=True)

    monitor = RuntimeMonitor(args)
    adb = monitor.adb
    await_marker = monitor.await_marker

    try:
        if not args.skip_install: adb("install", "--no-incremental", "-r", str(args.apk), timeout=180)
        # First-launch immersive guidance can cover the isolated fixture and
        # steal its focus. A recorded CI capture showed this system dialog.
        adb("shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed")
        adb("shell", "pm", "clear", PACKAGE)  # Dedicated fixture package only.
        adb("logcat", "-b", "all", "-c")
        monitor.launch()
        if args.success_only:
            log = await_marker("ANDROID_SUCCESS_PASS first descent, class relic and combined oath UI", "success-launch.log")
            if "ANDROID_READABILITY_PASS" not in log:
                raise RuntimeError("Android skill inspection did not verify pause and resume")
            for key in ["welcome", "first-fight", "skill-reading", "first-relic", "oaths", "oath-run", "filtered-bag", "protected-gear"]:
                capture = subprocess.run([args.adb, "exec-out", "run-as", PACKAGE, "cat", f"files/success-{key}.png"], capture_output=True, timeout=60)
                if capture.returncode or not capture.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
                    raise RuntimeError(f"Android first-session capture {key} missing or invalid")
                (args.output / f"android-success-{key}.png").write_bytes(capture.stdout)
            adb("shell", "am", "force-stop", PACKAGE)
            adb("logcat", "-b", "all", "-c")
            monitor.launch()
            await_marker("ANDROID_SUCCESS_PASS restart preserves combined oaths", "success-restart.log")
            print("ANDROID SUCCESS LOOP VERIFIED: first fight, skill inspection and resume, one-time relic, gear protection, bag filters, combined oaths and cold restart")
            monitor.finish("passed")
            return 0
        if args.art_only:
            log = await_marker("ANDROID_ART_PASS all four regions rendered", "art-launch.log")
            for region in range(4):
                if f"ANDROID_ART_REGION_PASS {region}" not in log:
                    raise RuntimeError(f"Graphics fixture did not render region {region}")
                capture = subprocess.run([args.adb, "exec-out", "run-as", PACKAGE, "cat", f"files/art-region-{region}.png"], capture_output=True, timeout=60)
                if capture.returncode or not capture.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
                    raise RuntimeError(f"Android graphics capture {region} missing or invalid")
                (args.output / f"android-region-{region}.png").write_bytes(capture.stdout)
            metrics = json.loads(adb("exec-out", "run-as", PACKAGE, "cat", "files/art-performance.json"))
            expected = {(region, quality) for region in range(4) for quality in ["balanced", "battery"]}
            if metrics.get("schema") != 1 or {(row["region"], row["quality"]) for row in metrics["measurements"]} != expected:
                raise RuntimeError("Android render report is missing a quality/region scenario")
            for row in metrics["measurements"]:
                if row["frames"] != 30 or not all(math.isfinite(row[key]) and row[key] > 0 for key in ["median_frame_ms", "p95_frame_ms", "median_draw_calls"]):
                    raise RuntimeError("Android render report contains invalid measurements")
            (args.output / "android-render-performance.json").write_text(json.dumps(metrics, indent=2))
            # Moving native skins advance with actual combat. These are not
            # physical-device frame-rate measurements.
            motion = metrics.get("motion", [])
            if {row.get("region") for row in motion} != set(range(4)):
                raise RuntimeError("Android motion evidence is missing a guardian")
            for row in motion:
                if not row["passed"] or row["frames"] != 20 or row["bone_changes"] < 6 or row["unique_rendered_frames"] != 4 or row.get("skeleton_bones") != 29 or row.get("native_clips") != 9 or not math.isfinite(row.get("source_depth", 0)) or row.get("source_depth", 0) <= .30:
                    raise RuntimeError("Native animation failed to advance or render")
                for frame in row["captures"]:
                    filename = f"motion-region-{row['region']}-{frame:02d}.png"
                    capture = subprocess.run([args.adb, "exec-out", "run-as", PACKAGE, "cat", "files/"+filename], capture_output=True, timeout=60)
                    if capture.returncode or not capture.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
                        raise RuntimeError("Android moving frame missing: "+filename)
                    (args.output / ("android-"+filename)).write_bytes(capture.stdout)
            print("ANDROID ART VERIFIED: four guardian scenes, native 29-bone 3D skins, lit materials and moving screenshots")
            monitor.finish("passed")
            return 0
        log = await_marker("ANDROID_BETA_PASS exact AFK ledger", "first-launch.log")
        if "cooperative=true" not in log: raise RuntimeError("Android launch did not select cooperative AFK recovery")
        adb("shell", "am", "force-stop", PACKAGE)
        adb("logcat", "-b", "all", "-c")
        monitor.launch()
        await_marker("ANDROID_BETA_PASS restart does not repeat", "restart.log")
        capture = subprocess.run([args.adb, "exec-out", "screencap", "-p"], capture_output=True, timeout=30)
        if capture.returncode: raise RuntimeError("Android screenshot capture failed")
        (args.output / "android-camp.png").write_bytes(capture.stdout)
        print("ANDROID BETA RUNTIME VERIFIED: cooperative AFK, exact rewards and cold restart without duplicate settlement")
        monitor.finish("passed")
        return 0
    except (RuntimeError, subprocess.TimeoutExpired, OSError, ValueError, KeyError) as error:
        # A full/unwritable evidence directory must not replace the actual QA
        # failure. Print it first and attempt each diagnostic phase independently.
        print(f"ANDROID BETA RUNTIME FAILED: {error}", flush=True)
        for capture in (lambda: monitor.finish("failed", error), monitor.failure_diagnostics):
            try:
                capture()
            except (RuntimeError, subprocess.TimeoutExpired, OSError) as diagnostic_error:
                print(f"ANDROID_RUNTIME_DIAGNOSTIC_UNAVAILABLE: {diagnostic_error}", flush=True)
        return 1


if __name__ == "__main__": raise SystemExit(main())
