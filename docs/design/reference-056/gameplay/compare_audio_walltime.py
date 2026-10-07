#!/usr/bin/env python3
"""Compare recorded native audio events while preserving disclosed process wall timestamps.

This read-only evidence helper removes only acceptance_wall_msec from comparison.
The original chronological JSONL is untouched; sample boundaries, cue keys, voice
slots, replaced keys, naturalEOF and exactzero-tail records remain compared.
"""
import argparse
import hashlib
import json
from pathlib import Path


def sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--before', type=Path, required=True)
    parser.add_argument('--after', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    before = [json.loads(line) for line in (args.before / 'frames.jsonl').read_text().splitlines() if line.strip()]
    after = [json.loads(line) for line in (args.after / 'frames.jsonl').read_text().splitlines() if line.strip()]
    if len(before) < len(after): raise ValueError('The original baseline is shorter than the current prefix')
    before_digest, after_digest = hashlib.sha256(), hashlib.sha256()
    differences, wall_differences = [], []
    event_count = 0
    for index, current in enumerate(after):
        old_events = before[index]['audio']['accepted_state_events']
        new_events = current['audio']['accepted_state_events']
        clean = lambda events: [{key: value for key, value in event.items() if key != 'acceptance_wall_msec'} for event in events]
        original, updated = clean(old_events), clean(new_events)
        before_digest.update((canonical(original) + '\n').encode())
        after_digest.update((canonical(updated) + '\n').encode())
        if original != updated: differences.append(index)
        if old_events != new_events: wall_differences.append(index)
        event_count += len(new_events)
    result = {'schema': 1, 'status': 'sample_timeline_and_audio_states_equal' if not differences else 'actual_audio_state_difference',
              'compared_frames': len(after), 'compared_audio_events': event_count,
              'ignored_fields': ['acceptance_wall_msec'], 'actual_audio_difference_frames': differences,
              'raw_event_difference_frames': wall_differences,
              'before_normalized_audio_event_sha256': before_digest.hexdigest(),
              'after_normalized_audio_event_sha256': after_digest.hexdigest(),
              'before_original_frame_log_sha256': sha256(args.before / 'frames.jsonl'),
              'after_original_frame_log_sha256': sha256(args.after / 'frames.jsonl'),
              'analysis_helper_sha256': sha256(Path(__file__)),
              'scope': 'Recorded cue acceptance wall timestamps belong to separate engine processes and remain in original JSONL. Only that field is excluded here; actual native sample-time event boundaries and complete cue/state/EOF data are compared. No sound, image, runtime or source data is edited.'}
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print('AUDIO_SAMPLE_STATE_COMPARISON', result['status'], result['compared_frames'], 'frames')
    return 0 if not differences else 1


if __name__ == '__main__':
    raise SystemExit(main())
