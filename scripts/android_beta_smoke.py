"""Run the isolated Android AFK/restart fixture; this never clears the shipping app's data."""
import argparse
import json
import math
from pathlib import Path
import subprocess
import time

PACKAGE = "com.philmenting.emberfallashenveil.betaqa"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("build/android-beta-runtime"))
    parser.add_argument("--skip-install", action="store_true", help="Use the already installed fixture on a slow local emulator")
    parser.add_argument("--art-only", action="store_true", help="Verify the four-region Android graphics fixture instead of AFK reconciliation")
    parser.add_argument("--success-only", action="store_true", help="Verify the first descent, relic equip and oath checkpoint")
    args = parser.parse_args()
    if args.art_only and args.success_only: parser.error("Choose one QA fixture")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*arguments, timeout=60):
        result = subprocess.run([args.adb, *arguments], capture_output=True, text=True, timeout=timeout)
        if result.returncode: raise RuntimeError((result.stdout + result.stderr)[-3000:])
        return result.stdout

    def await_marker(marker, filename):
        deadline = time.monotonic() + (900 if args.art_only else 300)
        while time.monotonic() < deadline:
            log = adb("logcat", "-d", "-s", "godot", timeout=30)
            (args.output / filename).write_text(log)
            if "ANDROID_BETA_FAIL" in log or "ANDROID_ART_FAIL" in log or "ANDROID_SUCCESS_FAIL" in log: raise RuntimeError(log[-4000:])
            if "ERROR:" in log or "shader failed to compile" in log.lower():
                raise RuntimeError("Godot reported a runtime or shader error; see " + str(args.output / filename))
            if marker in log: return log
            time.sleep(3)
        raise RuntimeError(f"Timed out waiting for {marker}; see {args.output / filename}")

    try:
        if not args.skip_install: adb("install", "--no-incremental", "-r", str(args.apk), timeout=180)
        # First-launch immersive guidance can cover the isolated fixture and
        # steal its focus. A recorded CI capture showed this system dialog.
        adb("shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed")
        adb("shell", "pm", "clear", PACKAGE)  # Dedicated fixture package only.
        adb("logcat", "-c")
        adb("shell", "am", "start", "-n", PACKAGE + "/com.godot.game.GodotAppLauncher")
        if args.success_only:
            await_marker("ANDROID_SUCCESS_PASS first descent, class relic and combined oath UI", "success-launch.log")
            for key in ["welcome", "first-fight", "first-relic", "oaths", "oath-run", "filtered-bag", "protected-gear"]:
                capture = subprocess.run([args.adb, "exec-out", "run-as", PACKAGE, "cat", f"files/success-{key}.png"], capture_output=True, timeout=60)
                if capture.returncode or not capture.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
                    raise RuntimeError(f"Android first-session capture {key} missing or invalid")
                (args.output / f"android-success-{key}.png").write_bytes(capture.stdout)
            adb("shell", "am", "force-stop", PACKAGE)
            adb("logcat", "-c")
            adb("shell", "am", "start", "-n", PACKAGE + "/com.godot.game.GodotAppLauncher")
            await_marker("ANDROID_SUCCESS_PASS restart preserves combined oaths", "success-restart.log")
            print("ANDROID SUCCESS LOOP VERIFIED: first fight, one-time relic, gear protection, bag filters, combined oaths and cold restart")
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
                if not row["passed"] or row["frames"] != 20 or row["bone_changes"] < 6 or row["unique_rendered_frames"] != 4:
                    raise RuntimeError("Native animation failed to advance or render")
                for frame in row["captures"]:
                    filename = f"motion-region-{row['region']}-{frame:02d}.png"
                    capture = subprocess.run([args.adb, "exec-out", "run-as", PACKAGE, "cat", "files/"+filename], capture_output=True, timeout=60)
                    if capture.returncode or not capture.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
                        raise RuntimeError("Android moving frame missing: "+filename)
                    (args.output / ("android-"+filename)).write_bytes(capture.stdout)
            print("ANDROID ART VERIFIED: four guardian scenes, real skinned geometry, painted materials and rendered screenshots")
            return 0
        log = await_marker("ANDROID_BETA_PASS exact AFK ledger", "first-launch.log")
        if "cooperative=true" not in log: raise RuntimeError("Android launch did not select cooperative AFK recovery")
        adb("shell", "am", "force-stop", PACKAGE)
        adb("logcat", "-c")
        adb("shell", "am", "start", "-n", PACKAGE + "/com.godot.game.GodotAppLauncher")
        await_marker("ANDROID_BETA_PASS restart does not repeat", "restart.log")
        capture = subprocess.run([args.adb, "exec-out", "screencap", "-p"], capture_output=True, timeout=30)
        if capture.returncode: raise RuntimeError("Android screenshot capture failed")
        (args.output / "android-camp.png").write_bytes(capture.stdout)
        print("ANDROID BETA RUNTIME VERIFIED: cooperative AFK, exact rewards and cold restart without duplicate settlement")
        return 0
    except (RuntimeError, subprocess.TimeoutExpired) as error:
        # Preserve visible startup failures instead of leaving only a timeout.
        # These diagnostics run against the dedicated QA installation.
        try:
            capture = subprocess.run([args.adb, "exec-out", "screencap", "-p"], capture_output=True, timeout=30)
            if capture.returncode == 0 and capture.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
                (args.output / "failure-screen.png").write_bytes(capture.stdout)
            state = adb("shell", "dumpsys", "activity", "top", timeout=30)
            (args.output / "failure-activity.txt").write_text(state)
        except (RuntimeError, subprocess.TimeoutExpired):
            pass
        print(f"ANDROID BETA RUNTIME FAILED: {error}")
        return 1


if __name__ == "__main__": raise SystemExit(main())
