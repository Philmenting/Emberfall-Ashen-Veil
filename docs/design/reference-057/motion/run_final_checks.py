import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--attempt', required=True)
parser.add_argument('--native', action='store_true')
args = parser.parse_args()
project = Path('/workspace/Emberfall-Ashen-Veil')
output = Path('/workspace/scratch/emberfall-quality-057/motion') / args.attempt
output.mkdir(parents=True, exist_ok=False)
godot = '/workspace/scratch/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
env = os.environ.copy()
env['DISPLAY'] = ':108'
env['LP_NUM_THREADS'] = '4'
source_paths = ['scripts/native_motion_transition.gd', 'scripts/class_avatar_pose.gd', 'scripts/class_avatar_rig.gd', 'scripts/source_avatar_combat.gd', 'scripts/source_avatar_rig.gd', 'scripts/dungeon_actor.gd', 'tests/native_motion_transition_smoke.gd', 'tests/native_motion_transition_preview.gd']
source_hashes = {name: hashlib.sha256((project / name).read_bytes()).hexdigest() for name in source_paths}
records = []
if args.native:
    native = output / 'native'
    native.mkdir()
    steps = [('native-preview', [godot, '--path', str(project), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--script', 'res://tests/native_motion_transition_preview.gd', '--', '--capture-dir=' + str(native)], 300)]
else:
    steps = [('editor-import', [godot, '--headless', '--path', str(project), '--editor', '--import', '--quit'], 300)]
    for suite in ['native_motion_transition', 'source_avatar_attack', 'source_avatar_attack_contact', 'class_avatar_quality', 'source_avatar_evade']:
        steps.append((suite, [godot, '--headless', '--path', str(project), '--audio-driver', 'Dummy', '--script', 'res://tests/' + suite + '_smoke.gd'], 300))
for label, command, limit in steps:
    started = time.time()
    log = output / (label + '.log')
    with log.open('wb') as destination:
        result = subprocess.run(command, cwd=project, env=env, stdout=destination, stderr=subprocess.STDOUT, timeout=limit)
    content = log.read_text()
    diagnostics = [line for line in content.splitlines() if re.search(r'(SCRIPT ERROR|SHADER ERROR|Parse Error|Compile Error|^ERROR:|couldn.t resolve track)', line)]
    summaries = [line for line in content.splitlines() if ('SMOKE:' in line or 'checks,' in line)]
    record = {'label': label, 'command': command, 'actual_exit_code': result.returncode, 'elapsed_seconds': round(time.time()-started, 3), 'log': str(log), 'engine_diagnostics': diagnostics, 'summaries': summaries}
    records.append(record)
    receipt = {'source_files_sha256': source_hashes, 'records': records, 'scope': 'Focused actual production tests; native previews are diagnostic images, not ordinary expedition movies or phone performance measurements.'}
    if args.native:
        shots = [{'image': file.name, 'bytes': file.stat().st_size, 'sha256': hashlib.sha256(file.read_bytes()).hexdigest()} for file in sorted(native.glob('*.png'))]
        receipt['native_images'] = shots
    (output / 'execution.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(record), flush=True)
    if result.returncode != 0 or diagnostics:
        raise SystemExit(1)
    if args.native and len(shots) != 18:
        raise SystemExit('Expected 18 original native images.')
if source_hashes != {name: hashlib.sha256((project / name).read_bytes()).hexdigest() for name in source_paths}:
    raise SystemExit('Owned motion source changed during focused execution.')
