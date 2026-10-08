#!/usr/bin/env python3
"""Independent read-only verification of finalized technical gameplay proof.

Outputs only to this scratch audit directory. No game render, source edits,
full suite execution, or aesthetic/physical-phone acceptance is performed.
"""
import datetime
import gzip
import hashlib
import json
import pathlib
import re
import struct
import subprocess
import sys

OUT = pathlib.Path(__file__).parent
REPO = pathlib.Path('/workspace/Emberfall-Ashen-Veil')
LEAF = REPO / 'docs/design/reference-057/gameplay'
SOURCE = '1cc13152a83c6631590d4df32ca298700a417df7'
BASE = '86cb1b8ec878b4ae06daba5e6c5a4fa583865dc5'
FIXTURE = {'tools/capture_arcanist_quality.py', 'tools/capture_combat_quality.py',
           'tests/arcanist_quality_gameplay_preview.gd', 'tests/arcanist_quality_gameplay_preview.tscn',
           'tests/combat_quality_gameplay_preview.gd', 'tests/combat_quality_gameplay_preview.tscn'}
AUTHORITY = ('frame', 'simulation_elapsed', 'simulation_accumulator', 'stage', 'phase',
             'finished', 'won', 'hero_hp', 'pending_attack', 'guardian')
EXPECT = {'arcanist': (2496, 3669120), 'ranger': (2559, 3761730), 'vowkeeper': (3099, 4555530)}
report = {'schema': 1, 'started_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
          'scope': 'Finalized technical proof only. Temporal appended review excluded; no whole-film visual acceptance or physical-phone performance claim.',
          'source_commit': SOURCE, 'baseline_source_commit': BASE,
          'assertions': 0, 'mismatches': [], 'classes': [], 'subprocesses': [], 'source_blobs': []}

def check(condition, message):
    report['assertions'] += 1
    if not condition:
        report['mismatches'].append(message)

def digest(p):
    h = hashlib.sha256()
    with pathlib.Path(p).open('rb') as f:
        for data in iter(lambda: f.read(1 << 20), b''):
            h.update(data)
    return h.hexdigest()

def load(p):
    return json.loads(pathlib.Path(p).read_text())

def command(argv, label):
    result = subprocess.run(argv, cwd=REPO, capture_output=True)
    report['subprocesses'].append({'label': label, 'command': argv, 'actual_process_exit': result.returncode,
                                  'stdout': result.stdout.decode(errors='replace'),
                                  'stderr': result.stderr.decode(errors='replace')})
    return result

git_cache = {}
def git_digest(commit, relative):
    key = (commit, relative)
    if key not in git_cache:
        result = subprocess.run(['git', 'cat-file', 'blob', commit + ':' + relative], cwd=REPO, capture_output=True)
        check(result.returncode == 0, 'Git blob unavailable: ' + commit + ':' + relative)
        git_cache[key] = hashlib.sha256(result.stdout).hexdigest()
        report['source_blobs'].append({'commit': commit, 'path': relative, 'actual_git_cat_file_exit': result.returncode,
                                       'sha256': git_cache[key]})
    return git_cache[key]

def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False)

try:
    session = load(LEAF/'capture-session-receipt.json')
    supervisor = load(LEAF/'detached-execution/detached-supervisor-receipt.json')
    launch = load(LEAF/'detached-execution/detached-launch-receipt.json')
    request = load(LEAF/'detached-execution/detached-launch-request.json')
    check(session['status'] == 'six_complete_native_recordings_and_three_verified_full_comparisons', 'Wrong session completion status')
    check(session['source_commit'] == SOURCE and session['baseline_commit'] == BASE, 'Session source identity mismatch')
    check(supervisor['actual_orchestrator_wait_exit'] == 0, 'Supervisor did not record actual wait exit 0')
    check(supervisor['final_session_receipt_sha256'] == digest(LEAF/'capture-session-receipt.json'), 'Final supervisor session hash mismatch')
    check(supervisor['source_commit'] == SOURCE, 'Supervisor source mismatch')
    request_hash = digest(LEAF/'detached-execution/detached-launch-request.json')
    check(supervisor['request_sha256'] == launch['request_sha256'] == request_hash, 'Detached request hash mismatch')
    check(launch['launcher_sha256'] == request['launcher_sha256'] == digest(LEAF/'detached-execution/launch_detached_full_captures.py'), 'Launcher identity mismatch')
    check(session['scratch_orchestrator_sha256'] == request['scratch_orchestrator_sha256'] == digest(LEAF/'run_six_full_captures.py'), 'Orchestrator identity mismatch')
    check(launch['start_new_session'] is True and launch['stdio_bound_to_files_or_devnull'] is True, 'Launch isolation evidence missing')
    check(supervisor['parent_pid'] == 1 and supervisor['pid'] == supervisor['session_id'] == launch['pid'], 'Supervisor reparent/session binding mismatch')
    check(len(session['processes']) == 9, 'Wrong actual process count')
    for proc in session['processes']:
        check(proc['status'] == 'passed' and proc['actual_process_exit'] == 0, 'Failed original process: ' + proc['label'])
        check((LEAF/'execution-logs'/pathlib.Path(proc['log']).name).is_file(), 'Missing original process log: ' + proc['label'])
        if 'capture_receipt_sha256' in proc:
            side, slug = proc['label'].split('-', 1)
            check(proc['capture_receipt_sha256'] == digest(LEAF/slug/side/'receipt.json'), 'Session capture hash mismatch: ' + proc['label'])
        else:
            slug = proc['label'].split('-', 1)[0]
            check(proc['comparison_sha256'] == digest(LEAF/slug/'comparison.json'), 'Session comparison hash mismatch: ' + proc['label'])
    hardlinks = load(LEAF/'hardlink-staging-receipt.json')
    check(len(hardlinks['files']) == 355, 'Wrong staged immutable inventory count')
    total = 0
    for item in hardlinks['files']:
        p, original = LEAF/item['path'], pathlib.Path(item['source'])
        check(p.is_file() and original.is_file(), 'Missing immutable staged/original file: ' + item['path'])
        check(p.stat().st_size == original.stat().st_size == item['bytes'], 'Immutable size mismatch: ' + item['path'])
        check(digest(p) == item['sha256'] == digest(original), 'Immutable SHA mismatch: ' + item['path'])
        a, b = p.stat(), original.stat()
        check((a.st_dev, a.st_ino) == (b.st_dev, b.st_ino), 'Staged original no longer hardlinked: ' + item['path'])
        total += item['bytes']
    check(total == hardlinks['sum_original_logical_bytes'], 'Immutable original byte sum mismatch')
    report['immutable_original_files'] = len(hardlinks['files'])
    report['immutable_original_logical_bytes'] = total
    check(not [p for p in LEAF.rglob('*') if any(x in ('.cache', '.godot', 'xdg', 'shader_cache') for x in p.parts) or p.suffix == '.cache'], 'Derived runtime caches accidentally staged')
    report['original_selected_pngs'] = 0
    for slug, (frames, samples) in EXPECT.items():
        comparison = load(LEAF/slug/'comparison.json')
        reproduced = load(LEAF/slug/'comparison-reproduced-after-hardlink.json')
        execution = load(LEAF/slug/'staged-analysis-execution.json')
        check(comparison == reproduced, 'Staged reanalysis differs from original comparison: ' + slug)
        check(execution['actual_process_exit'] == 0 and not execution['stderr'], 'Staged analysis execution not clean: ' + slug)
        check(execution['result_sha256'] == digest(LEAF/slug/'comparison-reproduced-after-hardlink.json'), 'Staged result hash mismatch: ' + slug)
        check(comparison['status'] == 'verified_complete_ordinary_expedition' and comparison['frames'] == frames, 'Wrong comparison completion/frame count: ' + slug)
        check(comparison['current_git_source_audit']['source_commit'] == SOURCE and comparison['baseline_git_source_audit']['source_commit'] == BASE, 'Comparison commit mismatch: ' + slug)
        check(comparison['comparison']['excluded_audio_comparison_fields'] == ['acceptance_wall_msec'], 'Extra audio comparison exclusions: ' + slug)
        sides = {}
        for side in ('before', 'after'):
            folder = LEAF/slug/side
            receipt, summary, metadata = (load(folder/n) for n in ('receipt.json', 'capture-summary.json', 'capture-metadata.json'))
            check(receipt['status'] == 'complete' and receipt['frames'] == frames, 'Capture receipt incomplete/wrong frames: ' + slug + side)
            for key in ('godot_process_exit', 'ffmpeg_process_exit', 'ffmpeg_full_decode_exit'):
                check(receipt[key] == 0, 'Original actual exit not 0: ' + slug + side + key)
            check(receipt['full_decode_passed'] and receipt['continuous_simulation_verified'] and receipt['continuous_audio_samples_verified'], 'Original full verification missing: ' + slug + side)
            check(receipt['inputs_unchanged'] and receipt['input_sha256_before'] == receipt['input_sha256_after'], 'Capture inputs changed during movie: ' + slug + side)
            for relative, expected_sha in receipt['input_sha256_before'].items():
                commit = SOURCE if side == 'after' or relative in FIXTURE else BASE
                check(git_digest(commit, relative) == expected_sha, 'Captured input not exact declared Git blob: ' + slug + side + relative)
            check(summary['frames'] == frames and summary['complete'] and summary['won'] and summary['run_boss_defeated'] and summary['run_succeeded'], 'Ordinary victory incomplete: ' + slug + side)
            check(summary['final_page'] == 'loot' and len(summary['recovered_loot']) == 2 and summary['settle_frames_recorded'] == 90, 'Missing original two-loot/end outcome: ' + slug + side)
            check(summary['recording_kind'] == metadata['recording_kind'] == receipt['recording_kind'] == 'ordinary_expedition', 'Wrong recording kind: ' + slug + side)
            check(metadata['world_seed'] == 1979 and metadata['run_seed'] == 95635017 and metadata['playback_fps'] == 30, 'Seed/playback mismatch: ' + slug + side)
            check(metadata['audio_channels'] == 2 and metadata['audio_sample_rate'] == 44100 and not metadata['physical_device_performance'], 'Audio/device scope mismatch: ' + slug + side)
            check(digest(folder/receipt['mp4_file']) == receipt['mp4_sha256'] and digest(folder/'frames.jsonl') == receipt['frame_log_sha256'], 'Original media/journal hash mismatch: ' + slug + side)
            for item in receipt['selected_frames']:
                p = folder/item['file']
                check(digest(p) == item['sha256'], 'Original selected PNG hash mismatch: ' + slug + side + item['file'])
                with p.open('rb') as stream:
                    png_head = stream.read(24)
                check(png_head[:8] == b'\x89PNG\r\n\x1a\n' and struct.unpack('>II', png_head[16:24]) == (1200, 536), 'PNG format/native dimensions mismatch: ' + str(p))
                report['original_selected_pngs'] += 1
            movie = folder/receipt['mp4_file']
            probe = command(['ffprobe', '-v', 'error', '-show_entries', 'stream=codec_type,width,height,r_frame_rate,nb_frames,duration,sample_rate,channels', '-of', 'json', str(movie)], slug + '-' + side + '-independent-container-probe')
            check(probe.returncode == 0, 'Independent MP4 probe failed: ' + slug + side)
            streams = json.loads(probe.stdout)['streams']
            video = next(x for x in streams if x['codec_type'] == 'video')
            audio = next(x for x in streams if x['codec_type'] == 'audio')
            check(int(video['nb_frames']) == frames and video['width'] == 1200 and video['height'] == 536 and video['r_frame_rate'] == '30/1', 'Container frame dimensions/count/rate mismatch: ' + slug + side)
            check(abs(float(video['duration']) - frames/30) < 1e-6 and audio['sample_rate'] == '44100' and audio['channels'] == 2, 'Container duration/audio mismatch: ' + slug + side)
            archive = receipt['native_pcm_lossless_archive']
            check(digest(folder/archive['file']) == archive['compressed_sha256'], 'Compressed original PCM hash mismatch: ' + slug + side)
            h, size = hashlib.sha256(), 0
            with gzip.open(folder/archive['file'], 'rb') as stream:
                for data in iter(lambda: stream.read(1 << 20), b''):
                    size += len(data); h.update(data)
            check(size == samples*8 == archive['uncompressed_bytes'] and h.hexdigest() == archive['uncompressed_sha256'] == comparison['native_pcm']['sha256'], 'Lossless full PCM mismatch: ' + slug + side)
            rows = [json.loads(line) for line in (folder/'frames.jsonl').open()]
            check(len(rows) == frames and all(row['frame'] == i for i,row in enumerate(rows)), 'Frame chronology has omission/reordering: ' + slug + side)
            check(all(row['audio']['first_sample_frame'] == i*1470 and row['audio']['end_sample_frame'] == (i+1)*1470 for i,row in enumerate(rows)), 'Audio clock discontinuity: ' + slug + side)
            check(rows[-1]['finished'] and rows[-1]['won'] and rows[-1]['page'] == 'loot', 'Journal does not finish in original loot UI: ' + slug + side)
            sides[side] = rows
        authority_hashes = []
        for side in ('before', 'after'):
            h = hashlib.sha256()
            for row in sides[side]:
                record = {k: row.get(k) for k in AUTHORITY}
                record['authoritative_events'] = [e for e in row['events'] if e['type'] != 'hero_release']
                record['ordinary_full_authority'] = row['ordinary_full_authority']
                h.update((canonical(record)+'\n').encode())
            authority_hashes.append(h.hexdigest())
        check(authority_hashes[0] == authority_hashes[1] == comparison['comparison']['before_authority_sha256'] == comparison['comparison']['after_authority_sha256'], 'Independent full authority digest differs: ' + slug)
        check(all(a.get('camera') == b.get('camera') for a,b in zip(sides['before'],sides['after'])), 'Independent camera transform differs: ' + slug)
        clean = lambda row: [{k:v for k,v in e.items() if k != 'acceptance_wall_msec'} for e in row['audio'].get('accepted_state_events',[])]
        check(all(clean(a) == clean(b) for a,b in zip(sides['before'],sides['after'])), 'Cue content differs beyond original acceptance wall time: ' + slug)
        boss_frames = sum(row['stage'] == 5 and row['phase'] == 'combat' for row in sides['after'])
        warning_frames = sum(row['stage'] == 5 and row['phase'] == 'combat' and bool(row['guardian']['warning']) for row in sides['after'])
        report['classes'].append({'class': slug, 'frames_each_side': frames, 'seconds_each_side': frames/30,
                                  'stereo_pcm_sample_frames': samples, 'paired_full_authority_equal': True,
                                  'paired_camera_equal': True, 'paired_cues_equal_except_acceptance_wall_msec': True,
                                  'after_guardian_combat_frames': boss_frames, 'after_guardian_warning_frames': warning_frames})
    # Independently rebind all historical exported files, with only two declared fixture GD overlays.
    base_receipt = load('/workspace/scratch/emberfall-quality-057/baseline-export-receipt.json')
    overlay = load(LEAF/'baseline-fixture-overlay-receipt-v2.json')
    altered = {item['path']: item for item in overlay['files'] if item['bytes_changed_from_baseline_git']}
    check(set(altered) == {'tests/arcanist_quality_gameplay_preview.gd', 'tests/combat_quality_gameplay_preview.gd'}, 'Baseline contains production/unexpected overlays')
    check(len(base_receipt['files']) == 851, 'Original exported baseline inventory count mismatch')
    for item in base_receipt['files']:
        check(git_digest(BASE,item['path']) == item['sha256'], 'Baseline inventory not exact original Git: ' + item['path'])
        expected = altered.get(item['path'], {}).get('fixture_sha256', item['sha256'])
        check(digest(pathlib.Path(base_receipt['directory'])/item['path']) == expected, 'Historical exported bytes changed beyond declared fixtures: ' + item['path'])
    report['historical_export_files_checked'] = 851
    prior = load(LEAF/'interrupted-prior-attempt-recovery.json')
    prior_staging = load(LEAF/'interrupted-prior-attempt-staging.json')
    check(prior['status'] == 'interrupted_native_recording_not_completed_not_accepted' and prior['complete_jsonl_rows'] == 2033, 'Prior attempt incorrectly treated as complete')
    check(prior['original_godot_actual_wait_exit'] is None and prior['original_ffmpeg_actual_wait_exit'] is None and not prior['capture_summary_exists'], 'Prior unknown waits/completion altered')
    check(prior['ffprobe']['actual_process_exit'] == 1 and 'moov atom not found' in prior['ffprobe']['stderr'], 'Prior invalid MP4 failure not retained')
    check(digest(LEAF/'interrupted-prior-attempt-recovery.json') == prior_staging['sha256'] == digest(prior_staging['source']), 'Prior recovery receipt provenance changed')
    partial_root = pathlib.Path(prior['ffprobe']['command'][-1]).parent
    for item in prior['original_files_preserved_without_changes']:
        check(digest(partial_root/item['path']) == item['sha256'], 'Prior interrupted original no longer preserved: ' + item['path'])
    check(len(list(LEAF.glob('*/*/*.mp4'))) == 6, 'Six accepted movie inventory wrong')
    report['preserved_interrupted_attempt_files'] = len(prior['original_files_preserved_without_changes'])
    readme = (LEAF/'README.md').read_text()
    links = re.findall(r'\]\(([^)]+)\)', readme)
    for target in links:
        if not target.startswith(('https:', 'http:', '#')):
            check((LEAF/target.split('#')[0]).exists(), 'Broken technical README link: ' + target)
    check(SOURCE in readme and BASE in readme and '2.033' in readme and 'keine normale Spiel-FPS' in readme, 'Technical README scope/source/recovery statements missing')
    check('Prozess-, Kamera- und Audioprüfungen allein bewerten weder die ästhetische Qualität noch die Beta-Reife.' in readme, 'Technical README overstates aesthetic acceptance')
    report['technical_readme_local_links'] = len(links)
    report['readme_sha256_at_audit'] = digest(LEAF/'README.md')
    report['unique_exact_git_blob_checks'] = len(git_cache)
except Exception as exc:
    report['mismatches'].append('Audit execution exception: ' + repr(exc))
    import traceback
    report['exception_traceback'] = traceback.format_exc()

report['completed_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
report['status'] = 'independent_finalized_technical_gameplay_proof_verified' if not report['mismatches'] else 'mismatches_require_resolution'
(OUT/'audit-report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ('status','assertions','mismatches','classes')},indent=2))
sys.exit(bool(report['mismatches']))
