"""Regression tests for native page-size checks and release identity/listing gates."""
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from android_native_check import verify_elf, verify_bundle_native
from check_play_release import validate


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


if __name__ == "__main__": unittest.main()
