import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time

repo = Path('/workspace/Emberfall-Ashen-Veil')
proof = Path(__file__).resolve().parent
output = proof / 'final-native'
output.mkdir(exist_ok=False)
native = output / 'native'
native.mkdir()
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
command = [godot, '--path', str(repo), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--script', 'res://tests/native_motion_transition_preview.gd', '--', '--capture-dir=' + str(native)]
started = time.time()
log = output / 'native-preview.log'
with log.open('wb') as handle:
    completed = subprocess.run(command, cwd=repo, env=env, stdout=handle, stderr=subprocess.STDOUT, timeout=300)
lines = log.read_text().splitlines()
expected_vsync = 'WARNING: Could not set V-Sync mode, as changing V-Sync mode is not supported by the graphics driver.'
diagnostics = [line for line in lines if re.search(r'^\s*(?:(?:SCRIPT|SHADER)\s+)?ERROR:|Parse Error:|WARNING:', line, re.I) and line != expected_vsync]
images = [{'image': file.name, 'bytes': file.stat().st_size, 'sha256': hashlib.sha256(file.read_bytes()).hexdigest()} for file in sorted(native.glob('*.png'))]
success = completed.returncode == 0 and not diagnostics and len(images) == 18 and before == snapshot()
receipt = {'scope': '18 original1000x1000 native production actor diagnostic frames; fixed studio camera, desktopGL compatibility/software renderer and Dummy audio; no continuous expedition, phone performance or AAA quality claim.', 'git_head_at_native_execution': head, 'command': command, 'actual_exit_code': completed.returncode, 'strict_success': success, 'elapsed_seconds': round(time.time() - started, 3), 'log': str(log), 'log_sha256': hashlib.sha256(log.read_bytes()).hexdigest(), 'engine_diagnostics': diagnostics, 'exact_known_xvfb_vsync_warning_count': lines.count(expected_vsync), 'source_files_sha256_before': before, 'source_files_sha256_after': snapshot(), 'native_images': images}
(output / 'execution.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps({k: receipt[k] for k in ['actual_exit_code', 'strict_success', 'elapsed_seconds', 'engine_diagnostics', 'exact_known_xvfb_vsync_warning_count']}), flush=True)
raise SystemExit(0 if success else 1)
