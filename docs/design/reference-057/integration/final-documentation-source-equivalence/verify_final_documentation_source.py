#!/usr/bin/env python3
"""Bind documentation-only work to the already tested game source; no Engine execution."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import os
import stat
import subprocess

REPO = Path('/workspace/Emberfall-Ashen-Veil')
SOURCE = '1cc13152a83c6631590d4df32ca298700a417df7'
EXPECTED_HEAD = 'f20edd1881e45f8afa42a460fc8ce0fb4ff7706b'
OUT = REPO / 'docs/design/reference-057/integration/final-documentation-source-equivalence'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=REPO)

def allowed(path):
    return path == 'README.md' or path.startswith('docs/')

def write_new(name, value):
    with (OUT / name).open('x', encoding='utf-8') as handle:
        json.dump(value, handle, indent=2)
        handle.write('\n')

assert git('rev-parse', 'HEAD').decode().strip() == EXPECTED_HEAD
assert not OUT.exists()
entries = []
for record in git('ls-tree', '-rz', SOURCE).split(b'\0'):
    if not record:
        continue
    meta, path_bytes = record.split(b'\t', 1)
    mode, kind, oid = meta.decode().split()
    path = path_bytes.decode('utf-8')
    if allowed(path):
        continue
    assert kind == 'blob', (path, kind)
    target = REPO / path
    info = target.lstat()
    if mode == '120000':
        assert stat.S_ISLNK(info.st_mode), path
        data = os.fsencode(os.readlink(target))
    else:
        assert mode in ('100644', '100755') and stat.S_ISREG(info.st_mode), path
        assert bool(info.st_mode & 0o111) == (mode == '100755'), path
        data = target.read_bytes()
    actual_oid = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
    assert actual_oid == oid, path
    entries.append({'path': path, 'git_mode': mode, 'source_git_blob': oid,
                    'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
assert len(entries) == 982, len(entries)
changes = git('diff', '--name-only', '-z', SOURCE).split(b'\0')
new_paths = git('ls-files', '--others', '--exclude-standard', '-z').split(b'\0')
for raw in changes + new_paths:
    if raw:
        assert allowed(raw.decode('utf-8')), raw.decode('utf-8')
OUT.mkdir()
write_new('inputs.json', entries)
write_new('receipt.json', {
    'schema': 1, 'observed_at': datetime.now(timezone.utc).isoformat(),
    'status': 'all_982_non_documentation_git_blobs_and_modes_match_tested_source',
    'source_commit': SOURCE, 'source_tree': git('rev-parse', SOURCE + '^{tree}').decode().strip(),
    'documentation_parent_commit': EXPECTED_HEAD, 'verified_paths': len(entries),
    'allowed_changes': ['README.md', 'docs/**'],
    'inputs_sha256': hashlib.sha256((OUT / 'inputs.json').read_bytes()).hexdigest(),
    'verifier_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'scope': 'Existing non-documentation working-tree bytes and Git executable/symlink modes, plus all tracked changes and non-ignored new paths. No Engine or test execution is implied. Final documentation commit must additionally be checked for a documentation-only diff.'
})
print('FINAL_DOCUMENTATION_SOURCE_EQUIVALENCE_OK 982 exact source blobs and Git modes; documentation-only changes')
