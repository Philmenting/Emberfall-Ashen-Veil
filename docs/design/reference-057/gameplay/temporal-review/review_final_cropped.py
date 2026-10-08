#!/usr/bin/env python3
"""Read-only, bounded temporal inspection of finalized ordinary captures.

Contact sheets contain H264-decoded, cropped frames at their original pixel scale.
Evade sequences retain every frame in PNG; longer hero phrases use every second
frame plus exact releases and range ends in JPEG92 4:4:4 contact sheets. Wider
context also uses explicitly sampled JPEG sheets; native original PNGs remain
the primary pixel evidence for fine details.
They are derived review aids, never original Godot PNGs or a whole-movie human review.
No Godot, Blender, game mutation, frame interpolation or image retouch is used.
"""
from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import subprocess

from PIL import Image, ImageDraw

SOURCE = "1cc13152a83c6631590d4df32ca298700a417df7"
BASELINE = "86cb1b8ec878b4ae06daba5e6c5a4fa583865dc5"
EVIDENCE = Path("/workspace/scratch/emberfall-quality-057/gameplay-final-evade")
REVIEW = Path(__file__).resolve().parent


def sha(path):
    result = hashlib.sha256()
    with Path(path).open("rb") as source:
        for block in iter(lambda: source.read(1048576), b""):
            result.update(block)
    return result.hexdigest()


def write(path, value):
    Path(path).write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")


def load(slug, side):
    folder = EVIDENCE / f"{side}-{slug}"
    receipt = json.loads((folder / "receipt.json").read_text())
    if receipt.get("status") != "complete" or receipt.get("recording_kind") != "ordinary_expedition":
        raise ValueError("Require an actually completed full ordinary expedition: " + str(folder))
    if any(receipt.get(key) != 0 for key in ("godot_process_exit", "ffmpeg_process_exit", "ffmpeg_full_decode_exit")):
        raise ValueError("A real successful native process/encoder/full decode exit is absent")
    movie = folder / receipt["mp4_file"]
    journal = folder / "frames.jsonl"
    if sha(movie) != receipt["mp4_sha256"] or sha(journal) != receipt["frame_log_sha256"]:
        raise ValueError("Finalized original movie/journal bytes changed")
    if not receipt.get("inputs_unchanged") or receipt["input_sha256_before"] != receipt["input_sha256_after"]:
        raise ValueError("Captured runtime inputs changed")
    rows = [json.loads(line) for line in journal.read_text().splitlines()]
    if len(rows) != receipt["frames"] or [row["frame"] for row in rows] != list(range(len(rows))):
        raise ValueError("Journal is not complete and consecutive")
    summary = json.loads((folder / "capture-summary.json").read_text())
    if not summary.get("complete") or not summary.get("won") or len(summary.get("recovered_loot", [])) != 2:
        raise ValueError("Actual complete victory and two recovered original loot items are required")
    for selected in receipt["selected_frames"]:
        if sha(folder / selected["file"]) != selected["sha256"]:
            raise ValueError("An original selected Godot PNG changed")
    return folder, receipt, movie, rows


def runs(rows, predicate):
    result, start = [], None
    for index, row in enumerate(rows):
        active = predicate(row)
        if active and start is None:
            start = index
        elif not active and start is not None:
            result.append([start, index - 1])
            start = None
    if start is not None:
        result.append([start, len(rows) - 1])
    return result


def audit(slug, side):
    folder, receipt, movie, rows = load(slug, side)
    attacks = []
    evades = []
    deaths = []
    for index, row in enumerate(rows):
        for event in row["events"]:
            if event["type"] == "hero_attack":
                last = index
                while last + 1 < len(rows) and rows[last + 1].get("hero_pose", {}).get("attack_time", -1) >= 0:
                    if any(e["type"] == "hero_attack" for e in rows[last + 1]["events"]):
                        break
                    last += 1
                release = [r["frame"] for r in rows[index:last + 1] if any(e["type"] == "hero_release" for e in r["events"])]
                attacks.append({"start": index, "last_attack_pose": last,
                                "first_complete_reset": min(last + 1, len(rows) - 1),
                                "style": row["hero"].get("attack_style"), "event": event,
                                "release_frames": release,
                                "recovery_relative_intervals": runs(rows[index:last + 1], lambda r: r["hero_pose"]["release_time"] >= 0)})
            if event["type"] in ("evade", "backstep"):
                last = index
                while last + 1 < len(rows) and rows[last + 1].get("hero_pose", {}).get("evade_time", -1) >= 0:
                    last += 1
                previous = rows[max(0, index - 1)]["hero_pose"]
                root_positions = [r["hero_pose"]["root"]["origin"] for r in rows[index:last + 1]]
                basis = row["hero_pose"].get("native_model", row["hero_pose"]["body"])["basis"]
                delta = [event["goal"][0] - event["position"][0], 0,
                         event["goal"][1] - event["position"][1]] if "goal" in event else [0, 0, 0]
                length = math.sqrt(sum(x * x for x in delta))
                # All observed actor bases are orthogonal uniform-scale transforms.
                native_direction = [sum(a * b for a, b in zip(column, delta)) /
                                    math.sqrt(sum(a * a for a in column)) / length
                                    if length else 0 for column in basis]
                evades.append({"start": index, "last_native_evade": last,
                               "event": event, "previous_clip": previous["clip"],
                               "previous_attack_time": previous["attack_time"],
                               "previous_release_time": previous["release_time"],
                               "native_basis_direction": native_direction,
                               "predominantly_lateral": abs(native_direction[0]) > abs(native_direction[2]),
                               "root_distance_between_observed_samples_m": sum(math.dist(a, b) for a, b in zip(root_positions, root_positions[1:])),
                               "scope": "Root and original model basis only; bone-detail-none journal cannot establish ankle overlap."})
            if event["type"] == "hit" and event.get("dead"):
                actor = next((p for p in row["actor_poses"] if p["id"] == event["target"]), None)
                deaths.append({"frame": index, "target": event["target"],
                               "kind": actor["kind"] if actor else "not_present", "event": event})
    result = {"schema": 1, "status": "complete_consecutive_journal_audit",
              "created_utc": datetime.now(timezone.utc).isoformat(),
              "character_class": slug, "side": side, "source_commit": SOURCE if side == "after" else BASELINE,
              "frames": len(rows), "movie_sha256": sha(movie),
              "journal_sha256": sha(folder / "frames.jsonl"), "receipt_sha256": sha(folder / "receipt.json"),
              "events": dict(Counter(e["type"] for r in rows for e in r["events"])),
              "hero_clip_counts": dict(Counter(r.get("hero_pose", {}).get("clip", "scene_removed_for_result_ui") for r in rows)),
              "actual_result_ui_rows_without_hero_scene": [r["frame"] for r in rows if "hero_pose" not in r],
              "attacks": attacks, "evades": evades, "death_events": deaths,
              "walk_intervals": runs(rows, lambda r: r.get("hero_pose", {}).get("clip") == "walk"),
              "human_visual_review": "pending; journal parsing is not visual acceptance",
              "review_tool_sha256": sha(__file__),
              "scope": "Actual consecutive journal. No native bone positions, GPU pixel occlusion, physical phone FPS or whole-movie human review inferred."}
    write(REVIEW / f"{slug}-{side}-journal-audit.json", result)
    return result


def plan_pair(slug):
    comparison_path = EVIDENCE / f"{slug}-comparison.json"
    comparison = json.loads(comparison_path.read_text())
    if comparison.get("status") != "verified_complete_ordinary_expedition":
        raise ValueError("Require the actual full before/after comparison")
    if comparison["current_git_source_audit"]["source_commit"] != SOURCE or comparison["baseline_git_source_audit"]["source_commit"] != BASELINE:
        raise ValueError("Comparison is bound to a different source")
    before, after = audit(slug, "before"), audit(slug, "after")
    if before["frames"] != after["frames"]:
        raise ValueError("Pair length differs")
    ranges = []

    def add(label, first, last, scope="hero_and_surrounding_scene"):
        ranges.append({"label": label, "first": max(0, first), "last": min(after["frames"] - 1, last), "crop_scope": scope})

    styles = list(dict.fromkeys(attack["style"] for attack in after["attacks"]))
    for style in styles:
        candidates = [attack for attack in after["attacks"] if attack["style"] == style]
        attack = next((attack for attack in candidates if attack["release_frames"]), candidates[0])
        # Prefer an actual released phrase, including its last recovery pose and
        # following reset. A never-released phrase is explicitly a cancellation.
        suffix = "full-released-phrase" if attack["release_frames"] else "cancelled-phrase"
        add("first-" + style + "-" + suffix, attack["start"] - 1, attack["first_complete_reset"] + 3)
    lateral = next((e for e in after["evades"] if e["predominantly_lateral"]), None)
    if lateral:
        add("first-lateral-evade", lateral["start"] - 2, lateral["last_native_evade"] + 5)
    cancel = next((e for e in after["evades"] if e["previous_attack_time"] >= 0), None)
    if cancel:
        cancelled = next((a for a in after["attacks"] if a["last_attack_pose"] == cancel["start"] - 1), None)
        first = min(cancel["start"] - 5, cancelled["start"] - 1) if cancelled else cancel["start"] - 5
        add("first-attack-to-evade", first, cancel["last_native_evade"] + 5)
    covered_evades = {e["start"] for e in (lateral, cancel) if e}
    for evade in after["evades"]:
        if evade["start"] not in covered_evades:
            cancelled = next((a for a in after["attacks"] if a["last_attack_pose"] == evade["start"] - 1), None) if evade["previous_attack_time"] >= 0 else None
            first = cancelled["start"] - 1 if cancelled else evade["start"] - 2
            add(f"additional-evade-{evade['start']}", first, evade["last_native_evade"] + 5)
    travel = next((r for r in after["walk_intervals"] if r[1] - r[0] >= 20), None)
    if travel:
        add("ordinary-travel-gait", travel[0] + 3, travel[0] + 23)
    roles = set()
    for death in after["death_events"]:
        role = death["kind"]
        if role in roles:
            continue
        roles.add(role)
        add("first-" + role + "-death", death["frame"] - 2, death["frame"] + 28, "full_viewport")
    folder, receipt, movie, rows = load(slug, "after")
    warning_roles = set()
    clean_recovery_roles = set()
    for row in rows:
        for event in row["events"]:
            if event["type"] != "warning":
                continue
            source = event["source"]
            actor = next((p for p in row.get("actor_poses", []) if p["id"] == source), None)
            role = actor["kind"] if actor else "not_present"
            role_already_sampled = role in warning_roles
            if role_already_sampled and role in clean_recovery_roles:
                continue
            impact = next((r["frame"] for r in rows[row["frame"] + 1:]
                           if any(e["type"] == "impact" and e.get("source") == source for e in r["events"])), None)
            if impact is None:
                if not role_already_sampled:
                    add("first-" + role + "-interrupted-telegraph", row["frame"] - 2, row["frame"] + 30, "full_viewport")
                    warning_roles.add(role)
                continue
            if role == "boss":
                # Inspect the complete observed phase sequence, not only its
                # first cycle. A transient idle before the final impact does
                # not terminate the visual range.
                impact = max(r["frame"] for r in rows[row["frame"]:]
                             if any(e["type"] in ("impact", "warning") and e.get("source") == source for e in r["events"]))
            reset = impact + 1
            while reset < min(len(rows), impact + 181):
                pose = next((p for p in rows[reset].get("actor_poses", []) if p["id"] == source), None)
                if not pose or (pose["attack_time"] < 0 and pose["release_time"] < 0
                                and not pose["clip"].startswith("windup")):
                    break
                reset += 1
            first = row["frame"] - 5 if role == "boss" else row["frame"] - 2
            pose = next((p for p in rows[min(reset, len(rows) - 1)].get("actor_poses", []) if p["id"] == source), None)
            clean_reset = bool(pose and pose["clip"] in ("idle", "walk"))
            if not role_already_sampled or clean_reset:
                prefix = "additional-" if role_already_sampled else "first-"
                suffix = "telegraph-release-recovery-reset" if clean_reset else "telegraph-release-interrupted-recovery"
                add(prefix + role + "-" + suffix, first, reset + 3, "full_viewport")
                warning_roles.add(role)
                if clean_reset:
                    clean_recovery_roles.add(role)
    add("original-ending-loot-ui", len(rows) - 6, len(rows) - 1, "full_viewport")
    result = {"schema": 1, "status": "planned_sampled_visual_review_not_acceptance",
              "source_commit": SOURCE, "baseline_commit": BASELINE, "character_class": slug,
              "comparison_sha256": sha(comparison_path), "ranges": ranges,
              "scope": "Every frame of these bounded ranges will be decoded. Explicitly sampled visual review, not a claim that a human watched either entire movie."}
    write(REVIEW / f"{slug}-review-plan.json", result)
    return result


def read_exact(stream, count):
    data = bytearray()
    while len(data) < count:
        block = stream.read(count - len(data))
        if not block:
            break
        data.extend(block)
    return bytes(data)


def decode_range(slug, side, label):
    plan = json.loads((REVIEW / f"{slug}-review-plan.json").read_text())
    selected = next(r for r in plan["ranges"] if r["label"] == label)
    first, last = selected["first"], selected["last"]
    folder, receipt, movie, rows = load(slug, side)
    output = REVIEW / slug / side / label
    output.mkdir(parents=True, exist_ok=False)
    width, height = int(receipt["decoded_video"]["width"]), int(receipt["decoded_video"]["height"])
    crop = [0, 0, width, height]
    if selected["crop_scope"] == "hero_and_surrounding_scene" or label != "original-ending-loot-ui":
        bounds = []
        for pair_side in ("before", "after"):
            pair_folder, pair_receipt, pair_movie, pair_rows = load(slug, pair_side)
            for row in pair_rows[first:last + 1]:
                x, y, w, h = row["hero"]["projection"]["rectangle"]
                rw, rh = row["render_viewport"]
                bounds.append((x * width / rw, y * height / rh, (x + w) * width / rw, (y + h) * height / rh))
                if selected["crop_scope"] == "full_viewport" and row.get("guardian_projection", {}).get("actor_visible"):
                    x, y, w, h = row["guardian_projection"]["rectangle"]
                    bounds.append((x * width / rw, y * height / rh, (x + w) * width / rw, (y + h) * height / rh))
        left, top = min(r[0] for r in bounds) - 45, min(r[1] for r in bounds) - 30
        right, bottom = max(r[2] for r in bounds) + 45, max(r[3] for r in bounds) + 30
        if right - left < 240:
            middle = (left + right) / 2
            left, right = middle - 120, middle + 120
        if bottom - top < 220:
            middle = (top + bottom) / 2
            top, bottom = middle - 110, middle + 110
        if selected["crop_scope"] == "full_viewport":
            middle_x, middle_y = (left + right) / 2, (top + bottom) / 2
            left, right = min(left, middle_x - 310), max(right, middle_x + 310)
            top, bottom = min(top, middle_y - 165), max(bottom, middle_y + 165)
        crop = [max(0, math.floor(left)), max(0, math.floor(top)), min(width, math.ceil(right)), min(height, math.ceil(bottom))]
    crop_w, crop_h = crop[2] - crop[0], crop[3] - crop[1]
    command = ["ffmpeg", "-hide_banner", "-loglevel", "warning", "-threads", "1", "-filter_threads", "1",
               "-i", str(movie), "-map", "0:v:0", "-an", "-vf", f"select=between(n\\,{first}\\,{last})",
               "-frames:v", str(last - first + 1), "-fps_mode", "passthrough", "-pix_fmt", "rgb24", "-f", "rawvideo", "pipe:1"]
    sheets, current, cells = [], [], []
    wider_context = selected["crop_scope"] == "full_viewport"
    consecutive_hero = "evade" in label
    exact_release_frames = {r["frame"] for r in rows[first:last + 1]
                            if any(e["type"] in ("hero_release", "impact", "warning", "boss_phase")
                                   or (e["type"] == "hit" and e.get("dead")) for e in r["events"])}
    warning_actor_ids = {e["source"] for r in rows[first:last + 1] for e in r["events"] if e["type"] == "warning"}
    for frame in range(first + 1, last + 1):
        previous = {p["id"]: p for p in rows[frame - 1].get("actor_poses", [])}
        for pose in rows[frame].get("actor_poses", []):
            if pose["id"] in warning_actor_ids and pose["id"] in previous and pose["clip"] != previous[pose["id"]]["clip"]:
                exact_release_frames.update((frame - 1, frame))
    attack_audit = json.loads((REVIEW / f"{slug}-{side}-journal-audit.json").read_text())
    for attack in attack_audit["attacks"]:
        for frame in (attack["start"], attack["last_attack_pose"], attack["first_complete_reset"]):
            if first <= frame <= last:
                exact_release_frames.add(frame)
    columns = 2 if wider_context else 4
    per_sheet = columns * (3 if wider_context else 4)

    def flush():
        if not current:
            return
        sheet = Image.new("RGB", (columns * crop_w, math.ceil(len(current) / columns) * (crop_h + 26)), "#181c20")
        draw = ImageDraw.Draw(sheet)
        for i, (frame, pixels) in enumerate(current):
            x, y = (i % columns) * crop_w, (i // columns) * (crop_h + 26)
            sheet.paste(pixels, (x, y + 26))
            origin = "H264-derived PNG" if consecutive_hero else "H264 + JPEG92"
            draw.text((x + 4, y + 5), f"{side.upper()} {slug} {origin} f{frame} / {frame / 30:.3f}s; 1:1", fill="white")
        suffix = "png" if consecutive_hero else "jpg"
        path = output / f"derived-contact-sheet-{len(sheets):02d}.{suffix}"
        if not consecutive_hero:
            sheet.save(path, quality=92, subsampling=0)
        else:
            sheet.save(path)
        sheets.append({"file": path.name, "sha256": sha(path), "bytes": path.stat().st_size,
                       "first_frame": current[0][0], "last_frame": current[-1][0], "frames": [x[0] for x in current]})
        current.clear()

    with (output / "decode.stderr.txt").open("wb") as errors:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=errors)
        try:
            for frame in range(first, last + 1):
                raw = read_exact(process.stdout, width * height * 3)
                if len(raw) != width * height * 3:
                    raise ValueError("FFmpeg returned an incomplete selected frame")
                cells.append(frame)
                stride = 4 if wider_context else 1 if consecutive_hero else 2
                if (frame - first) % stride == 0 or frame == last or frame in exact_release_frames:
                    pixels = Image.frombytes("RGB", (width, height), raw).crop(tuple(crop))
                    current.append((frame, pixels))
                    if len(current) == per_sheet:
                        flush()
            if process.stdout.read(1):
                raise ValueError("FFmpeg decoded extra frames outside the specified range")
            code = process.wait(timeout=60)
            flush()
        except BaseException:
            process.kill()
            process.wait()
            raise
    if code != 0:
        raise ValueError("Actual FFmpeg decoder process failed")
    record = {"schema": 1, "status": "complete_consecutive_h264_decoded_range",
              "character_class": slug, "side": side, "label": label,
              "source_commit": SOURCE if side == "after" else BASELINE,
              "first_frame_zero_based": first, "last_frame_zero_based_inclusive": last,
              "every_consecutive_frame_decoded": cells == list(range(first, last + 1)),
              "retained_frame_sampling": "Every fourth frame plus range end, exact hero releases/enemy impacts and hero attack/recovery/reset boundaries" if wider_context else "Every consecutive decoded frame" if consecutive_hero else "Every second frame plus range end, exact hero releases/enemy impacts and hero attack/recovery/reset boundaries",
              "exact_semantic_frames_retained": sorted(exact_release_frames),
              "actual_ffmpeg_command": command, "actual_ffmpeg_exit_code": code,
              "movie_sha256": sha(movie), "capture_receipt_sha256": sha(folder / "receipt.json"),
              "crop_xyxy": crop, "contact_sheet_pixel_scale": "1:1 original decoded pixels; shared fixed crop for this before/after range",
              "context_crop_scope": "Full viewport for original ending UI; other context ranges use a shared native-pixel crop around hero and visible Guardian with a minimum620x330 scene margin. Hero ranges keep all sampled conservative actor/weapon projection bounds plus45px horizontal/30px vertical margin and minimum240x220. Off-crop actors/environment cannot be visually judged here; original movies and native PNGs remain full viewport.",
              "image_origin": "H264-decoded lossy movie frames, lossless PNG contact sheets, cropped only with external labels. Not original Godot PNGs." if consecutive_hero else "H264-decoded lossy movie frames, JPEG92 4:4:4 contact sheets, cropped only with external labels. Not original Godot PNGs.",
              "human_visual_review": "pending; decoding alone is not visual acceptance",
              "sheets": sheets, "review_tool_sha256": sha(__file__)}
    write(output / "decode-receipt.json", record)
    print(json.dumps({"class": slug, "side": side, "label": label, "first": first, "last": last, "sheets": len(sheets), "actual_decoder_exit": code}))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=("audit", "plan", "decode"))
    parser.add_argument("character_class", choices=("arcanist", "ranger", "vowkeeper"))
    parser.add_argument("--side", choices=("before", "after"))
    parser.add_argument("--label")
    args = parser.parse_args()
    if args.operation == "audit":
        result = audit(args.character_class, args.side)
        print(json.dumps({"class": args.character_class, "side": args.side, "frames": result["frames"], "attacks": len(result["attacks"]), "evades": len(result["evades"])}))
    elif args.operation == "plan":
        result = plan_pair(args.character_class)
        print(json.dumps(result, indent=2))
    else:
        decode_range(args.character_class, args.side, args.label)


if __name__ == "__main__":
    main()
