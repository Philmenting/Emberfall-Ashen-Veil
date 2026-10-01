"""Run the isolated Android AFK/restart fixture; this never clears the shipping app's data."""
import argparse
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
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*arguments, timeout=60):
        result = subprocess.run([args.adb, *arguments], capture_output=True, text=True, timeout=timeout)
        if result.returncode: raise RuntimeError((result.stdout + result.stderr)[-3000:])
        return result.stdout

    def await_marker(marker, filename):
        deadline = time.monotonic() + 300
        while time.monotonic() < deadline:
            log = adb("logcat", "-d", "-s", "godot", timeout=30)
            (args.output / filename).write_text(log)
            if "ANDROID_BETA_FAIL" in log: raise RuntimeError(log[-4000:])
            if marker in log: return log
            time.sleep(3)
        raise RuntimeError(f"Timed out waiting for {marker}; see {args.output / filename}")

    try:
        if not args.skip_install: adb("install", "--no-incremental", "-r", str(args.apk), timeout=180)
        adb("shell", "pm", "clear", PACKAGE)  # Dedicated fixture package only.
        adb("logcat", "-c")
        adb("shell", "am", "start", "-n", PACKAGE + "/com.godot.game.GodotAppLauncher")
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
        print(f"ANDROID BETA RUNTIME FAILED: {error}")
        return 1


if __name__ == "__main__": raise SystemExit(main())
