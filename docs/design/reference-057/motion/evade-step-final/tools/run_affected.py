import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time

repo = Path('/workspace/Emberfall-Ashen-Veil')
proof = Path(__file__).resolve().parent
output = proof / 'final-affected'
output.mkdir(exist_ok=False)
godot = '/workspace/scratch/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=repo).decode().split('\0')
paths = [p for p in tracked if p and not p.startswith('docs/') and p != 'README.md']
def snapshot():
    return {p: hashlib.sha256((repo / p).read_bytes()).hexdigest() for p in paths if (repo / p).is_file()}
before = snapshot()
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip()
env = os.environ.copy()
env['LP_NUM_THREADS'] = '4'
env['DISPLAY'] = ':108'
env['XDG_DATA_HOME'] = str(output / 'isolated-userdata')
records = []
version = subprocess.run([godot, '--version'], capture_output=True, text=True)
assert version.returncode == 0 and version.stdout.strip().startswith('4.7.2')
steps = [('editor-import', [godot, '--headless', '--path', str(repo), '--editor', '--import', '--quit'])]
for suite in ['source_avatar_evade', 'native_motion_transition', 'source_avatar_attack', 'source_avatar_attack_contact', 'class_avatar_quality', 'character_3d', 'animation_craft', 'source_avatar', 'source_avatar_grip']:
    steps.append((suite, [godot, '--headless', '--path', str(repo), '--audio-driver', 'Dummy', '--script', 'res://tests/' + suite + '_smoke.gd']))
for suite, command in steps:
    started = time.time()
    log = output / (suite + '.log')
    with log.open('wb') as handle:
        completed = subprocess.run(command, cwd=repo, env=env, stdout=handle, stderr=subprocess.STDOUT, timeout=300)
    text = log.read_text()
    diagnostics = [line for line in text.splitlines() if re.search(r'^\s*(?:(?:SCRIPT|SHADER)\s+)?ERROR:|Parse Error:|WARNING:.*(?:couldn.t resolve|shader|script|track|rendering|gpu|vulkan|opengl|uniform|material|parse)', line, re.I)]
    summaries = [line for line in text.splitlines() if re.search(r':\s*\d+ checks,\s*(?:\d+ actual poses,\s*)?\d+ failures', line)]
    results = [json.loads(line) for line in text.splitlines() if line.startswith('{') and line.endswith('}')]
    success = completed.returncode == 0 and not diagnostics and (suite == 'editor-import' or any(result.get('failures') == 0 for result in results) or any('0 failures' in line for line in summaries))
    record = {'suite': suite, 'command': command, 'actual_exit_code': completed.returncode, 'strict_success': success, 'elapsed_seconds': round(time.time() - started, 3), 'log': str(log), 'log_sha256': hashlib.sha256(log.read_bytes()).hexdigest(), 'engine_diagnostics': diagnostics, 'summaries': summaries, 'results': results}
    records.append(record)
    receipt = {'scope': 'Affected native motion/anatomy/grip suites only; actual current working-source snapshot, not an immutable commit until root commits these same bytes; no phone performance claim.', 'git_head_before_changes': head, 'godot_version_actual': version.stdout.strip(), 'source_files_sha256_before': before, 'source_files_sha256_after': snapshot(), 'records': records}
    (output / 'execution.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps({k: record[k] for k in ['suite', 'actual_exit_code', 'strict_success', 'elapsed_seconds', 'summaries']}), flush=True)
    if not success:
        raise SystemExit(1)
assert before == snapshot(), 'Tracked source changed during final affected checks'
print('FINAL EVADE AFFECTED CHECKS: 9 suites, all actual exit0, strict diagnostics clean, source bytes unchanged', flush=True)
