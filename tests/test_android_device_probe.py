"""Physical-probe observer contracts. These fakes are not hardware measurements."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import android_device_probe as probe


class IdentityAdb:
    serial = "authorised-phone"

    def __init__(self, **changes):
        self.props = {"ro.kernel.qemu":"0", "ro.boot.qemu":"", "ro.hardware":"tensor",
                      "ro.product.model":"Pixel 9 Pro Fold", "ro.product.manufacturer":"Google",
                      "ro.product.cpu.abilist":"arm64-v8a,armeabi-v7a", "ro.build.version.release":"16",
                      "ro.build.version.sdk":"36", "ro.build.fingerprint":"test-build"}
        self.props.update(changes)

    def text(self, *command):
        return self.props[command[-1]]


def fixture(case_seconds=200):
    interval = {"samples":1000,"mean":17.1,"median":16.7,"p95":22.0,"p99":28.0,"max":45.0}
    rows = []
    for name in sorted(probe.CLASSES):
        for quality in sorted(probe.QUALITIES):
            rows.append({"class":name,"quality":quality,"frames":1000,"hero_attacks":18,"simulation_seconds":200,
                         "case_wall_seconds":case_seconds,"frame_intervals":interval.copy(),"guardian_attacks":2,
                         "guardian_frame_intervals":{"samples":300,"mean":20.0}})
    return {"schema":2,"status":"measured","platform":"Android","case_seconds":case_seconds,
            "elapsed_seconds":case_seconds*6,"short_fixture_smoke":False,"measurements":rows,
            "provenance":{"apk_sha256":"test-apk-hash","source_commit":"a"*40}}


class ProbeContracts(unittest.TestCase):
    def test_target_selection_never_implicitly_chooses_among_multiple_devices(self):
        self.assertEqual(probe.choose_device("List of devices attached\nphone device product:pixel\n"), "phone")
        for output in ("List of devices attached\n", "phone unauthorized\n", "one device\ntwo device\n"):
            with self.assertRaises(probe.Unavailable): probe.choose_device(output)
        self.assertEqual(probe.choose_device("one device\ntwo device", "two"), "two")
        with self.assertRaises(probe.Unavailable): probe.choose_device("one offline", "one")

    def test_all_known_emulator_signals_are_refused(self):
        for changes in ({"ro.kernel.qemu":"1"}, {"ro.boot.qemu":"1"}, {"ro.hardware":"ranchu"},
                        {"ro.hardware":"goldfish"}, {"ro.hardware":"cutf_cvm"},
                        {"ro.product.model":"sdk_gphone64_arm64"}, {"ro.product.cpu.abilist":"x86_64"}):
            with self.subTest(changes=changes), self.assertRaises(probe.Unavailable):
                probe.physical_identity(IdentityAdb(**changes))
        adb = IdentityAdb(); adb.serial="emulator-5554"
        with self.assertRaises(probe.Unavailable): probe.physical_identity(adb)

    def test_identity_is_bounded_and_does_not_store_raw_serial(self):
        identity=probe.physical_identity(IdentityAdb())
        self.assertTrue(identity["physical_hardware_verified"])
        self.assertEqual(identity["serial_sha256"],hashlib.sha256(b"authorised-phone").hexdigest())
        self.assertNotIn("authorised-phone",json.dumps(identity))

    def test_missing_adb_is_explicit_unavailable_not_a_measurement(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(probe.shutil,"which",return_value=None):
            self.assertEqual(probe.main(["--discover-only","--output",directory]),3)
            report=json.loads((Path(directory)/"device-profile.json").read_text())
            self.assertEqual(report["status"],"unavailable")
            self.assertFalse(report["physical_device_measured"])

    def test_subprocess_target_is_selected_without_a_host_shell(self):
        with patch.object(probe.subprocess,"run",return_value=subprocess.CompletedProcess([],0,"ok","")) as run:
            self.assertEqual(probe.Adb("/sdk/adb","phone").text("shell","getprop","ro.hardware"),"ok")
            self.assertEqual(run.call_args.args[0],["/sdk/adb","-s","phone","shell","getprop","ro.hardware"])
            self.assertNotIn("shell",run.call_args.kwargs)

    def test_manifest_gate_refuses_shipping_or_online_or_nondebuggable_apks(self):
        with tempfile.TemporaryDirectory() as directory:
            apk=Path(directory)/"probe.apk"
            with zipfile.ZipFile(apk,"w") as archive: archive.writestr("lib/arm64-v8a/libgodot.so",b"fixture")
            good=f"package: name='{probe.PACKAGE}' versionCode='54'\napplication-debuggable\n"
            for bad in (good.replace(probe.PACKAGE,"com.philmenting.emberfallashenveil"),
                        good.replace("application-debuggable",""),
                        good+"uses-permission: name='android.permission.INTERNET'\n"):
                with patch.object(probe.subprocess,"run",return_value=subprocess.CompletedProcess([],0,bad,"")):
                    with self.assertRaises(probe.ProbeFailure): probe.verify_qa_apk(apk,"aapt2")
            with patch.object(probe.subprocess,"run",return_value=subprocess.CompletedProcess([],0,good,"")):
                self.assertTrue(probe.verify_qa_apk(apk,"aapt2")["offline"])
            with zipfile.ZipFile(apk,"w") as archive: archive.writestr("lib/x86_64/libgodot.so",b"fixture")
            with patch.object(probe.subprocess,"run",return_value=subprocess.CompletedProcess([],0,good,"")):
                with self.assertRaises(probe.ProbeFailure): probe.verify_qa_apk(apk,"aapt2")

    def test_android_service_parsers_preserve_units_and_missing_data(self):
        battery=probe.parse_battery(" USB powered: true\n level: 78\n scale: 100\n temperature: 327\n voltage: 4100\n Charge counter: 2300000\n")
        self.assertEqual(battery["temperature_c"],32.7)
        self.assertEqual(battery["powered_sources"],["usb"])
        self.assertEqual(battery["charge_counter_uah"],2300000)
        self.assertIsNone(probe.parse_battery("Charge counter: -1")["charge_counter_uah"])
        self.assertIsNone(probe.parse_battery("permission denied")["temperature_c"])
        self.assertFalse(probe.parse_battery("permission denied")["power_state_available"])
        self.assertEqual(probe.parse_memory(" TOTAL PSS: 146372 TOTAL RSS: 2000")["total_pss_kib"],146372)
        self.assertEqual(probe.parse_memory(" TOTAL 246810 10 20")["total_pss_kib"],246810)
        self.assertIsNone(probe.parse_memory("not available")["total_pss_kib"])
        thermal=probe.parse_thermal("Thermal Status: 2\n Temperature{mValue=49.25, mType=0, mName=CPU, mStatus=2}\n")
        self.assertEqual(thermal["android_thermal_status"],2)
        self.assertEqual(thermal["sensors"][0]["temperature_c"],49.25)
        self.assertEqual(probe.parse_thermal("Can't find service: thermalservice")["status"],"unavailable")

    def test_process_cpu_stat_accepts_names_with_spaces_and_parentheses(self):
        fields=["S"]+["0"]*21
        fields[11]="100";fields[12]="20";fields[21]="4096"
        text="123 (game process (native)) "+" ".join(fields)
        self.assertEqual(probe.parse_process_stat(text),{"user_ticks":100,"system_ticks":20,"rss_pages":4096})
        self.assertIsNone(probe.parse_process_stat("permission denied"))
        samples=[{"elapsed_seconds":0,"pid":"123","process_clock_ticks_per_second":100,"process_cpu":{"user_ticks":100,"system_ticks":20}},
                 {"elapsed_seconds":10,"pid":"123","process_clock_ticks_per_second":100,"process_cpu":{"user_ticks":900,"system_ticks":220}}]
        probe.add_cpu_delta(samples)
        self.assertEqual(samples[-1]["process_cpu"]["one_core_percent"],100)
        samples[-1]["pid"]="456"; samples[-1]["process_cpu"].pop("one_core_percent")
        probe.add_cpu_delta(samples)
        self.assertNotIn("one_core_percent",samples[-1]["process_cpu"])

    def test_usb_charging_or_missing_power_state_never_claims_battery_drain(self):
        def sample(level,counter,power):
            return {"battery":probe.parse_battery(f"USB powered: {power}\nlevel: {level}\nCharge counter: {counter}\n"),
                    "memory":{"total_pss_kib":200000},"thermal":{"android_thermal_status":0}}
        samples=[sample(80,2400000,"false"),sample(78,2300000,"false")]
        self.assertEqual(probe.summarise_system(samples)["battery_drain_uah"],100000)
        samples[-1]=sample(78,2300000,"true")
        self.assertIsNone(probe.summarise_system(samples)["battery_drain_uah"])
        samples[-1]["battery"]["power_state_available"]=False
        samples[-1]["battery"]["powered_sources"]=[]
        self.assertIsNone(probe.summarise_system(samples)["battery_drain_uah"])

    def test_unavailable_optional_services_do_not_hide_other_samples(self):
        class Services:
            def run(self,*command,**kwargs):
                if command[-1]=="thermalservice": raise subprocess.TimeoutExpired(command,30)
                if command[-1]=="battery": return subprocess.CompletedProcess([],0,"level: 70\ntemperature: 310","")
                if "meminfo" in command:return subprocess.CompletedProcess([],0,"TOTAL PSS: 123456","")
                return subprocess.CompletedProcess([],1,"","permission denied")
        with tempfile.TemporaryDirectory() as directory:
            sample=probe.collect_sample(Services(),Path(directory),0,10,"123",None)
            self.assertEqual(sample["memory"]["total_pss_kib"],123456)
            self.assertEqual(sample["battery"]["temperature_c"],31)
            self.assertEqual(sample["thermal"]["status"],"unavailable")
            self.assertIsNone(sample["process_cpu"])
            self.assertEqual(len(sample["unavailable"]),2)

    def test_fixture_requires_all_distinct_cases_matching_apk_and_real_time(self):
        self.assertEqual(probe.validate_fixture(fixture(),"test-apk-hash","a"*40,200)["status"],"measured")
        mutations=[lambda r:r.update(platform="Linux"),lambda r:r.update(short_fixture_smoke=True),
                   lambda r:r.update(elapsed_seconds=12),lambda r:r["provenance"].update(apk_sha256="other"),
                   lambda r:r["measurements"].pop(),lambda r:r["measurements"].__setitem__(1,r["measurements"][0]),
                   lambda r:r["measurements"][0].update(hero_attacks=0),
                   lambda r:r["measurements"][0].update(guardian_attacks=0),
                   lambda r:r["measurements"][0]["frame_intervals"].update(p95=float("nan"))]
        for mutate in mutations:
            report=copy.deepcopy(fixture()); mutate(report)
            with self.subTest(report=report),self.assertRaises(probe.ProbeFailure):
                probe.validate_fixture(report,"test-apk-hash","a"*40,200)


class FakeAdb:
    """Only for observer failure-path verification; never used for a hardware receipt."""
    mode="complete"
    commands=[]
    report=None
    config=None

    def __init__(self, executable,serial=None):
        self.serial=serial
        self.calls=0

    def run(self,*command,input=None,required=True,timeout=30):
        type(self).commands.append(command)
        stdout=""; code=0; stderr=""
        if command[:2]==("devices","-l"):stdout="List of devices attached\nphone device product:pixel\n"
        elif command[:2]==("shell","getprop"):
            stdout=IdentityAdb().props[command[-1]]
        elif command[0]=="install":stdout="Success"
        elif command[:3]==("shell","am","start"):
            stdout="Error type 3\nError: Activity does not exist" if self.mode=="activity-error" else "Starting: Intent"
        elif command[:2]==("shell","getconf"):stdout="100"
        elif command[:2]==("shell","pidof"):
            self.calls+=1
            if self.mode=="process-loss" and self.calls>1:code=1
            else:stdout="456" if self.mode=="restart" and self.calls>1 else "123"
        elif command[:4]==("shell","-T","run-as",probe.PACKAGE) and "tee" in command:
            type(self).config=json.loads(input)
        elif command[-1]=="files/device-probe-config.json":stdout=json.dumps(type(self).config)
        elif command[-1]=="files/device-probe-status.json":
            state="failed" if self.mode=="fixture-failure" else "measuring" if self.mode in ("process-loss","restart","timeout") else "measured"
            stdout=json.dumps({"status":state,"failure":"missing combat"})
        elif command[-1]=="files/device-performance.json":
            report=fixture(30);report["provenance"]=type(self).config["provenance"]
            stdout=json.dumps(report)
        elif command[0]=="logcat":stdout="SCRIPT ERROR: bad animation" if self.mode=="script-error" else "ANDROID_DEVICE_PROBE_MEASURED"
        elif "meminfo" in command:stdout="TOTAL PSS: 100000"
        elif command[-1]=="battery":stdout="USB powered: true\nlevel: 80\ntemperature: 300"
        elif command[-1]=="thermalservice":stdout="Thermal Status: 0"
        elif command[-1].startswith("/proc/"):stdout="permission denied";code=1
        if required and code:raise probe.ProbeFailure("fake adb failure")
        return subprocess.CompletedProcess([],code,stdout,stderr)

    def text(self,*command,**kwargs):return self.run(*command,**kwargs).stdout


class ObserverLifecycle(unittest.TestCase):
    def run_mode(self,mode):
        FakeAdb.mode=mode;FakeAdb.commands=[]
        with tempfile.TemporaryDirectory() as directory:
            apk=Path(directory)/"probe.apk";apk.write_bytes(b"fake test APK")
            output=Path(directory)/"output"
            clock=iter([0,200,200]+[201+i*2 for i in range(400)])
            with patch.object(probe,"Adb",FakeAdb),patch.object(probe,"verify_qa_apk",return_value={"package":probe.PACKAGE}),\
                 patch.object(probe.time,"monotonic",side_effect=lambda:next(clock)),patch.object(probe.time,"sleep"):
                code=probe.main(["--apk",str(apk),"--source-commit","a"*40,"--adb","adb",
                                 "--output",str(output),"--case-seconds","30"])
            return code,json.loads((output/"device-profile.json").read_text())

    def test_complete_profile_is_measurement_with_touch_pending_and_no_release_pass(self):
        code,report=self.run_mode("complete")
        self.assertEqual(code,0);self.assertEqual(report["status"],"measured_touch_pending")
        self.assertTrue(report["physical_device_measured"])
        self.assertEqual(report["acceptance"]["touch"],"pending")
        self.assertFalse(report["acceptance"]["release_ready"])
        self.assertIsNone(report["system_summary"]["battery_drain_uah"])
        self.assertIn(("shell","-T","run-as",probe.PACKAGE,"tee","files/device-probe-config.json"),FakeAdb.commands)
        self.assertFalse(any("clear" in command or "uninstall" in command for command in FakeAdb.commands))

    def test_live_failure_never_becomes_a_profile_pass(self):
        for mode in ("activity-error","process-loss","restart","fixture-failure","script-error","timeout"):
            with self.subTest(mode=mode):
                code,report=self.run_mode(mode)
                self.assertEqual(code,1);self.assertEqual(report["status"],"failed")
                self.assertFalse(report["physical_device_measured"])
                self.assertEqual(FakeAdb.commands[-1],("shell","am","force-stop",probe.PACKAGE))


if __name__=="__main__":unittest.main()
