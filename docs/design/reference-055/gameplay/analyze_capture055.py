#!/usr/bin/env python3
"""Read completed native capture evidence; never edit game sources or infer art acceptance.

Example:
  python3 analyze_capture055.py /scratch/.../after-complete \
    --source-commit SHA --output /scratch/.../after-analysis.json
Use repeated --allow-overlay PATH for explicitly disclosed baseline instrumentation.
"""
from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import sys

REPO = Path('/workspace/Emberfall-Ashen-Veil')
SCRATCH = Path('/workspace/scratch/emberfall-quality-055')


def sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False)


def clock(row):
    return float(row['simulation_elapsed']) + float(row['simulation_accumulator'])


def at(row):
    return {'frame': row['frame'], 'simulation_seconds': row['simulation_elapsed'],
            'simulation_clock_seconds': clock(row), 'playback_seconds': row['playback_seconds']}


def event_at(row, event):
    return {**at(row), 'event': event}


def style(event):
    return event.get('ability_id') or ('signature' if event.get('skill', False) else 'basic')


def camera_delta(first, second):
    position = math.dist(first['origin'], second['origin'])
    basis = max(abs(a - b) for x, y in zip(first['basis'], second['basis']) for a, b in zip(x, y))
    return position, basis


def camera_analysis(rows):
    rows = [row for row in rows if 'camera' in row]
    if not rows:
        return {'camera_records': 0}
    signatures = [canonical(row['camera']) for row in rows]
    tail = len(rows) - 1
    while tail > 0 and signatures[tail - 1] == signatures[-1]:
        tail -= 1
    longest = run = 1
    changed = 0
    peak_position = peak_basis = 0.0
    for index in range(1, len(rows)):
        if signatures[index] == signatures[index - 1]:
            run += 1
        else:
            changed += 1
            run = 1
        longest = max(longest, run)
        position, basis = camera_delta(rows[index - 1]['camera'], rows[index]['camera'])
        peak_position = max(peak_position, position)
        peak_basis = max(peak_basis, basis)
    still = rows[tail:]
    return {'camera_records': len(rows), 'consecutive_transform_changes': changed,
            'longest_exact_constant_run_frames': longest,
            'maximum_consecutive_origin_delta_m': peak_position,
            'maximum_consecutive_basis_component_delta': peak_basis,
            'terminal_exact_static_tail': {'first': at(still[0]), 'last': at(still[-1]),
                'frames': len(still), 'camera': still[-1]['camera'],
                'event_counts': dict(Counter(event['type'] for row in still for event in row['events'])),
                'frames_with_guardian_warning': sum(bool(row.get('guardian', {}).get('warning')) for row in still)},
            'scope': 'Exact logged camera transforms during combat; room-entry settling may move. No rendered-pixel or visual-quality inference.'}


def commit_audit(repo, commit, inputs, overlays):
    if not commit:
        return {'status': 'not_requested', 'claimed_source_commit': None}
    if not re.fullmatch(r'[0-9a-f]{40}', commit):
        raise ValueError('--source-commit must be an exact 40-character lowercase Git SHA')
    subprocess.run(['git', 'cat-file', '-e', commit + '^{commit}'], cwd=repo, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    matching, mismatches = [], []
    for relative, expected in sorted(inputs.items()):
        if '\n' in relative or '\r' in relative:
            raise ValueError('Unexpected newline in an input source path')
        process = subprocess.Popen(['git', 'show', commit + ':' + relative], cwd=repo,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        digest = hashlib.sha256()
        for block in iter(lambda: process.stdout.read(1024 * 1024), b''):
            digest.update(block)
        error = process.stderr.read().decode(errors='replace')
        code = process.wait()
        actual = digest.hexdigest() if code == 0 else None
        if actual == expected:
            matching.append(relative)
        else:
            mismatches.append({'path': relative, 'captured_sha256': expected, 'git_sha256': actual,
                               'explicit_overlay': relative in overlays,
                               'git_error': error[-400:] if code else None})
    unallowed = [row for row in mismatches if not row['explicit_overlay']]
    return {'status': 'matched' if not mismatches else 'matched_with_disclosed_overlays' if not unallowed else 'mismatch',
            'claimed_source_commit': commit, 'matching_files': len(matching), 'compared_files': len(inputs),
            'disclosed_overlay_allowlist': sorted(overlays), 'differences': mismatches,
            'unallowed_differences': len(unallowed),
            'scope': 'SHA256 of exact Git blob bytes versus the immutable capture receipt; allowed instrumentation differences remain explicitly listed.'}


def analyze(directory, args):
    receipt = json.loads((directory / 'receipt.json').read_text())
    valid_status = ('complete', 'incomplete_probe') if args.allow_incomplete_probe else ('complete',)
    if receipt.get('status') not in valid_status:
        raise ValueError('Capture is not completed/verified: status=' + str(receipt.get('status')))
    metadata = json.loads((directory / 'capture-metadata.json').read_text())
    summary = json.loads((directory / 'capture-summary.json').read_text())
    fps = int(metadata['playback_fps'])
    rows = [json.loads(line) for line in (directory / 'frames.jsonl').read_text().splitlines() if line.strip()]
    if not rows or len(rows) != receipt['frames'] or len(rows) != summary['frames']:
        raise ValueError('Frame count differs between JSONL, final receipt and summary')
    previous_clock, previous_sample, sample_rate = 0.0, 0, None
    events, audio_events, casts = [], [], []
    active_cast = None
    authority_trace = hashlib.sha256()
    for index, row in enumerate(rows):
        if row['frame'] != index or not math.isclose(row['playback_seconds'], index / fps, abs_tol=.0001):
            raise ValueError('Dropped/reordered viewport frame or playback-time discontinuity')
        expected = previous_clock + (1 / fps if row['simulation_advanced'] else 0)
        if not math.isfinite(clock(row)) or not math.isclose(clock(row), expected, abs_tol=.0001):
            raise ValueError('Simulation clock jumps at frame ' + str(index))
        previous_clock = clock(row)
        audio = row.get('audio')
        if audio:
            rate = int(audio['sample_rate'])
            end = (index + 1) * rate // fps
            if rate <= 0 or sample_rate not in (None, rate) or audio['channels'] != 2:
                raise ValueError('Native PCM rate/channels changed')
            if audio['first_sample_frame'] != previous_sample or audio['end_sample_frame'] != end:
                raise ValueError('Missing/overlapping native PCM samples at frame ' + str(index))
            sample_rate = rate
            for event in audio['accepted_state_events']:
                if event['sample_frame'] != previous_sample:
                    raise ValueError('Audio event lies outside its logged frame boundary')
                if event['type'] == 'effect_eof':
                    silence = event['silence_from_sample_frame']
                    if not previous_sample <= silence <= end or event['valid_frames'] + event['zero_tail_frames'] != end - previous_sample:
                        raise ValueError('Native EOF/zero-tail witness does not match its PCM block')
                audio_events.append({**at(row), 'event': event})
            previous_sample = end
        elif sample_rate is not None:
            raise ValueError('An audio-bearing recording lost its per-frame PCM evidence')
        for event in row['events']:
            entry = event_at(row, event)
            events.append(entry)
            if event['type'] == 'hero_attack':
                if active_cast and 'release' not in active_cast and 'cancel' not in active_cast:
                    active_cast['unresolved_end'] = {'reason': 'next_commit_without_release_or_cancel', **at(row)}
                active_cast = {'style': style(event), 'commit': entry, 'hit_events': []}
                casts.append(active_cast)
            elif event['type'] == 'hero_release':
                if active_cast and 'release' not in active_cast and 'cancel' not in active_cast:
                    active_cast['release'] = entry
                    active_cast['release_classification_matches_commit'] = style(event) == active_cast['style']
                else:
                    casts.append({'style': style(event), 'orphan_release': entry})
            elif event['type'] in ('evade', 'backstep'):
                if active_cast and 'release' not in active_cast and 'cancel' not in active_cast:
                    active_cast['cancel'] = entry
            elif event['type'] == 'hit' and active_cast and 'release' in active_cast:
                active_cast['hit_events'].append(entry)
        # hero_release is presentation-only; omit visual poses and camera from
        # this digest so independent before/after simulation traces can compare.
        trace = {key: row[key] for key in ('frame', 'simulation_elapsed', 'simulation_accumulator',
                 'stage', 'phase', 'finished', 'won', 'hero_hp', 'pending_attack', 'guardian')}
        trace['authoritative_events'] = [event for event in row['events'] if event['type'] != 'hero_release']
        authority_trace.update((canonical(trace) + '\n').encode())
    if active_cast and 'release' not in active_cast and 'cancel' not in active_cast:
        active_cast['unresolved_end'] = {'reason': 'capture_end', **at(rows[-1])}
    frame_path = directory / 'frames.jsonl'
    if receipt.get('frame_log_sha256') != sha256(frame_path):
        raise ValueError('Chronological frame-log digest differs from final receipt')
    mp4 = directory / 'ordinary-arcanist-complete.mp4'
    if receipt.get('mp4_sha256') != sha256(mp4):
        raise ValueError('Encoded MP4 digest differs from final receipt')
    inputs_before, inputs_after = receipt['input_sha256_before'], receipt['input_sha256_after']
    if inputs_before != inputs_after or not receipt.get('inputs_unchanged'):
        raise ValueError('Source inputs changed during recording')
    selected_verified = []
    for image in receipt.get('selected_frames', []):
        path = (directory / image['file']).resolve()
        if not path.is_relative_to(directory) or sha256(path) != image['sha256']:
            raise ValueError('Selected original PNG path/digest differs from receipt')
        selected_verified.append(image['file'])
    stations = []
    for stage in range(6):
        stage_rows = [row for row in rows if row['stage'] == stage]
        combat = [row for row in stage_rows if row['phase'] == 'combat' and not row['finished']]
        stations.append({'station': stage + 1, 'stage': stage, 'frames': len(stage_rows),
            'first': at(stage_rows[0]) if stage_rows else None, 'last': at(stage_rows[-1]) if stage_rows else None,
            'phase_frame_counts': dict(Counter(row['phase'] for row in stage_rows)),
            'actual_event_counts': dict(Counter(event['type'] for row in stage_rows for event in row['events'])),
            'combat_first': at(combat[0]) if combat else None, 'combat_last': at(combat[-1]) if combat else None,
            'combat_camera': camera_analysis(combat)})
    phrases = {}
    for phrase in ('basic', 'skill', 'heavy'):
        windup = [row for row in rows if row.get('hero', {}).get('clip') == 'windup_' + phrase]
        recovery = [row for row in rows if row.get('hero', {}).get('clip') == 'recover_' + phrase]
        phrases[phrase] = {'windup_frames': len(windup), 'recovery_frames': len(recovery),
                          'first_windup': at(windup[0]) if windup else None,
                          'first_recovery': at(recovery[0]) if recovery else None,
                          'actual_style_frame_counts': dict(Counter(row['hero']['attack_style'] for row in windup + recovery))}
    guardian = [row for row in rows if row['stage'] == 5 and row['phase'] == 'combat' and not row['finished']]
    dead = [entry for entry in events if entry['event']['type'] == 'hit'
            and entry['event'].get('target') == 50 and entry['event'].get('dead')]
    result = [row for row in rows if row['page'] == 'loot']
    finished = [row for row in rows if row['finished']]
    projection = [row['hero']['projection'] for row in rows if 'hero' in row]
    cue_events = [entry for entry in audio_events if entry['event']['type'] == 'cue']
    native_audio = None
    if sample_rate is not None:
        pcm = directory / 'native-game-audio.f32le'
        actual_digest = sha256(pcm)
        if pcm.stat().st_size != previous_sample * 8 or summary['audio']['sample_frames'] != previous_sample:
            raise ValueError('Native PCM sample length differs from recorded frame spans')
        if summary['native_pcm_sha256'] != actual_digest or receipt.get('native_pcm_sha256') != actual_digest:
            raise ValueError('Native PCM digest differs from summary/final receipt')
        if summary['audio']['accepted_cues'] != len(cue_events):
            raise ValueError('Accepted cue count differs from native mixer summary')
        native_audio = {'sample_rate': sample_rate, 'sample_frames': previous_sample,
            'seconds': previous_sample / sample_rate, 'channels': 2, 'sample_format': 'f32le',
            'native_pcm_sha256': actual_digest, 'encoded_audio': receipt.get('encoded_audio'),
            'mix_summary': summary['audio'], 'event_counts': dict(Counter(entry['event']['type'] for entry in audio_events)),
            'accepted_cue_counts': dict(Counter(entry['event']['key'] for entry in cue_events)),
            'first_accepted_cue': cue_events[0] if cue_events else None,
            'last_accepted_cue': cue_events[-1] if cue_events else None,
            'stolen_cues': [entry for entry in cue_events if entry['event'].get('replaced_key')],
            'context_and_state_changes': [entry for entry in audio_events if entry['event']['type'] in ('context', 'state')],
            'effect_eof_witnesses': [entry for entry in audio_events if entry['event']['type'] == 'effect_eof'],
            'accepted_cue_timeline': cue_events,
            'scope': metadata.get('audio_scope'), 'cue_clock_scope': metadata.get('audio_clock_scope')}
    report = {'schema': 1, 'created_utc': datetime.now(timezone.utc).isoformat(),
        'capture_directory': str(directory), 'capture_receipt_sha256': sha256(directory / 'receipt.json'),
        'helper_sha256': sha256(Path(__file__)),
        'recording': {'status': receipt['status'], 'frames': len(rows), 'fps': fps, 'playback_seconds': len(rows) / fps,
            'simulation_seconds': summary['simulation_elapsed'], 'advancing_frames': sum(row['simulation_advanced'] for row in rows),
            'ending_settle_frames': summary['settle_frames_recorded'], 'chronology_verified': True,
            'source_inputs_unchanged': True, 'selected_original_pngs_verified': selected_verified,
            'mp4_sha256': receipt['mp4_sha256'], 'frame_log_sha256': receipt['frame_log_sha256'],
            'decoded_video': receipt.get('decoded_video'), 'full_decode_reported_by_launcher': receipt.get('full_decode_passed'),
            'physical_device_performance': metadata.get('physical_device_performance'),
            'engine': metadata.get('engine_version'), 'renderer': metadata['renderer'],
            'video_adapter': metadata.get('video_adapter'), 'viewport': metadata['viewport']},
        'setup': {key: metadata.get(key) for key in ('world_seed', 'run_seed', 'initial_stats',
            'selected_skill_loadout', 'loadout_scope', 'scope')},
        'six_stations': stations, 'attack_phrases': phrases, 'cast_timeline': casts,
        'cast_counts': {'commits': sum('commit' in cast for cast in casts),
            'released': sum('release' in cast for cast in casts), 'cancelled_before_release': sum('cancel' in cast for cast in casts),
            'orphan_releases': sum('orphan_release' in cast for cast in casts),
            'unresolved': sum('unresolved_end' in cast for cast in casts),
            'by_style': dict(Counter(cast['style'] for cast in casts if 'commit' in cast))},
        'actual_event_counts': dict(Counter(entry['event']['type'] for entry in events)),
        'authoritative_frame_trace_sha256': authority_trace.hexdigest(),
        'authoritative_trace_scope': 'Frame clocks/stage/phase/outcome/HP/pending attack/guardian and all events except presentation-only hero_release; excludes camera and visual poses.',
        'guardian': {'first_combat': at(guardian[0]) if guardian else None,
            'last_combat': at(guardian[-1]) if guardian else None, 'actual_death': dead,
            'phase_events': [entry for entry in events if entry['event']['type'] == 'boss_phase'],
            'warning_events': [entry for entry in events if entry['event']['type'] == 'warning' and entry['event'].get('source') == 50],
            'actual_received_hits': [entry for entry in events if entry['event']['type'] == 'hero_hit' and entry['event'].get('source') == 50],
            'combat_camera': camera_analysis(guardian)},
        'outcome': {'complete': summary['complete'], 'won': summary['won'],
            'simulation_finished': summary['simulation_finished'], 'final_hero_hp': rows[-1]['hero_hp'],
            'minimum_recorded_hero_hp': min(row['hero_hp'] for row in rows),
            'initial_maximum_hp': metadata['initial_stats']['max_hp'],
            'first_finished': at(finished[0]) if finished else None,
            'result_ui_reached': bool(result), 'first_result_ui': at(result[0]) if result else None,
            'result_ui_frames': len(result), 'last_frame': at(rows[-1]),
            'scope': 'Logged outcome and page state; actual result-image appearance requires inspection.'},
        'conservative_projection': {'hero_records': len(projection),
            'outside_viewport_records': sum(not item['fully_inside_viewport'] for item in projection),
            'nonintersecting_records': sum(not item['viewport_intersection'] for item in projection),
            'behind_camera_records': sum(item['corners_behind_camera'] > 0 for item in projection),
            'invisible_actor_records': sum(not item['actor_visible'] for item in projection),
            'skeleton_bone_inventory': sorted(set(row['hero']['skeleton_bones'] for row in rows if 'hero' in row)),
            'scope': metadata['projection_scope']},
        'audio': native_audio,
        'source_commit_audit': commit_audit(args.repo, args.source_commit, inputs_before, set(args.allow_overlay)),
        'source_input_sha256_before': inputs_before, 'source_input_sha256_after': inputs_after,
        'limitations': ['Counts and conservative bounds do not certify visual acceptance or pixel occlusion.',
            'Fixed-step PCM uses native decoders, not hardware audio loopback or real-time callback recording.',
            'Capture wall time includes rendering/readback/PNG/transport and is not game FPS.',
            'Source differences allowed as instrumentation overlays are disclosed, never silently treated as original baseline code.']}
    return report


def compare(first, second):
    a, b = first['setup'], second['setup']
    same = {key: a[key] == b[key] for key in ('world_seed', 'run_seed', 'initial_stats', 'selected_skill_loadout')}
    changed = sorted(path for path in set(first['source_input_sha256_before']) | set(second['source_input_sha256_before'])
                     if first['source_input_sha256_before'].get(path) != second['source_input_sha256_before'].get(path))
    return {'setup_equal': same,
        'authoritative_frame_trace_identical': first['authoritative_frame_trace_sha256'] == second['authoritative_frame_trace_sha256'],
        'before_recording': first['recording'], 'after_recording': second['recording'],
        'before_outcome': first['outcome'], 'after_outcome': second['outcome'],
        'before_cast_counts': first['cast_counts'], 'after_cast_counts': second['cast_counts'],
        'before_guardian_camera': first['guardian']['combat_camera'], 'after_guardian_camera': second['guardian']['combat_camera'],
        'changed_capture_source_paths': changed,
        'audio_stream_pcm_identical': first['audio']['mix_summary']['stream_pcm_sha256'] == second['audio']['mix_summary']['stream_pcm_sha256']
            if first['audio'] and second['audio'] else None,
        'before_accepted_cues': first['audio']['accepted_cue_counts'] if first['audio'] else None,
        'after_accepted_cues': second['audio']['accepted_cue_counts'] if second['audio'] else None,
        'scope': 'Metadata/chronology comparison only; no visual before/after acceptance is inferred.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', type=Path)
    parser.add_argument('--repo', type=Path, default=REPO)
    parser.add_argument('--source-commit')
    parser.add_argument('--allow-overlay', action='append', default=[])
    parser.add_argument('--allow-incomplete-probe', action='store_true')
    parser.add_argument('--compare-analysis', type=Path, help='Completed earlier analysis JSON to compare metadata/authority')
    parser.add_argument('--output', type=Path, help='New scratch-only analysis file; default prints JSON')
    args = parser.parse_args()
    try:
        report = analyze(args.capture.resolve(), args)
        if args.compare_analysis:
            previous = json.loads(args.compare_analysis.read_text())
            report['comparison_to_previous'] = compare(previous, report)
            report['comparison_input_sha256'] = sha256(args.compare_analysis)
        payload = json.dumps(report, indent=2, allow_nan=False) + '\n'
        if args.output:
            destination = args.output.resolve()
            if not destination.is_relative_to(SCRATCH) or destination.exists():
                raise ValueError('--output must be a new file below ' + str(SCRATCH))
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(payload)
            print(json.dumps({'analysis': str(destination), 'sha256': sha256(destination),
                  'status': report['recording']['status'], 'frames': report['recording']['frames'],
                  'cast_counts': report['cast_counts'], 'source_audit': report['source_commit_audit']['status']}))
        else:
            print(payload, end='')
        return 1 if report['source_commit_audit'].get('unallowed_differences', 0) else 0
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        print('ANALYSIS FAILED: ' + str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
