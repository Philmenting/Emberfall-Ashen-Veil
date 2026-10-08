#!/usr/bin/env python3
"""Launch the full native capture orchestrator in an independent Linux session.

Scratch supervision only. This file never edits game inputs or substitutes
partial recordings. A successful launcher exit means only daemon launch, while
the supervisor records the actual eventual orchestrator wait exit separately.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
REPO = Path('/workspace/Emberfall-Ashen-Veil')
RUNNER = HERE / 'run_six_full_captures.py'


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write_json(path, value):
    temporary = path.with_name(path.name + '.tmp')
    temporary.write_text(json.dumps(value, indent=2, allow_nan=False) + '\n')
    temporary.replace(path)


def utc():
    return time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())


def supervise(request_path):
    signal.signal(signal.SIGHUP, signal.SIG_IGN)
    request = json.loads(request_path.read_text())
    receipt_path = Path(request['supervisor_receipt'])
    record = {'schema': 1, 'status': 'running_not_completed', 'started_utc': utc(),
              'source_commit': request['source_commit'], 'pid': os.getpid(),
              'parent_pid': os.getppid(), 'session_id': os.getsid(0),
              'request_sha256': digest(request_path), 'command': request['command'],
              'scope': 'Detached scratch supervisor; actual completion depends on all native receipts and strict comparisons.'}
    write_json(receipt_path, record)
    environment = os.environ.copy()
    environment.update(LP_NUM_THREADS='4', DISPLAY=request['display'])
    started = time.monotonic()
    try:
        with Path(request['orchestrator_log']).open('xb') as stream:
            child = subprocess.Popen(request['command'], cwd=request['repo'], env=environment,
                                     stdin=subprocess.DEVNULL, stdout=stream,
                                     stderr=subprocess.STDOUT, close_fds=True)
            record['orchestrator_pid'] = child.pid
            record['orchestrator_session_id'] = os.getsid(child.pid)
            write_json(receipt_path, record)
            result = child.wait()
        record.update(status='orchestrator_exited', actual_orchestrator_wait_exit=result,
                      completed_utc=utc(), wall_seconds=round(time.monotonic() - started, 3))
        session_path = Path(request['session_dir']) / 'session-receipt.json'
        if session_path.is_file():
            session = json.loads(session_path.read_text())
            record.update(final_session_status=session.get('status'),
                          final_session_receipt_sha256=digest(session_path))
            if result == 0 and session.get('status') == 'six_complete_native_recordings_and_three_verified_full_comparisons':
                record['status'] = 'six_full_native_recordings_completed_and_compared'
        write_json(receipt_path, record)
        return result
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        record.update(status='supervisor_failed', error=str(error), completed_utc=utc(),
                      wall_seconds=round(time.monotonic() - started, 3))
        write_json(receipt_path, record)
        return 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--supervise-request', type=Path, help=argparse.SUPPRESS)
    parser.add_argument('--source-commit')
    parser.add_argument('--evidence', type=Path)
    parser.add_argument('--session-dir', type=Path)
    parser.add_argument('--repo', type=Path, default=REPO)
    parser.add_argument('--godot', default='/workspace/scratch/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64')
    parser.add_argument('--display', default=':108')
    parser.add_argument('--exclusive-render-slot', action='store_true')
    args = parser.parse_args()
    if args.supervise_request:
        return supervise(args.supervise_request.resolve())
    if not args.exclusive_render_slot:
        parser.error('Root must explicitly grant the exclusive Engine slot; no Engine starts before that grant')
    if not args.source_commit or not re.fullmatch(r'[0-9a-f]{40}', args.source_commit):
        parser.error('An exact final 40-character source commit is required')
    if args.evidence is None or args.session_dir is None:
        parser.error('Fresh evidence and session directories are required')
    evidence, session_dir = args.evidence.resolve(), args.session_dir.resolve()
    if evidence == HERE or evidence.exists() and any(evidence.iterdir()):
        parser.error('Use fresh evidence; every interrupted historical attempt remains untouched')
    if session_dir.exists() and any(session_dir.iterdir()):
        parser.error('Use a fresh session directory')
    if not session_dir.is_relative_to(evidence):
        parser.error('The session directory must be inside the fresh evidence directory')
    subprocess.run(['git', 'cat-file', '-e', args.source_commit + '^{commit}'],
                   cwd=args.repo, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    # Match real executable argv[0], not command text mentioning its path.
    live_engine_pids = []
    for proc in Path('/proc').iterdir():
        if not proc.name.isdigit():
            continue
        try:
            state = (proc / 'stat').read_text().split(') ', 1)[1].split()[0]
            executable = (proc / 'cmdline').read_bytes().split(b'\0', 1)[0].decode(errors='replace')
            if state != 'Z' and Path(executable).name.lower().startswith('godot'):
                live_engine_pids.append(int(proc.name))
        except (FileNotFoundError, PermissionError, IndexError, ProcessLookupError):
            continue
    if live_engine_pids:
        parser.error('A live Godot process still owns the engine: ' + repr(live_engine_pids))
    evidence.mkdir(parents=True, exist_ok=True)
    for name in ('baseline-fixture-overlay-receipt-v2.json', 'run_six_full_captures.py', 'launch_detached_full_captures.py'):
        os.link(HERE / name, evidence / name)
    request_path = evidence / 'detached-launch-request.json'
    request = {'schema': 1, 'source_commit': args.source_commit, 'repo': str(args.repo.resolve()),
               'evidence': str(evidence), 'session_dir': str(session_dir), 'display': args.display,
               'command': [sys.executable, str(evidence / RUNNER.name), '--source-commit', args.source_commit,
                           '--repo', str(args.repo.resolve()), '--evidence', str(evidence),
                           '--session-dir', str(session_dir), '--godot', args.godot,
                           '--display', args.display, '--exclusive-render-slot'],
               'orchestrator_log': str(evidence / 'detached-orchestrator-console.log'),
               'supervisor_receipt': str(evidence / 'detached-supervisor-receipt.json'),
               'launcher_sha256': digest(Path(__file__)), 'scratch_orchestrator_sha256': digest(RUNNER),
               'scope': 'Six new full recordings; no interrupted partial clip is reused as completion.'}
    write_json(request_path, request)
    with (evidence / 'detached-supervisor-console.log').open('xb') as stream:
        daemon = subprocess.Popen([sys.executable, str(Path(__file__).resolve()), '--supervise-request', str(request_path)],
                                  cwd=args.repo, stdin=subprocess.DEVNULL, stdout=stream,
                                  stderr=subprocess.STDOUT, start_new_session=True, close_fds=True)
    sid = os.getsid(daemon.pid)
    if sid != daemon.pid:
        raise RuntimeError('Detached supervisor did not become its own session leader')
    launch = {'schema': 1, 'status': 'detached_daemon_launched_not_capture_complete',
              'launched_utc': utc(), 'source_commit': args.source_commit, 'pid': daemon.pid,
              'session_id': sid, 'start_new_session': True, 'stdio_bound_to_files_or_devnull': True,
              'request_sha256': digest(request_path), 'launcher_sha256': digest(Path(__file__)),
              'scope': 'Protects against exec-session process-group cleanup; not a guarantee against complete machine shutdown.'}
    write_json(evidence / 'detached-launch-receipt.json', launch)
    print(json.dumps(launch, indent=2), flush=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
