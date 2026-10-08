#!/usr/bin/env python3
"""Run exclusive-slot operation and real GL primitive assays sequentially."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import time

ROOT = Path('/workspace/Emberfall-Ashen-Veil')
OUT = Path('/workspace/scratch/emberfall-quality-057/render-budget')
ENGINE = Path('/workspace/scratch/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64')
ERROR = re.compile(r'(?:^|\n)(?:SCRIPT ERROR:|SHADER ERROR:|ERROR:|Parse Error:)|(?:AnimationMixer|AnimationPlayer).*couldn.t resolve track', re.I)
SOURCE_PATHS = (
    'scripts/combat_readability.gd', 'scripts/native_mesh_lods.gd',
    'assets/shaders/hero_occlusion.gdshader', 'tests/render_budget_smoke.gd',
    'scripts/dungeon_actor.gd', 'scripts/dungeon_world.gd',
    'scripts/avatar_attire_motion.gd', 'scripts/native_hostile_rig.gd',
    'scripts/native_hostile_style.gd', 'scripts/class_avatar_rig.gd',
    'scripts/source_avatar_rig.gd', 'scripts/hero_art.gd',
)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def sources():
    listed = subprocess.check_output(
        ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '--',
         'scripts', 'assets/models', 'assets/shaders', 'assets/materials',
         'tests/render_budget_smoke.gd', 'project.godot'], cwd=ROOT, text=True).splitlines()
    return {name: digest(ROOT / name) for name in sorted(set(listed) | set(SOURCE_PATHS)) if (ROOT / name).is_file()}

OUT.mkdir(parents=True, exist_ok=True)
stamp = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
run_dir = OUT / stamp
run_dir.mkdir()
receipt = {
    'scope': 'Exact operation/resources and available native LODs; GL Compatibility primitive assay on software llvmpipe, no frame-time or physical-phone measurement.',
    'source_not_frozen': True, 'source_before': sources(),
    'engine_path': str(ENGINE), 'engine_sha256': digest(ENGINE), 'runs': [],
}
receipt_path = run_dir / 'execution-receipt.json'
for label, native in [('headless-operations', False), ('native-gl-primitives', True)]:
    report = run_dir / (label + '-report.json')
    command = [str(ENGINE), '--path', str(ROOT)]
    command += ['--display-driver', 'x11', '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy'] if native else ['--headless']
    command += ['--script', 'res://tests/render_budget_smoke.gd', '--', '--budget-report=' + str(report)]
    if native:
        command += ['--require-native-render']
    env = os.environ.copy()
    env.update({'DISPLAY': ':108', 'LP_NUM_THREADS': '4', 'GODOT_SILENCE_ROOT_WARNING': '1'})
    for variable, suffix in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
        env[variable] = str(run_dir / 'isolated' / label / suffix)
    log = run_dir / (label + '.log')
    start = time.perf_counter()
    try:
        with log.open('w') as stream:
            completed = subprocess.run(command, cwd=ROOT, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=300, check=False)
        exit_code = completed.returncode
    except subprocess.TimeoutExpired:
        exit_code = None
    output = log.read_text(errors='replace')
    summary = re.findall(r'RENDER BUDGET SMOKE: (\d+) checks, (\d+) failures', output)
    engine_errors = ERROR.findall(output)
    report_error = None
    try:
        parsed_report = json.loads(report.read_text()) if report.exists() else None
    except (OSError, ValueError) as exc:
        parsed_report = None
        report_error = str(exc)
    report_consistent = bool(summary) and parsed_report is not None and parsed_report.get('checks') == int(summary[-1][0]) and parsed_report.get('failures') == 0
    if parsed_report is not None:
        report_consistent = report_consistent and len(parsed_report.get('classes', [])) == 3 and len(parsed_report.get('hostile_geometry', [])) == 7
        report_consistent = report_consistent and len(parsed_report.get('native_render_primitives', [])) == (3 if native else 0)
    item = {'label': label, 'command': command, 'actual_exit_code': exit_code,
            'wall_seconds': round(time.perf_counter() - start, 3),
            'log': log.name, 'log_sha256': digest(log), 'report': report.name,
            'report_sha256': digest(report) if report.exists() else None,
            'summary_matches': summary, 'strict_engine_errors': engine_errors,
            'report_read_error': report_error,
            'report_consistent_with_actual_summary_and_render_scope': report_consistent,
            'software_render_thread_count': 4 if native else None}
    item['strict_success'] = exit_code == 0 and bool(summary) and int(summary[-1][1]) == 0 and not engine_errors and report_consistent
    receipt['runs'].append(item)
    receipt['source_after'] = sources()
    receipt['source_changes_during_execution'] = [name for name in sorted(set(receipt['source_before']) | set(receipt['source_after'])) if receipt['source_before'].get(name) != receipt['source_after'].get(name)]
    receipt_path.write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(item), flush=True)
    if not item['strict_success'] or receipt['source_changes_during_execution']:
        raise SystemExit(1)
print('RENDER BUDGET EXCLUSIVE CHECKS COMPLETE ' + str(receipt_path), flush=True)
