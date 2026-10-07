"""Reject lost samples, video clock drift and misplaced accepted-cue evidence."""
import importlib.util
import gzip
import math
from pathlib import Path
import struct
import sys
import tempfile
import unittest

MODULE_PATH = Path(__file__).resolve().parents[1] / "tools" / "capture_arcanist_quality.py"
SPEC = importlib.util.spec_from_file_location("capture_arcanist_quality", MODULE_PATH)
CAPTURE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CAPTURE)
sys.modules["capture_arcanist_quality"] = CAPTURE

PREFIX_SPEC = importlib.util.spec_from_file_location("capture_combat_quality", MODULE_PATH.with_name("capture_combat_quality.py"))
PREFIX = importlib.util.module_from_spec(PREFIX_SPEC)
PREFIX_SPEC.loader.exec_module(PREFIX)
ANALYSIS_SPEC = importlib.util.spec_from_file_location("analyze_combat_quality", MODULE_PATH.with_name("analyze_combat_quality.py"))
ANALYSIS = importlib.util.module_from_spec(ANALYSIS_SPEC)
ANALYSIS_SPEC.loader.exec_module(ANALYSIS)


class AudioChronologyContracts(unittest.TestCase):
    @staticmethod
    def record(frame, rate=44100):
        start = frame * rate // 30
        return {"audio": {"first_sample_frame": start,
                          "end_sample_frame": (frame + 1) * rate // 30,
                          "sample_rate": rate, "channels": 2,
                          "accepted_state_events": [{"type": "cue", "key": "nova", "sample_frame": start}]}}

    def test_normal_and_fractional_rates_have_no_accumulated_drift(self):
        for rate in (22050, 44100, 48000, 44117):
            with self.subTest(rate=rate):
                sample, previous_rate = 0, None
                for frame in range(2496):
                    sample, previous_rate = CAPTURE.verify_audio_record(self.record(frame, rate), frame, sample, previous_rate)
                self.assertEqual(sample, 2496 * rate // 30)

    def test_dropped_or_overlapping_native_samples_are_rejected(self):
        for field, delta in (("first_sample_frame", -1), ("first_sample_frame", 1),
                             ("end_sample_frame", -1), ("end_sample_frame", 1)):
            with self.subTest(field=field, delta=delta):
                record = self.record(1)
                record["audio"][field] += delta
                with self.assertRaisesRegex(RuntimeError, "samples"):
                    CAPTURE.verify_audio_record(record, 1, 1470, 44100)

    def test_rate_and_channel_changes_are_rejected(self):
        for field, value in (("sample_rate", 0), ("sample_rate", 48000), ("channels", 1)):
            with self.subTest(field=field, value=value):
                record = self.record(1)
                record["audio"][field] = value
                with self.assertRaisesRegex(RuntimeError, "rate/channels"):
                    CAPTURE.verify_audio_record(record, 1, 1470, 44100)

    def test_cue_cannot_be_shifted_to_an_unrecorded_audio_boundary(self):
        record = self.record(1)
        record["audio"]["accepted_state_events"][0]["sample_frame"] += 1470
        with self.assertRaisesRegex(RuntimeError, "sample boundary"):
            CAPTURE.verify_audio_record(record, 1, 1470, 44100)

    def test_actual_simulation_and_continuous_video_clock_are_both_checked(self):
        record = {"frame": 0, "simulation_elapsed": 0, "simulation_accumulator": 1 / 30,
                  "simulation_advanced": True, "playback_seconds": 0}
        self.assertAlmostEqual(CAPTURE.verify_record(record, 0, 0), 1 / 30)
        record["simulation_accumulator"] = .1
        with self.assertRaisesRegex(RuntimeError, "elapsed-time jump"):
            CAPTURE.verify_record(record, 0, 0)
        record["simulation_accumulator"] = 1 / 30
        record["playback_seconds"] = 1 / 30
        with self.assertRaisesRegex(RuntimeError, "playback clock"):
            CAPTURE.verify_record(record, 0, 0)


class OrdinaryPrefixContracts(unittest.TestCase):
    @staticmethod
    def summary(seconds=30):
        return {"frames": seconds * 30, "complete": False,
                "simulation_finished": False, "won": False, "settle_frames_recorded": 0}

    def test_exact_ordinary_prefix_is_accepted_without_victory(self):
        for seconds in (20, 25, 30):
            CAPTURE.verify_prefix_summary(self.summary(seconds), seconds, seconds * 30)

    def test_missing_or_extra_prefix_frames_are_rejected(self):
        for delta in (-1, 1):
            with self.assertRaisesRegex(RuntimeError, "frame count"):
                CAPTURE.verify_prefix_summary(self.summary(), 30, 900 + delta)
        summary = self.summary()
        summary["frames"] = 901
        with self.assertRaisesRegex(RuntimeError, "frame count"):
            CAPTURE.verify_prefix_summary(summary, 30, 900)

    def test_a_prefix_cannot_claim_dungeon_completion_or_victory(self):
        for key in ("complete", "simulation_finished", "won"):
            summary = self.summary()
            summary[key] = True
            with self.assertRaisesRegex(RuntimeError, "completed/won"):
                CAPTURE.verify_prefix_summary(summary, 30, 900)
            summary.pop(key)
            with self.assertRaisesRegex(RuntimeError, "completed/won"):
                CAPTURE.verify_prefix_summary(summary, 30, 900)
        summary = self.summary()
        summary["settle_frames_recorded"] = 1
        with self.assertRaisesRegex(RuntimeError, "result settling"):
            CAPTURE.verify_prefix_summary(summary, 30, 900)

    def test_motion_evidence_is_selected_only_for_explicit_prefix(self):
        row = {"frame": 315, "prefix_first_evade_age": 3}
        self.assertEqual(CAPTURE.selected_reasons(row, set()), [])
        self.assertEqual(CAPTURE.selected_reasons(row, set(), combat_prefix=True),
                         ["first_evade_age-offset-03"])

    def test_wrapper_defaults_to_thirty_seconds_and_keeps_explicit_duration(self):
        self.assertEqual(PREFIX.prefix_arguments(["--output", "/tmp/capture"]),
                         ["--output", "/tmp/capture", "--prefix-seconds", "30"])
        for arguments in (["--prefix-seconds", "20"], ["--prefix-seconds=25"]):
            self.assertEqual(PREFIX.prefix_arguments(arguments), arguments)


class OrdinaryComparisonContracts(unittest.TestCase):
    @staticmethod
    def row():
        return {"frame": 0, "simulation_elapsed": 0, "simulation_accumulator": 1 / 30,
                "stage": 0, "phase": "combat", "finished": False, "won": False,
                "hero_hp": 380, "pending_attack": {}, "guardian": {"hp": 500},
                "events": [{"type": "hit", "target": 0, "damage": 100}],
                "camera": {"origin": [0, 10, 10]}}

    def test_pose_and_presentation_release_do_not_hide_gameplay_differences(self):
        before, after = self.row(), self.row()
        after["hero_pose"] = {"pelvis": "new-pose"}
        after["events"] += [{"type": "hero_release", "target": 0}]
        result = ANALYSIS.compare_rows([before], [after])
        self.assertTrue(result["authoritative_trace_equal"])
        after["hero_hp"] -= 1
        self.assertEqual(ANALYSIS.compare_rows([before], [after])["authoritative_difference_frames"], [0])

    def test_camera_changes_and_missing_baseline_are_reported_independently(self):
        before, after = self.row(), self.row()
        after["camera"] = {"origin": [0, 11, 10]}
        result = ANALYSIS.compare_rows([before], [after])
        self.assertTrue(result["authoritative_trace_equal"])
        self.assertEqual(result["camera_difference_frames"], [0])
        with self.assertRaisesRegex(ValueError, "entire requested"):
            ANALYSIS.compare_rows([], [after])

    def test_raw_and_compressed_native_prefix_samples_are_scanned_independently(self):
        with tempfile.TemporaryDirectory() as location:
            directory = Path(location)
            samples = struct.pack("<4f", .25, -.25, .5, -.5)
            (directory / "native-game-audio.f32le").write_bytes(samples)
            raw = ANALYSIS.scan_pcm(directory, 2, require_exact_length=True)
            self.assertEqual(raw["peak"], .5)
            self.assertAlmostEqual(raw["rms"], math.sqrt(.15625))
            self.assertEqual(raw["nonfinite_samples"], 0)
            (directory / "native-game-audio.f32le").unlink()
            with gzip.open(directory / "native-game-audio.f32le.gz", "wb") as stream:
                stream.write(samples + samples)
            prefix = ANALYSIS.scan_pcm(directory, 2, require_exact_length=False)
            self.assertEqual(raw["sha256"], prefix["sha256"])
            with self.assertRaisesRegex(ValueError, "beyond"):
                ANALYSIS.scan_pcm(directory, 2, require_exact_length=True)

    def test_native_nan_and_short_sample_sources_cannot_pass_as_clean_audio(self):
        with tempfile.TemporaryDirectory() as location:
            directory = Path(location)
            source = directory / "native-game-audio.f32le"
            source.write_bytes(struct.pack("<2f", float("nan"), .5))
            self.assertEqual(ANALYSIS.scan_pcm(directory, 1, require_exact_length=True)["nonfinite_samples"], 1)
            source.write_bytes(b"\x00\x00")
            with self.assertRaisesRegex(ValueError, "partial"):
                ANALYSIS.scan_pcm(directory, 1, require_exact_length=True)


if __name__ == "__main__":
    unittest.main()
