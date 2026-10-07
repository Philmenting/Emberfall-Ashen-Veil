#!/usr/bin/env python3
"""Stream a continuous, ordinary Arcanist expedition into an MP4 and native evidence.

Godot renders its actual Main viewport. Every chronological PNG is encoded, but
only bounded selected original frames are retained on disk. Fixed 30 Hz playback
is separate from real gameplay frame pacing; capture timings include readback,
PNG encoding and transport. Root must assign the exclusive native renderer slot.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import socket
import struct
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
MAX_PNG_BYTES = 32 * 1024 * 1024


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def runtime_hashes(root: Path, additional_input_paths=()) -> dict[str, str]:
    """Hash runtime code, native models, shaders and this exact capture fixture."""
    paths = {root / "Main.tscn", root / "project.godot"}
    for relative, pattern in [
        ("scripts", "*.gd"),
        ("assets/shaders", "*"),
        ("assets/models", "*"),
    ]:
        directory = root / relative
        if directory.is_dir():
            paths.update(path for path in directory.rglob(pattern) if path.is_file()
                         and not path.name.endswith((".import", ".uid"))
                         and not path.name.startswith(("arcanist_T_", "ranger-native65_T_", "raider-native65_T_")))
    paths.update(root / "tests" / name for name in [
        "attack_gameplay_preview.gd", "arcanist_quality_gameplay_preview.gd",
        "arcanist_quality_gameplay_preview.tscn",
        "native_capture_audio.gd",
    ])
    paths.add(Path(__file__).resolve())
    paths.update(Path(path).resolve() for path in additional_input_paths)
    return {str(path.relative_to(root)): digest(path) for path in sorted(paths)
            if path.is_file() and path.is_relative_to(root)}


def receive_exact(connection: socket.socket, size: int, *, allow_eof: bool = False) -> bytes | None:
    output = bytearray()
    while len(output) < size:
        block = connection.recv(min(size - len(output), 65536))
        if not block:
            if allow_eof and not output:
                return None
            raise RuntimeError("The viewport stream ended inside a frame.")
        output.extend(block)
    return bytes(output)


def receive_png(connection: socket.socket) -> bytes | None:
    header = receive_exact(connection, 4, allow_eof=True)
    if header is None:
        return None
    size, = struct.unpack("!I", header)
    if not len(PNG_SIGNATURE) <= size <= MAX_PNG_BYTES:
        raise RuntimeError(f"Invalid PNG packet length: {size}")
    pixels = receive_exact(connection, size)
    if pixels is None or not pixels.startswith(PNG_SIGNATURE):
        raise RuntimeError("The viewport packet is not an original PNG.")
    return pixels


def verify_record(record: dict, frame: int, previous_clock: float) -> float:
    if record.get("frame") != frame:
        raise RuntimeError("The viewport sequence and chronological frame log diverged")
    clock = float(record["simulation_elapsed"]) + float(record["simulation_accumulator"])
    expected = previous_clock + (1 / 30 if record["simulation_advanced"] else 0)
    if not math.isfinite(clock) or not math.isclose(clock, expected, abs_tol=0.0001):
        raise RuntimeError("The chronological simulation contains an elapsed-time jump or an unrecorded step")
    if not math.isclose(float(record["playback_seconds"]), frame / 30, abs_tol=0.0001):
        raise RuntimeError("The viewport playback clock is not a continuous 30 Hz sequence")
    return clock


def verify_audio_record(record: dict, frame: int, previous_sample: int, sample_rate: int | None) -> tuple[int, int]:
    audio = record["audio"]
    rate = int(audio["sample_rate"])
    if rate <= 0 or audio["channels"] != 2 or sample_rate not in (None, rate):
        raise RuntimeError("The native PCM rate/channels changed during capture")
    expected_end = (frame + 1) * rate // 30
    if audio["first_sample_frame"] != previous_sample or audio["end_sample_frame"] != expected_end:
        raise RuntimeError("Native PCM has missing/overlapping samples or diverges from the video clock")
    for event in audio["accepted_state_events"]:
        if event["sample_frame"] != previous_sample:
            raise RuntimeError("An accepted cue/state event is outside its recorded sample boundary")
    return expected_end, rate


def write_all(stream, payload: bytes) -> None:
    remaining = memoryview(payload)
    while remaining:
        written = stream.write(remaining)
        if written is None or written <= 0:
            raise RuntimeError("The encoder stopped accepting original PNG bytes")
        remaining = remaining[written:]


def selected_reasons(record: dict, selected: set[str], *, combat_prefix: bool = False) -> list[str]:
    reasons = []
    index = record["frame"]
    if index == 0:
        reasons.append("ordinary-start")
    if index % 300 == 0:
        reasons.append(f"chronological-{index // 30:03d}s")
    hero = record.get("hero", {})
    if hero.get("attack_time", -1) >= 0:
        reason = "first-windup-" + hero.get("attack_style", "unknown")
        if reason not in selected:
            reasons.append(reason)
    if hero.get("release_time", -1) >= 0:
        reason = "first-release-" + hero.get("attack_style", "unknown")
        if reason not in selected:
            reasons.append(reason)
    if record.get("stage") == 5 and record.get("phase") == "combat":
        if "first-guardian-combat" not in selected:
            reasons.append("first-guardian-combat")
        guardian = record.get("guardian", {})
        if guardian.get("warning") and "first-guardian-warning" not in selected:
            reasons.append("first-guardian-warning")
        reason = "first-guardian-phase-" + str(guardian.get("boss_phase", 0))
        if reason not in selected:
            reasons.append(reason)
    if record.get("finished") and "expedition-finished" not in selected:
        reasons.append("expedition-finished")
    if combat_prefix:
        reasons.extend(record.get("prefix_pose_markers", []))
        for key, ages in (("prefix_first_hit_age", (0, 4, 8)),
                          ("prefix_first_evade_age", (0, 3, 6, 9, 12, 15))):
            age = record.get(key, -1)
            if age in ages:
                reasons.append(key.removeprefix("prefix_") + f"-offset-{age:02d}")
    return reasons


def verify_prefix_summary(summary: dict, seconds: int, received_frames: int) -> None:
    """A verified prefix is complete as a recording, never as an expedition."""
    expected = seconds * 30
    if received_frames != expected or summary.get("frames") != expected:
        raise RuntimeError("The ordinary prefix did not record its exact requested frame count")
    if any(summary.get(key) is not False for key in ("complete", "simulation_finished", "won")):
        raise RuntimeError("A first-dungeon prefix must not be labeled as a completed/won expedition")
    if summary.get("settle_frames_recorded") != 0:
        raise RuntimeError("An ordinary prefix must contain advancing gameplay without result settling")


def write_json(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, indent=2) + "\n")


def main(argv=None, *, additional_input_paths=()) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="Fresh evidence directory; existing files are never overwritten")
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--godot", default=os.getenv("GODOT_BIN") or shutil.which("godot"))
    parser.add_argument("--ffmpeg", default=shutil.which("ffmpeg"))
    parser.add_argument("--display", default=":107")
    parser.add_argument("--max-simulation-seconds", type=float, default=240.0,
                        help="Use a smaller limit only for a transport/fixture probe; incomplete recordings are labeled")
    parser.add_argument("--prefix-seconds", type=int, choices=range(20, 31),
                        help="Record an exact ordinary 20–30 second expedition prefix, explicitly unfinished")
    parser.add_argument("--timeout-seconds", type=float, default=7200.0,
                        help="Whole capture wall-clock deadline; software rendering can be much slower than playback")
    parser.add_argument("--exclusive-render-slot", action="store_true",
                        help="Confirm root has assigned this run the only Godot/Blender render slot")
    args = parser.parse_args(argv)
    if not args.godot or not args.ffmpeg:
        parser.error("Godot and ffmpeg executables are required")
    if not args.exclusive_render_slot:
        parser.error("Coordinate the native renderer slot, then pass --exclusive-render-slot")
    if not 0 < args.max_simulation_seconds <= 240 or args.timeout_seconds <= 0:
        parser.error("Simulation limit must be in (0, 240] and the wall-clock timeout positive")
    if args.prefix_seconds is not None and args.max_simulation_seconds != 240.0:
        parser.error("Use either --prefix-seconds or a non-default --max-simulation-seconds probe")
    simulation_limit = args.prefix_seconds or args.max_simulation_seconds
    prefix = args.prefix_seconds is not None
    movie_name = f"ordinary-arcanist-first{args.prefix_seconds}s.mp4" if prefix else "ordinary-arcanist-complete.mp4"
    fixture = "combat_quality_gameplay_preview" if prefix else "arcanist_quality_gameplay_preview"
    output = args.output.resolve()
    root = args.root.resolve()
    fixture_inputs = tuple(additional_input_paths)
    if prefix:
        fixture_inputs += (root / "tests" / (fixture + ".gd"), root / "tests" / (fixture + ".tscn"))
    if output.exists() and any(output.iterdir()):
        parser.error("Use a fresh output directory; existing evidence is never overwritten")
    output.mkdir(parents=True, exist_ok=True)
    (output / "selected-frames").mkdir()
    started = time.monotonic()
    before = runtime_hashes(root, fixture_inputs)
    receipt = {
        "schema": 1, "status": "running", "input_sha256_before": before,
        "scope": "Original continuous native viewport export at fixed 30 Hz simulation/playback; capture wall time is not a game FPS benchmark.",
        "physical_device_performance": False, "captured_audio": True,
        "portrait_clock_scope": "Original HeroArt updates follow the recorded playback clock rather than viewport-export wall time.",
        "audio_scope": "Actual accepted game cues/music, decoded with native AudioStreamPlayback and fixed-step mixed into stereo PCM; not live hardware loopback. MP4 audio is AAC encoded from this PCM.",
        "pixel_changes": "None in selected native PNGs; all chronological PNGs are H.264 encoded into the MP4.",
        "maximum_simulation_seconds": simulation_limit,
        "recording_kind": "ordinary_expedition_prefix" if prefix else "ordinary_expedition",
        "mp4_file": movie_name,
    }
    if prefix:
        receipt.update(prefix_seconds=args.prefix_seconds, prefix_frames=args.prefix_seconds * 30,
                       prefix_scope="Exact chronological start of the ordinary expedition; no completion, victory, guardian or whole-dungeon claim.")
    write_json(output / "receipt.json", receipt)
    process = encoder = None
    connection = record_file = None
    frame_count = 0
    selected = set()
    selected_frames = []
    frame_size = None
    simulation_clock = 0.0
    audio_sample_frames = 0
    audio_sample_rate = None
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener, \
                (output / "godot.log").open("wb") as engine_log, \
                (output / "ffmpeg.log").open("wb") as encode_log:
            listener.bind(("127.0.0.1", 0))
            listener.listen(1)
            listener.settimeout(0.5)
            port = listener.getsockname()[1]
            command = [args.godot, "--path", str(root), "--audio-driver", "Dummy",
                       "--resolution", "1200x536", "res://tests/" + fixture + ".tscn",
                       "--", "--capture-dir=" + str(output), "--stream-port=" + str(port),
                       "--max-simulation-seconds=" + str(simulation_limit)]
            xdg = output / "xdg"
            environment = os.environ.copy()
            environment.update(DISPLAY=args.display, XDG_DATA_HOME=str(xdg / "data"),
                               XDG_CONFIG_HOME=str(xdg / "config"), XDG_CACHE_HOME=str(xdg / "cache"))
            receipt["godot_command"] = command
            receipt["display"] = args.display
            write_json(output / "receipt.json", receipt)
            process = subprocess.Popen(command, cwd=root, env=environment, stdin=subprocess.DEVNULL,
                                       stdout=engine_log, stderr=subprocess.STDOUT)
            print("CAPTURE START", process.pid, output, flush=True)
            while connection is None:
                if process.poll() is not None:
                    raise RuntimeError("Godot exited before connecting; inspect godot.log")
                if time.monotonic() - started > min(args.timeout_seconds, 120):
                    raise RuntimeError("Godot did not connect within the startup deadline")
                try:
                    connection, _ = listener.accept()
                except socket.timeout:
                    pass
            connection.settimeout(120)
            encoder_command = [args.ffmpeg, "-hide_banner", "-loglevel", "warning", "-f", "image2pipe",
                               "-framerate", "30", "-vcodec", "png", "-i", "pipe:0", "-an",
                               "-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-threads", "2",
                               "-pix_fmt", "yuv420p", "-movflags", "+faststart",
                               str(output / "viewport-video-only.mp4")]
            receipt["ffmpeg_command"] = encoder_command
            encoder = subprocess.Popen(encoder_command, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL,
                                       stderr=encode_log, bufsize=0)
            while True:
                if time.monotonic() - started > args.timeout_seconds:
                    raise RuntimeError("The whole capture exceeded its wall-clock deadline")
                pixels = receive_png(connection)
                if pixels is None:
                    break
                if record_file is None:
                    record_file = (output / "frames.jsonl").open()
                line = record_file.readline()
                if not line:
                    raise RuntimeError("A viewport frame has no flushed chronological metadata")
                record = json.loads(line)
                simulation_clock = verify_record(record, frame_count, simulation_clock)
                audio_sample_frames, audio_sample_rate = verify_audio_record(
                    record, frame_count, audio_sample_frames, audio_sample_rate)
                dimensions = struct.unpack("!II", pixels[16:24])
                if frame_size is None:
                    frame_size = dimensions
                if dimensions != frame_size or dimensions != (1200, 536):
                    raise RuntimeError(f"Unexpected or changing viewport dimensions: {dimensions}")
                reasons = selected_reasons(record, selected, combat_prefix=prefix)
                if reasons:
                    if len(selected_frames) >= 64:
                        raise RuntimeError("The selected-frame evidence exceeded its bounded size")
                    filename = f"frame-{frame_count:05d}.png"
                    path = output / "selected-frames" / filename
                    path.write_bytes(pixels)
                    selected_frames.append({"file": "selected-frames/" + filename,
                                            "frame": frame_count, "simulation_elapsed": record["simulation_elapsed"],
                                            "reasons": reasons, "sha256": digest(path)})
                    selected.update(reasons)
                if encoder.poll() is not None or encoder.stdin is None:
                    raise RuntimeError("ffmpeg exited before the viewport stream ended")
                write_all(encoder.stdin, pixels)
                connection.sendall(b"\x06")
                frame_count += 1
                if frame_count % 300 == 0:
                    print("CAPTURE", frame_count, "frames;", round(frame_count / 30, 1),
                          "playback seconds;", round(time.monotonic() - started, 1), "wall seconds", flush=True)
            if encoder.stdin is not None:
                encoder.stdin.close()
            encoder_code = encoder.wait(timeout=120)
            engine_code = process.wait(timeout=30)
            if encoder_code or engine_code:
                raise RuntimeError(f"Native process or encoder failed: godot={engine_code}, ffmpeg={encoder_code}")
        summary = json.loads((output / "capture-summary.json").read_text())
        if summary.get("frames") != frame_count or frame_count == 0:
            raise RuntimeError("The final simulation summary does not match the encoded frame count")
        if prefix:
            verify_prefix_summary(summary, args.prefix_seconds, frame_count)
        native_pcm = output / "native-game-audio.f32le"
        audio_summary = summary["audio"]
        if (native_pcm.stat().st_size != audio_sample_frames * 2 * 4
                or audio_summary["sample_frames"] != audio_sample_frames
                or audio_summary["sample_rate"] != audio_sample_rate
                or not audio_summary["finite"] or not 0 < audio_summary["peak"] <= 1
                or audio_summary["accepted_cues"] <= 0
                or digest(native_pcm) != summary["native_pcm_sha256"]):
            raise RuntimeError("The actual native PCM evidence has invalid length, mix state or provenance")
        with (output / "ffmpeg-mux.log").open("wb") as mux_log:
            mux_command = [args.ffmpeg, "-hide_banner", "-loglevel", "warning",
                           "-i", str(output / "viewport-video-only.mp4"),
                           "-f", "f32le", "-ar", str(audio_sample_rate), "-ac", "2",
                           "-i", str(native_pcm), "-map", "0:v:0", "-map", "1:a:0",
                           "-c:v", "copy", "-c:a", "aac", "-b:a", "128k",
                           "-movflags", "+faststart", str(output / movie_name)]
            receipt["ffmpeg_audio_mux_command"] = mux_command
            subprocess.run(mux_command, check=True, stdout=subprocess.DEVNULL, stderr=mux_log, timeout=120)
        after = runtime_hashes(root, fixture_inputs)
        receipt["input_sha256_after"] = after
        receipt["inputs_unchanged"] = before == after
        if before != after:
            raise RuntimeError("Runtime inputs changed during capture; preserve this attempt as invalid evidence")
        if not prefix and args.max_simulation_seconds == 240 and not summary.get("complete"):
            raise RuntimeError("The full-duration recording ended before the actual expedition and settling completed")
        errors = (output / "godot.log").read_text(errors="replace")
        if any(marker in errors for marker in ["SCRIPT ERROR", "\nERROR:", "CAPTURE_FAIL"]):
            raise RuntimeError("Godot reported a capture/runtime error; inspect godot.log")
        probe_command = ["ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0",
                         "-show_entries", "stream=width,height,nb_read_frames,r_frame_rate,duration",
                         "-of", "json", str(output / movie_name)]
        probe = subprocess.run(probe_command, check=True, capture_output=True, text=True, timeout=120)
        video = json.loads(probe.stdout)["streams"][0]
        if int(video["nb_read_frames"]) != frame_count or video["r_frame_rate"] != "30/1":
            raise RuntimeError("Decoded MP4 chronology does not match the original viewport frames")
        audio_probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0",
                                     "-show_entries", "stream=codec_name,sample_rate,channels,duration",
                                     "-of", "json", str(output / movie_name)],
                                    check=True, capture_output=True, text=True, timeout=120)
        encoded_audio = json.loads(audio_probe.stdout)["streams"]
        expected_audio_seconds = audio_sample_frames / audio_sample_rate
        if (len(encoded_audio) != 1 or encoded_audio[0]["codec_name"] != "aac"
                or int(encoded_audio[0]["sample_rate"]) != audio_sample_rate
                or encoded_audio[0]["channels"] != 2
                or not math.isclose(float(encoded_audio[0]["duration"]), expected_audio_seconds, abs_tol=0.001)
                or not math.isclose(float(video["duration"]), expected_audio_seconds, abs_tol=0.001)):
            raise RuntimeError("Muxed audio/video streams do not match the actual native PCM duration")
        decode = subprocess.run([args.ffmpeg, "-v", "error", "-i", str(output / movie_name),
                                 "-f", "null", "-"], capture_output=True, text=True, timeout=120)
        if decode.returncode or decode.stderr.strip():
            raise RuntimeError("The complete MP4 failed native decode verification")
        receipt.update(status="complete_prefix" if prefix else "complete" if summary["complete"] else "incomplete_probe",
                       frames=frame_count, wall_seconds=round(time.monotonic() - started, 3),
                       simulation_summary=summary, selected_frames=selected_frames, decoded_video=video,
                       full_decode_passed=True, mp4_sha256=digest(output / movie_name),
                       frame_log_sha256=digest(output / "frames.jsonl"), continuous_simulation_verified=True)
        receipt.update(native_audio=audio_summary, native_pcm_sha256=digest(native_pcm),
                       encoded_audio=encoded_audio[0], continuous_audio_samples_verified=True)
        write_json(output / "receipt.json", receipt)
        (output / "viewport-video-only.mp4").unlink()
        print("CAPTURE VERIFIED", receipt["status"], frame_count, "chronological frames;", output, flush=True)
        return 0
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.SubprocessError) as error:
        receipt.update(status="failed", error=str(error), frames_received=frame_count,
                       wall_seconds=round(time.monotonic() - started, 3))
        write_json(output / "receipt.json", receipt)
        print("CAPTURE FAILED:", error, file=sys.stderr)
        return 1
    finally:
        if connection is not None:
            connection.close()
        if record_file is not None:
            record_file.close()
        for child in [process, encoder]:
            if child is not None and child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait(timeout=10)


if __name__ == "__main__":
    raise SystemExit(main())
