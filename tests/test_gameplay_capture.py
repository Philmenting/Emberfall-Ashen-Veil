"""Reject lost samples, video clock drift and misplaced accepted-cue evidence."""
import importlib.util
from pathlib import Path
import unittest

MODULE_PATH = Path(__file__).resolve().parents[1] / "tools" / "capture_arcanist_quality.py"
SPEC = importlib.util.spec_from_file_location("capture_arcanist_quality", MODULE_PATH)
CAPTURE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CAPTURE)


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


if __name__ == "__main__":
    unittest.main()
