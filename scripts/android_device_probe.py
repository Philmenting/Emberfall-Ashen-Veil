"""Collect a physical-only Android gameplay profile without touching the shipping save.

Exit 0 = profiling completed (touch acceptance still pending); 1 = failure;
3 = hardware/tool unavailable. A software emulator never produces a phone pass.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import time
import zipfile

PACKAGE = "com.philmenting.emberfallashenveil.betaqa"
LAUNCHER = PACKAGE + "/com.godot.game.GodotAppLauncher"
CLASSES = {"Vowkeeper", "Arcanist", "Ranger"}
QUALITIES = {"balanced", "battery"}


class ProbeFailure(RuntimeError):
    pass


class Unavailable(ProbeFailure):
    pass


class Adb:
    def __init__(self, executable, serial=None):
        self.executable = executable
        self.serial = serial

    def run(self, *arguments, input=None, required=True, timeout=30):
        command = [self.executable]
        if self.serial:
            command += ["-s", self.serial]
        command += list(arguments)
        result = subprocess.run(command, input=input, capture_output=True, text=True, timeout=timeout)
        if required and result.returncode:
            raise ProbeFailure("adb " + " ".join(arguments[:4]) + ": " + (result.stdout + result.stderr)[-1200:])
        return result

    def text(self, *arguments, **kwargs):
        return self.run(*arguments, **kwargs).stdout


def choose_device(output, requested=None):
    devices = []
    for line in output.splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[0] != "List":
            devices.append((parts[0], parts[1]))
    if requested:
        matches = [entry for entry in devices if entry[0] == requested]
        if not matches or matches[0][1] != "device":
            raise Unavailable("The requested device is absent or is not authorised in adb")
        return requested
    ready = [serial for serial, state in devices if state == "device"]
    if len(ready) != 1:
        raise Unavailable("Connect exactly one authorised phone or select it with --serial")
    return ready[0]


def physical_identity(adb):
    properties = {}
    for key in ("ro.kernel.qemu", "ro.boot.qemu", "ro.hardware", "ro.product.model",
                "ro.product.manufacturer", "ro.product.cpu.abilist", "ro.build.version.release",
                "ro.build.version.sdk", "ro.build.fingerprint"):
        properties[key] = adb.text("shell", "getprop", key).strip()
    emulator = (adb.serial.startswith("emulator-") or properties["ro.kernel.qemu"] == "1" or
                properties["ro.boot.qemu"] == "1" or
                any(name in properties["ro.hardware"].lower() for name in ("ranchu", "goldfish", "cuttlefish", "cutf", "qemu", "vbox")) or
                properties["ro.product.model"].lower().startswith(("sdk_gphone", "android sdk built")))
    if emulator:
        raise Unavailable("The selected target is a software emulator; no physical-phone measurement was made")
    if not properties["ro.product.model"] or "arm64-v8a" not in properties["ro.product.cpu.abilist"].split(","):
        raise Unavailable("The selected device does not expose an ARM64 phone identity")
    return {"physical_hardware_verified": True, "serial_sha256": hashlib.sha256(adb.serial.encode()).hexdigest(),
            "properties": properties, "identity_method": "adb target plus qemu/hardware/ABI properties; not device attestation"}


def parse_battery(text):
    fields = {}
    for key in ("level", "scale", "temperature", "voltage", "status", "health", "Charge counter"):
        match = re.search(r"^\s*" + re.escape(key) + r":\s*(-?\d+)\s*$", text, re.MULTILINE)
        fields[key] = int(match.group(1)) if match else None
    powered = []
    power_fields = 0
    for name in ("AC", "USB", "Wireless", "Dock"):
        match = re.search(r"^\s*" + name + r" powered:\s*(true|false)", text, re.MULTILINE | re.IGNORECASE)
        if match:
            power_fields += 1
            if match.group(1).lower() == "true":
                powered.append(name.lower())
    return {"level": fields["level"], "scale": fields["scale"],
            "temperature_c": fields["temperature"] / 10 if fields["temperature"] is not None else None,
            "voltage_mv": fields["voltage"], "charge_counter_uah": fields["Charge counter"]
                if fields["Charge counter"] is not None and fields["Charge counter"]>0 else None,
            "android_status": fields["status"], "health": fields["health"], "powered_sources": powered,
            "power_state_available": power_fields > 0,
            "status": "measured" if any(value is not None for value in fields.values()) else "unavailable",
            "scope": "battery sensor and charge state; battery temperature is not CPU/GPU temperature"}


def parse_memory(text):
    # Android versions expose either the App Summary TOTAL PSS or the table TOTAL.
    match = re.search(r"TOTAL PSS:\s*(\d+)", text)
    if not match:
        match = re.search(r"^\s*TOTAL\s+(\d+)\s+", text, re.MULTILINE)
    return {"total_pss_kib": int(match.group(1)) if match else None,
            "status": "measured" if match else "unavailable"}


def parse_thermal(text):
    match = re.search(r"(?:Thermal Status|Current thermal status):\s*(\d+)", text, re.IGNORECASE)
    sensors = []
    for value, sensor_type, name, status in re.findall(
            r"Temperature\{mValue=([-+\d.eE]+), mType=(\d+), mName=([^,}]+), mStatus=(\d+)\}", text):
        numeric = float(value)
        if math.isfinite(numeric):
            sensors.append({"name": name, "android_type": int(sensor_type), "temperature_c": numeric,
                            "throttling_status": int(status)})
    return {"android_thermal_status": int(match.group(1)) if match else None, "sensors": sensors,
            "status": "measured" if match or sensors else "unavailable"}


def parse_process_stat(text):
    # comm may contain spaces and parentheses; field 3 follows the last ')'.
    closing = text.rfind(")")
    if closing < 0:
        return None
    fields = text[closing + 1:].split()
    try:
        return {"user_ticks": int(fields[11]), "system_ticks": int(fields[12]), "rss_pages": int(fields[21])}
    except (IndexError, ValueError):
        return None


def validate_fixture(report, apk_sha256, source_commit, case_seconds):
    if report.get("schema") != 2 or report.get("status") != "measured" or report.get("platform") != "Android":
        raise ProbeFailure("The fixture did not produce a completed Android profile")
    provenance = report.get("provenance", {})
    if provenance.get("apk_sha256") != apk_sha256 or provenance.get("source_commit") != source_commit:
        raise ProbeFailure("The fixture profile does not match this APK and source receipt")
    if report.get("short_fixture_smoke") or float(report.get("case_seconds", 0)) < case_seconds:
        raise ProbeFailure("A short fixture smoke cannot stand in for the requested sustained profile")
    if float(report.get("elapsed_seconds", 0)) < case_seconds * 6 * .98:
        raise ProbeFailure("The fixture wall-clock duration was too short for the requested workload")
    rows = report.get("measurements", [])
    expected = {(name, mode) for name in CLASSES for mode in QUALITIES}
    if len(rows) != 6 or {(row.get("class"), row.get("quality")) for row in rows} != expected:
        raise ProbeFailure("The fixture omitted or duplicated a class/quality case")
    for row in rows:
        if (row.get("frames", 0) < 30 or row.get("hero_attacks", 0) < 1 or row.get("simulation_seconds", 0) <= 0 or
                row.get("case_wall_seconds", 0) < case_seconds * .98):
            raise ProbeFailure("A class/quality case lacked sustained ordinary combat")
        interval = row.get("frame_intervals", {})
        values = [interval.get(key) for key in ("mean", "median", "p95", "p99", "max")]
        if interval.get("samples") != row["frames"] or not all(
                isinstance(value, (float, int)) and math.isfinite(value) and value > 0 for value in values):
            raise ProbeFailure("The frame-pacing measurement is incomplete or non-finite")
        if case_seconds >= 150 and (row.get("guardian_attacks", 0)<1 or
                                  row.get("guardian_frame_intervals",{}).get("samples",0)<30):
            raise ProbeFailure("A sustained case did not include a measured ordinary-equipment guardian fight")
    return report


def save_report(path, report):
    path.write_text(json.dumps(report, indent=2) + "\n")


def verify_qa_apk(apk, executable=None):
    tool = executable or shutil.which("aapt2") or shutil.which("aapt")
    if not tool:
        raise Unavailable("aapt2/aapt is required to verify the isolated QA package before installation; provide --aapt")
    result = subprocess.run([tool, "dump", "badging", str(apk)], capture_output=True, text=True, timeout=60)
    if result.returncode:
        raise ProbeFailure("Unable to inspect APK identity: " + result.stderr[-1000:])
    package = re.search(r"^package: name='([^']+)'", result.stdout, re.MULTILINE)
    if not package or package.group(1) != PACKAGE or "application-debuggable" not in result.stdout:
        raise ProbeFailure("Only the dedicated debuggable betaqa APK can be installed by this observer")
    if re.search(r"uses-permission[^\n]*android.permission.INTERNET", result.stdout):
        raise ProbeFailure("The physical QA workload must use the offline export preset")
    with zipfile.ZipFile(apk) as archive:
        if not any(name.startswith("lib/arm64-v8a/") and name.endswith(".so") for name in archive.namelist()):
            raise ProbeFailure("The QA APK has no native ARM64 library")
    return {"package":PACKAGE,"debuggable":True,"offline":True,"arm64_native":True}


def summarise_system(samples):
    pss = [sample["memory"]["total_pss_kib"] for sample in samples
           if sample.get("memory", {}).get("total_pss_kib") is not None]
    batteries = [sample["battery"] for sample in samples if sample.get("battery", {}).get("level") is not None]
    charging = any(battery["powered_sources"] for battery in batteries)
    power_known = bool(batteries) and all(battery["power_state_available"] for battery in batteries)
    charge_counters = [battery["charge_counter_uah"] for battery in batteries if battery["charge_counter_uah"] is not None]
    return {"memory_peak_pss_kib":max(pss) if pss else None,"battery_power_state_available":power_known,
            "external_power_seen":charging,"battery_level_first":batteries[0]["level"] if batteries else None,
            "battery_level_last":batteries[-1]["level"] if batteries else None,
            "battery_drain_uah":charge_counters[0]-charge_counters[-1]
                if power_known and not charging and len(charge_counters) == len(batteries) and len(batteries)>1 else None,
            "battery_drain_status":"measured_sensor_delta" if power_known and not charging and len(charge_counters)==len(batteries) and len(batteries)>1
                else "unavailable_or_externally_powered",
            "thermal_statuses":[sample.get("thermal",{}).get("android_thermal_status") for sample in samples]}


def add_cpu_delta(samples):
    if len(samples)<2:
        return
    before, current = samples[-2:]
    first, last = before.get("process_cpu"), current.get("process_cpu")
    ticks = current.get("process_clock_ticks_per_second")
    elapsed = current["elapsed_seconds"]-before["elapsed_seconds"]
    if first and last and ticks and elapsed>0 and current["pid"]==before["pid"]:
        used = last["user_ticks"]+last["system_ticks"]-first["user_ticks"]-first["system_ticks"]
        if used>=0:
            current["process_cpu"]["one_core_percent"] = 100*used/ticks/elapsed


def collect_sample(adb, directory, index, elapsed, pid, clock_ticks):
    sample = {"elapsed_seconds": round(elapsed, 3), "pid": pid, "unavailable": []}
    for name, command, parser in (
            ("memory", ("shell", "dumpsys", "meminfo", PACKAGE), parse_memory),
            ("battery", ("shell", "dumpsys", "battery"), parse_battery),
            ("thermal", ("shell", "dumpsys", "thermalservice"), parse_thermal)):
        try:
            result = adb.run(*command, required=False)
        except (OSError, subprocess.TimeoutExpired) as error:
            result = subprocess.CompletedProcess([],1,"",str(error))
        (directory / f"sample-{index:04d}-{name}.txt").write_text(result.stdout + result.stderr)
        sample[name] = parser(result.stdout)
        if result.returncode:
            sample["unavailable"].append(name + ": " + result.stderr.strip()[-300:])
    try:
        result = adb.run("shell", "run-as", PACKAGE, "cat", f"/proc/{pid}/stat", required=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        result = subprocess.CompletedProcess([],1,"",str(error))
    sample["process_cpu"] = parse_process_stat(result.stdout)
    sample["process_clock_ticks_per_second"] = clock_ticks
    if sample["process_cpu"] is None:
        sample["unavailable"].append("process CPU accounting is unavailable on this Android build")
    return sample


def profile(args, report):
    if not args.apk or not args.apk.is_file():
        raise ProbeFailure("Provide the isolated ARM64 device-probe APK with --apk")
    if not re.fullmatch(r"[0-9a-f]{40}", args.source_commit or ""):
        raise ProbeFailure("Provide the exact 40-character --source-commit used to export the APK")
    executable = args.adb or shutil.which("adb")
    if not executable:
        raise Unavailable("adb is unavailable; no physical Android device could be inspected")
    adb = Adb(executable)
    adb.serial = choose_device(adb.text("devices", "-l"), args.serial)
    report["device"] = physical_identity(adb)
    args.selected_adb = adb
    if args.discover_only:
        report["status"] = "available_not_measured"
        return
    with args.apk.open("rb") as stream:
        apk_hash = hashlib.file_digest(stream, "sha256").hexdigest()
    report["apk"] = {"path": str(args.apk.resolve()), "sha256": apk_hash}
    report["source_commit"] = args.source_commit
    report["apk_manifest"] = verify_qa_apk(args.apk, args.aapt)
    args.verified_qa_package = True
    report["source_provenance_scope"] = "Operator-provided export commit echoed by the fixture; pair with the exporter receipt. APK SHA256 is measured from the installed file; the source commit is not independently embedded or attested."
    # No shipping package clear/uninstall, battery-service mutation or device settings change.
    adb.text("shell", "am", "force-stop", PACKAGE)
    install = adb.text("install", "-r", str(args.apk.resolve()), timeout=180)
    if "Success" not in install:
        raise ProbeFailure("adb install did not confirm Success")
    config = {"case_seconds": args.case_seconds, "warmup_seconds": 3,
              "provenance": {"apk_sha256": apk_hash, "source_commit": args.source_commit}}
    adb.text("shell", "run-as", PACKAGE, "mkdir", "-p", "files")
    # shell -T forwards stdin without a PTY; exec-out only copies stdout.
    # All remote arguments are fixed tokens, so no shell quoting is needed.
    adb.run("shell", "-T", "run-as", PACKAGE, "tee", "files/device-probe-config.json",
            input=json.dumps(config))
    copied_config = json.loads(adb.text("exec-out", "run-as", PACKAGE, "cat", "files/device-probe-config.json"))
    if copied_config != config:
        raise ProbeFailure("The device probe configuration did not match the requested source and workload")
    for filename in ("device-probe-status.json", "device-performance.json"):
        adb.text("shell", "run-as", PACKAGE, "rm", "-f", "files/" + filename)
    start = adb.text("shell", "am", "start", "-n", LAUNCHER)
    if re.search(r"^\s*(Error|Exception|SecurityException)", start, re.MULTILINE | re.IGNORECASE):
        raise ProbeFailure("Activity start reported an error: " + start[-500:])
    clock = adb.run("shell", "getconf", "CLK_TCK", required=False)
    ticks = int(clock.stdout.strip()) if clock.returncode == 0 and clock.stdout.strip().isdigit() else None
    started = time.monotonic()
    deadline = started + args.case_seconds * 6 + args.timeout_extra_seconds
    next_sample = started
    observed_pid = None
    report["status"] = "measuring"
    report["system_samples"] = []
    while time.monotonic() < deadline:
        now = time.monotonic()
        response = adb.run("shell", "pidof", PACKAGE, required=False)
        pids = response.stdout.split()
        if response.returncode and not (response.returncode == 1 and not pids and not response.stderr.strip()):
            raise ProbeFailure("The device stopped responding: " + response.stderr[-500:])
        if pids and (len(pids) != 1 or not pids[0].isdigit()):
            raise ProbeFailure("Unexpected QA process identity: " + response.stdout)
        if not pids:
            if observed_pid or now - started >= 30:
                raise ProbeFailure("The QA process disappeared or failed to start")
            time.sleep(2)
            continue
        if observed_pid and pids[0] != observed_pid:
            raise ProbeFailure("The QA process restarted before finishing the profile")
        observed_pid = pids[0]
        status_text = adb.run("exec-out", "run-as", PACKAGE, "cat", "files/device-probe-status.json", required=False)
        status = None
        if status_text.returncode == 0:
            try:
                status = json.loads(status_text.stdout)
            except json.JSONDecodeError:
                pass  # A write in progress is not a completed report.
        report["fixture_progress"] = status
        if status and status.get("status") == "failed":
            raise ProbeFailure("The fixture failed: " + status.get("failure", "unknown"))
        if now >= next_sample or status and status.get("status") == "measured":
            report["system_samples"].append(collect_sample(adb, args.output, len(report["system_samples"]),
                                                         now - started, observed_pid, ticks))
            add_cpu_delta(report["system_samples"])
            next_sample = now + args.sample_seconds
        save_report(args.output / "device-profile.json", report)
        if status and status.get("status") == "measured":
            log = adb.text("logcat", "-d", "--pid="+observed_pid, "-v", "threadtime", "-s", "godot")
            (args.output / "qa-logcat.txt").write_text(log)
            if "SCRIPT ERROR:" in log or "ERROR:" in log or "shader failed to compile" in log.lower():
                raise ProbeFailure("The QA process reported a script/runtime/shader error; see qa-logcat.txt")
            fixture = json.loads(adb.text("exec-out", "run-as", PACKAGE, "cat", "files/device-performance.json"))
            validate_fixture(fixture, apk_hash, args.source_commit, args.case_seconds)
            if time.monotonic()-started < args.case_seconds * 6 * .95:
                raise ProbeFailure("The observer did not see the requested wall-clock workload; a stale or accelerated fixture cannot pass")
            save_report(args.output / "device-performance.json", fixture)
            report["fixture"] = fixture
            report["system_summary"] = summarise_system(report["system_samples"])
            report["status"] = "measured_touch_pending"
            report["elapsed_seconds"] = round(time.monotonic() - started, 3)
            report["acceptance"] = {"profiling_complete": True, "touch": "pending", "release_ready": False,
                                    "performance_target_met": "requires review of individual case timings and throttling"}
            break
        time.sleep(2)
    else:
        raise ProbeFailure("Timed out without all six real-time class/quality measurements")
    exit_info = adb.run("shell", "dumpsys", "activity", "exit-info", PACKAGE, required=False)
    (args.output / "qa-exit-info.txt").write_text(exit_info.stdout+exit_info.stderr)
    adb.text("shell", "am", "force-stop", PACKAGE)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path)
    parser.add_argument("--source-commit")
    parser.add_argument("--adb", help="Path to adb; defaults to the executable on PATH")
    parser.add_argument("--aapt", help="Path to aapt2/aapt; verifies QA identity before installing")
    parser.add_argument("--serial", help="An already-authorised attached physical device")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--discover-only", action="store_true", help="Read target identity without installing or starting an APK")
    parser.add_argument("--case-seconds", type=float, default=200)
    parser.add_argument("--sample-seconds", type=float, default=10)
    parser.add_argument("--timeout-extra-seconds", type=float, default=180)
    args = parser.parse_args(argv)
    if not 30 <= args.case_seconds <= 600 or not 5 <= args.sample_seconds <= 60 or not 30 <= args.timeout_extra_seconds <= 600:
        parser.error("Use 30–600 seconds/case, 5–60 seconds/system sample and 30–600 seconds/timeout allowance")
    args.output.mkdir(parents=True, exist_ok=True)
    report = {"schema":1,"status":"starting","started_at":datetime.now(timezone.utc).isoformat(),
              "observer_sha256":hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "touch_acceptance":"pending","physical_device_measured":False,
              "scope":"Physical-only QA profile; USB charging, sensor availability and instrumentation affect results. No touch-latency or beta-readiness inference."}
    try:
        # Discovery does not need an APK; full profiling validates it before mutation.
        if args.discover_only:
            executable = args.adb or shutil.which("adb")
            if not executable:
                raise Unavailable("adb is unavailable; no physical Android device could be inspected")
            adb = Adb(executable)
            adb.serial = choose_device(adb.text("devices", "-l"), args.serial)
            report["device"] = physical_identity(adb)
            report["status"] = "available_not_measured"
        else:
            profile(args, report)
            report["physical_device_measured"] = report["status"] == "measured_touch_pending"
        code = 0
    except Unavailable as error:
        report.update({"status":"unavailable","reason":str(error)})
        code = 3
    except (ProbeFailure, OSError, subprocess.TimeoutExpired, ValueError, KeyError, TypeError) as error:
        report.update({"status":"failed","reason":str(error)})
        code = 1
    if code and getattr(args, "selected_adb", None):
        for filename, command in (("failure-exit-info.txt", ("shell","dumpsys","activity","exit-info",PACKAGE)),
                                  ("failure-qa-logcat.txt", ("logcat","-d","-v","threadtime","-s","godot"))):
            try:
                result = args.selected_adb.run(*command, required=False)
                (args.output/filename).write_text(result.stdout+result.stderr)
            except (OSError, subprocess.TimeoutExpired):
                pass  # Keep the original profile failure.
        if getattr(args,"verified_qa_package",False):
            try:
                args.selected_adb.run("shell","am","force-stop",PACKAGE,required=False)
            except (OSError,subprocess.TimeoutExpired):
                pass  # Loss of the device must not replace the first failure.
    report["finished_at"] = datetime.now(timezone.utc).isoformat()
    save_report(args.output / "device-profile.json", report)
    print(json.dumps({"status":report["status"],"report":str(args.output / "device-profile.json"),
                      "reason":report.get("reason"),"physical_device_measured":report["physical_device_measured"]}))
    return code


if __name__ == "__main__":
    raise SystemExit(main())
