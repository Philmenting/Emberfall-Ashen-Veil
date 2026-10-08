import hashlib
import json
import os
from pathlib import Path
import re
import shutil

repo = Path('/workspace/Emberfall-Ashen-Veil')
scratch = Path(__file__).resolve().parent
leaf = repo / 'docs/design/reference-057/motion/evade-step-final'
leaf.mkdir(parents=True, exist_ok=False)

def copy_original(source, relative):
    target = leaf / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if source.is_relative_to(repo) and not source.is_relative_to(repo / "docs"):
        shutil.copyfile(source, target)
    else:
        try:
            os.link(source, target)
        except OSError:
            shutil.copyfile(source, target)
    assert source.read_bytes() == target.read_bytes()

for file in (scratch / 'final-affected').glob('*.log'):
    copy_original(file, 'accepted/affected/' + file.name)
copy_original(scratch / 'final-affected/execution.json', 'accepted/affected/execution.json')
copy_original(scratch / 'final-native/execution.json', 'accepted/native/execution.json')
copy_original(scratch / 'final-native/native-preview.log', 'accepted/native/native-preview.log')
for file in (scratch / 'final-native/native').iterdir():
    copy_original(file, 'accepted/native/originals/' + file.name)
for name in ['source_avatar_evade.original.gd', 'source_avatar_evade_smoke.original.gd', 'regression-original-evade.gd', 'original-regression-red.log', 'original-audit.log', 'original-signed-separation.json', 'original-summary.json', 'source_avatar_evade.half-cycle-stride150-rejected.gd', 'corrected-evade-smoke-stride150-rejected.log', 'corrected-audit.log', 'corrected-signed-separation.json', 'corrected-summary.json', 'corrected-evade-smoke-stride100.log']:
    copy_original(scratch / name, 'historical-diagnosis/' + name)
for name in ['audit.gd', 'run_affected.py', 'run_native.py', 'prepare_supplement.py']:
    copy_original(scratch / name, 'tools/' + name)
for name in ['scripts/source_avatar_evade.gd', 'tests/source_avatar_evade_smoke.gd']:
    copy_original(repo / name, 'accepted/source-snapshot/' + name)

affected = json.loads((scratch / 'final-affected/execution.json').read_text())
native = json.loads((scratch / 'final-native/execution.json').read_text())
assert affected['source_files_sha256_before'] == affected['source_files_sha256_after'] == native['source_files_sha256_before'] == native['source_files_sha256_after']
evade = next(record for record in affected['records'] if record['suite'] == 'source_avatar_evade')['results'][0]
paths = [path for paths in evade['choreography_metrics'].values() for path in paths]
actual_samples = sum(path['actual_progress_samples'] + path['actual_recovery_samples'] for path in paths)
assert actual_samples == 6288 and len(paths) == 48

def original_summary(log):
    lines = log.read_text().splitlines()
    return next(line for line in reversed(lines) if re.search(r':\s*\d+ checks,\s*\d+ failures', line))
historical = {
    'scope': 'Original logs and exact preserved helper/fixture bytes. The baseline regression uses the preserved original evade helper via one scratch-only preload substitution; the actor/source anatomy remains the then-current057 production. These are diagnostics, not056 full-game captures or successful final tests.',
    'original_geometry_audit': {'actual_engine_exit_code': 0, 'actual_poses': 2904, 'signed_ankle_minimum_m': min(row['signed_ankle_separation_m'] for path in json.loads((scratch / 'original-signed-separation.json').read_text())['paths'] for row in path['rows'])},
    'original_helper_with_new_choreography_regression': {'actual_engine_exit_code': 1, 'summary': original_summary(scratch / 'original-regression-red.log'), 'result': 'Expected failing regression, including negative actual native ankle/weighted sole separation.'},
    'half_cycle_stride150_rejected': {'actual_engine_exit_code': 1, 'summary': original_summary(scratch / 'corrected-evade-smoke-stride150-rejected.log'), 'result': 'Rejected despite positive lateral foot order: existing crouch/knee, outfit and weapon floor requirements fail.'},
    'stride100_provisional': {'actual_engine_exit_code': 0, 'summary': original_summary(scratch / 'corrected-evade-smoke-stride100.log'), 'scope': 'Earlier provisional fixture with121 travel samples; final131 travel/recovery and half-cycle outfit/weapon checks are separate accepted execution.'},
    'receipt_timing': 'Actual exit codes were recorded from the execution tools; this consolidated index was assembled after those executions. Original logs are retained without rewriting.'
}
(leaf / 'historical-diagnosis/attempt-index.json').write_text(json.dumps(historical, indent=2) + '\n')
total_checks = sum(int(re.search(r'(\d+) checks', record['summaries'][0]).group(1)) for record in affected['records'] if record['summaries'])
receipt = {
    'scope': 'Accepted shared evade correction, affected native suites and18 original diagnostic PNGs. Game-scale temporal acceptance is pending the newly rendered full ordinary expedition movies; no phone/AAA/general beta readiness claim.',
    'source_binding_kind': 'Exact unchanged working-source byte snapshots; root may append an immutable commit binding for these same bytes without rewriting original execution receipts.',
    'recorded_git_head_before_owned_changes': affected['git_head_before_changes'],
    'all_tracked_non_docs_source_sha256': affected['source_files_sha256_before'],
    'owned_changes': ['scripts/source_avatar_evade.gd', 'tests/source_avatar_evade_smoke.gd'],
    'choreography': {'outside_swing_offset': .5, 'inside_initial_stance_offset': 0, 'stance_fraction': .5, 'visual_stride_source_m': 1, 'unchanged_simulation': 'Actual movement/control/events/release/cooldowns/damage/RNG/camera; actual world snapshot equivalence is asserted in original production fixture.'},
    'accepted_suites': [{'suite': record['suite'], 'actual_exit_code': record['actual_exit_code'], 'strict_success': record['strict_success'], 'summary': record['summaries']} for record in affected['records'] if record['suite'] != 'editor-import'],
    'actual_affected_suite_count': 9,
    'actual_affected_check_count': total_checks,
    'actual_choreography_path_count': len(paths),
    'actual_choreography_pose_count': actual_samples,
    'choreography_audit_scope': '48 paths: three classes × eight original-source-basis directions × normal2.4m/three-complete-stride paths;121 actual travel samples and10 fixed-position recovery samples per path. The original engine JSON preserves per-path actual minima/criteria, not a full per-pose movie or vertex journal.',
    'native_actual_exit_code': native['actual_exit_code'],
    'native_strict_success': native['strict_success'],
    'native_original_png_count': len(native['native_images']),
    'visual_review': {'viewer': 'evade_step_final_057 owner', 'original_pngs_viewed': [item['image'] for item in native['native_images']], 'finding': 'Signature load/release/follow and cancellation departure/entry retain coherent proportions and grips. Outside-first LowStep originals show distinct noncrossing boots/shins and a broad lateral lunge. Root independently reviewed all three LowStep originals and accepted the frozen source for upcoming temporal review. This still-image review does not establish continuous game-scale motion quality.'},
    'historical_original_proofs_preserved': True
}
(leaf / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
readme = '''# Shared evade choreography correction

The previous helper started the inside foot swinging while the outside foot stayed planted. Actual native bones and indexed weighted sole geometry reverse their original lateral order during sideways and diagonal travel. The preserved original-helper regression records 2,005 checks and 132 failures; the original source and logs remain in `historical-diagnosis/`.

The correction opens with the outside foot, gives each support half of the gait cycle, and uses a1.00-source visual stride. The1.50-source candidate preserved order but failed the existing anatomical crouch/knee and garment/weapon floor checks; that candidate and its original failed log are also retained. The shorter accepted stride passes those unchanged requirements. Simulation travel, speed, timing, release/cancellation events, RNG and camera behavior remain covered by the existing production fixture.

The final actual Godot4.7.2 run passes9 affected suites and4,321 checks with zero failures, actual exit0 and clean strict diagnostics. Its five motion suites total3,744 checks. The evade fixture passes2,173 checks, including6,288 actual travel/recovery poses over48 original-basis paths, both stance supports, unchanged65 native rests/scales/segment lengths, signed ankle and indexed weighted sole separation, and complete outfit/weapon clearance at exact half-cycle landings. The original per-path measured minima are in `accepted/affected/source_avatar_evade.log` and the complete actual execution/source-byte receipts are in `accepted/affected/execution.json`.

`accepted/native/originals/` contains all18 original1000×1000 native diagnostic PNGs and actual production-bone pose metadata. The native process exits0 and passes strict diagnostics; its original log contains only the exact known unsupported Xvfb VSync warning. All18 PNGs were viewed. Root also reviewed all three LowStep originals: distinct boots/shins and intact proportions, with a broad lunge accepted for the upcoming motion review.

**Game-scale temporal acceptance is pending the newly rendered complete ordinary expedition movies.** These fixed studio stills and geometry audits establish their stated scope only. They do not establish phone frame times or general beta/AAA quality. Exact source byte snapshots match across the accepted headless and native runs; the immutable source commit binding is appended separately by root after committing those same bytes.
'''
readme = readme.replace('with132','with 132').replace('a1.00','a 1.00').replace('The1.50','The 1.50').replace('Godot4.7.2','Godot 4.7.2').replace('passes9','passes 9').replace('and4,321','and 4,321').replace('exit0','exit 0').replace('total3,744','total 3,744').replace('passes2,173','passes 2,173').replace('including6,288','including 6,288').replace('over48','over 48').replace('unchanged65','unchanged 65').replace('all18','all 18').replace('original1000','original 1000').replace('exits0','exits 0').replace('All18','All 18')
(leaf / 'README.md').write_text(readme)
index = {str(file.relative_to(leaf)): {'bytes': file.stat().st_size, 'sha256': hashlib.sha256(file.read_bytes()).hexdigest()} for file in sorted(leaf.rglob('*')) if file.is_file()}
(leaf / 'file-index.json').write_text(json.dumps(index, indent=2) + '\n')
print(json.dumps({'leaf': str(leaf), 'files_before_index': len(index), 'bytes': sum(item['bytes'] for item in index.values()), 'actual_checks': total_checks, 'actual_pose_count': actual_samples}))
