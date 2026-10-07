import hashlib
import json
from pathlib import Path
import re
import subprocess
import struct
from urllib.parse import unquote

repo = Path('/workspace/Emberfall-Ashen-Veil')
base = repo / 'docs/design/reference-057'
out = Path(__file__).resolve().parent
leaves = ['attire', 'hostiles', 'render-budget', 'integration', 'motion']
checks = []
issues = []
limitations = []
cache = {}

def digest(path):
    path = Path(path)
    key = (str(path), path.stat().st_size, path.stat().st_mtime_ns)
    if key not in cache:
        cache[key] = hashlib.sha256(path.read_bytes()).hexdigest()
    return cache[key]

def load(name):
    return json.loads((base / name).read_text())

def verify(path, expected, label, size=None):
    path = Path(path)
    result = {'kind': 'immutable_artifact_hash', 'label': label, 'path': str(path), 'exists': path.exists()}
    if path.exists():
        result.update({'sha256': digest(path), 'matches': digest(path) == expected, 'size_matches': size is None or path.stat().st_size == size})
    else:
        result.update({'matches': False, 'size_matches': False})
    checks.append(result)
    if not result['matches'] or not result['size_matches']:
        issues.append(result)

def commit_snapshot(commit, expected_tree, hashes, label):
    tree = subprocess.check_output(['git', 'rev-parse', commit + '^{tree}'], cwd=repo, text=True).strip()
    names = list(hashes)
    raw = subprocess.check_output(['git', 'cat-file', '--batch'], cwd=repo, input=''.join(commit + ':' + name + '\n' for name in names).encode())
    cursor = 0
    mismatches = []
    for name in names:
        end = raw.index(b'\n', cursor)
        header = raw[cursor:end].decode().split()
        assert len(header) == 3 and header[1] == 'blob', (label, name, header)
        size = int(header[2])
        actual = hashlib.sha256(raw[end + 1:end + 1 + size]).hexdigest()
        cursor = end + 1 + size + 1
        if actual != hashes[name]:
            mismatches.append(name)
    assert cursor == len(raw)
    result = {'kind': 'actual_git_blob_binding', 'label': label, 'commit': commit, 'actual_tree': tree, 'tree_matches': tree == expected_tree, 'actual_blobs': len(names), 'mismatches': mismatches}
    checks.append(result)
    if mismatches or tree != expected_tree:
        issues.append(result)

# Explicit receipt schemas prevent historic working-source hashes from being
# mistaken for current source assertions. No live gameplay file is read.
a = load('attire/execution-receipt.json')
for item in a['files']:
    verify(base / 'attire' / item['path'], item['sha256'], 'attire final original', item['bytes'])
for item in a['archived_original_native']['original_files']:
    verify(base / 'attire/native-first-tone' / Path(item['path']).name, item['sha256'], 'attire first-tone original', item['bytes'])
for item in a['runs']:
    verify(base / 'attire' / Path(item['log']).name, item['log_sha256'], 'attire actual process log')
for item in load('attire/independent-review-receipt.json')['verified_receipt_files']:
    verify(base / 'attire' / item['path'], item['expected_sha256'], 'attire prior independent hash', item['bytes'])
limitations.append({'leaf': 'attire', 'scope': 'Original execution explicitly source_not_frozen; static source-review snapshot is separately attributed and is not an original Engine source binding.'})

h = load('hostiles/native-hostile-preview-receipt.json')
for name, item in h['files'].items():
    verify(base / 'hostiles/native' / name, item['sha256'], 'hostiles final original PNG', item['bytes'])
for name, item in load('hostiles/reproduction-final-receipt.json')['files'].items():
    verify(repo / 'assets/models/hostiles057' / name, item['sha256'], 'hostiles reproduced actual asset/license', item['bytes'])
for name, expected in json.loads((repo / 'assets/models/hostiles057/manifest.json').read_text())['source_files'].items():
    path = Path(name) if name.startswith('/') else repo / name
    verify(path, expected, 'hostiles original builder input provenance')
vendor_licenses = {
    'BASE-LICENSE.txt': Path('/workspace/scratch/emberfall-character-source-052/universal-base-characters/Universal Base Characters[Standard]/License_Standard.txt'),
    'OUTFIT-LICENSE.txt': Path('/workspace/scratch/emberfall-character-source-052/modular-character-outfits-fantasy/Modular Character Outfits - Fantasy[Standard]/License_Standard.txt'),
    'ANIMATION1-LICENSE.txt': Path('/workspace/scratch/quaternius-uam-inspection/extracted/Universal Animation Library[Standard]/License.txt'),
    'ANIMATION2-LICENSE.txt': Path('/workspace/scratch/quaternius-uam-inspection/universal-animation-library-2/extracted/Universal Animation Library 2[Standard]/License.txt'),
}
for name, original in vendor_licenses.items():
    verify(original, digest(repo / 'assets/models/hostiles057' / name), 'hostiles byte-identical vendor license provenance')
hi = load('hostiles/rejected/preserved-original-index.json')
for name, item in hi['files'].items():
    verify(Path(hi['scratch_root']) / name, item['sha256'], 'hostiles preserved rejected original scratch', item['bytes'])
owned = load('hostiles/owned-source-snapshot.json')
historical_differences = []
for name, item in owned['files'].items():
    if not (repo / name).exists() or digest(repo / name) != item['sha256']:
        historical_differences.append(name)
limitations.append({'leaf': 'hostiles', 'scope': owned['scope'], 'historical_owned_snapshot_differences_from_current_source': historical_differences, 'interpretation': 'These are historical focused-source snapshots, not a claim that all current source files equal that earlier work stage.'})

rb = load('render-budget/files-receipt.json')
for item in rb['files']:
    verify(base / 'render-budget' / item['path'], item['sha256'], 'render budget original artifact', item['bytes'])
rr = load('render-budget/receipt.json')
assert rr['source_before'] == rr['source_after'] and not rr['source_changes_during_execution']
verify(Path(rr['engine_path']), rr['engine_sha256'], 'actual immutable Godot executable')
limitations.append({'leaf': 'render-budget', 'scope': '406 original source hashes remain equal before/after; execution explicitly source_not_frozen and does not claim phone frame-time or056-vs057 FPS improvement.'})

coverage = load('integration/combined-local-coverage.json')
for item in coverage['suites']:
    verify(base / 'integration' / item['log'], item['log_sha256'], 'integration combined original suite log')
for item in coverage['contracts']:
    verify(base / 'integration' / item['log'], item['log_sha256'], 'integration original contract log')
assert len({item['suite'] for item in coverage['suites']}) == coverage['unique_suites'] == 53
assert sum(item['checks'] for item in coverage['suites']) == coverage['unique_checks'] == 12980
assert coverage['single_complete_53_run_on_final_source'] is False
binding = load('integration/final-validation/commit-binding.json')
verify(base / 'integration/final-validation/receipt.json', binding['original_final_receipt_sha256'], 'integration original final receipt')
verify(base / 'integration/final-validation/source-binding.json', binding['source_binding_sha256'], 'integration original stage binding')
source = load('integration/final-validation/source-binding.json')
assert source['final_snapshot_before'] == source['final_snapshot_after']
assert sorted(name for name in source['final_snapshot_before'] if source['final_snapshot_before'][name] != source['historical_round4_snapshot_after'][name]) == sorted(source['changed_between_stages'])
commit_snapshot(binding['source_commit'], binding['source_tree'], source['final_snapshot_before'], 'integration original02 commit905 source files')
limitations.append({'leaf': 'integration', 'scope': '53-suite coverage is explicitly41 historical plus12 final-at02 suites, not a single final full-run or current1cc full-run. The later evade and workflow changes are separately bound. PCK/native original block has its own earlier source scope.'})
for name, expected in load('integration/historical-original-files.json').items():
    verify(base / 'integration' / name, expected, 'integration complete preserved original file index')
package = load('integration/package-native/receipt.json')
for command in package['commands']:
    verify(base / 'integration/package-native' / command['log'], command['log_sha256'], 'integration actual package/native command log')
export = next(command for command in package['commands'] if command['name'] == 'export-pack')
verify(Path(export['command'][-1]), package['package']['sha256'], 'integration actual original exported PCK in scratch', package['package']['bytes'])
for name, expected in load('integration/package-native/renderer-scope.json')['copied_original_capture_sha256'].items():
    verify(base / 'integration/package-native/desktop-originals' / name, expected, 'integration original DesktopGL PNG')
evidence = load('integration/package-native/desktop-art-evidence.json')
verify(base / 'integration/package-native/desktop-art-performance.json', evidence['report_sha256'], 'integration original DesktopGL report')
toe = load('integration/independent-toe-audit/execution.json')
assert toe['input_sha256_before'] == toe['input_sha256_after'] and toe['inputs_unchanged']
for name, expected in toe['input_sha256_before'].items():
    verify(Path(name), expected, 'independent toe historical actual input')
for name, expected in toe['outputs'].items():
    verify(base / 'integration/independent-toe-audit' / name, expected, 'independent toe actual output')

for receipt_name in ['motion/motion-proof-receipt.json', 'motion/final-motion-proof-receipt.json']:
    mr = load(receipt_name)
    for item in mr['original_artifacts']:
        verify(base / 'motion' / item['file'], item['sha256'], receipt_name, item['bytes'])
        if item.get('original_capture_file'):
            verify(Path(item['original_capture_file']), item['sha256'], receipt_name + ' original scratch provenance', item['bytes'])
mfinal = load('motion/final-motion-proof-receipt.json')
verify(base / 'motion/motion-proof-receipt.json', mfinal['historical_original_proof_receipt_sha256'], 'motion preserved historical receipt')
ms = load('motion/native-final/final-source-binding.json')
assert ms['source_files_sha256_before'] == ms['source_files_sha256_after'] == source['final_snapshot_before']
for key in ['native_execution_receipt', 'prior_binding_receipt', 'integration_receipt']:
    verify(Path(ms[key]), ms[key + '_sha256'], 'motion original scratch source-binding provenance')
mb = load('motion/evade-step-final/commit-binding.json')
mi = load('motion/evade-step-final/file-index.json')
for name, item in mi.items():
    verify(base / 'motion/evade-step-final' / name, item['sha256'], 'accepted evade original index', item['bytes'])
verify(base / 'motion/evade-step-final/file-index.json', mb['original_file_index_sha256'], 'accepted evade original index itself')
es = load('motion/evade-step-final/receipt.json')
commit_snapshot(mb['actual_git_commit'], mb['actual_git_tree'], es['all_tracked_non_docs_source_sha256'], 'accepted evade current1cc commit982 source files')
assert es['actual_affected_check_count'] == 4321 and es['actual_choreography_pose_count'] == 6288

png_dimensions = []
for folder, expected_size in [('attire/native', (1200, 1200)), ('attire/native-first-tone', (1200, 1200)), ('hostiles/native', (1000, 1000)), ('motion/native-accepted', (1000, 1000)), ('motion/native-final', (1000, 1000)), ('motion/evade-step-final/accepted/native/originals', (1000, 1000))]:
    for png in (base / folder).glob('*.png'):
        header = png.read_bytes()[:24]
        assert header[:8] == b'\x89PNG\r\n\x1a\n'
        actual_size = struct.unpack('>II', header[16:24])
        record = {'file': str(png.relative_to(repo)), 'actual_size': list(actual_size), 'expected_size': list(expected_size), 'matches': actual_size == expected_size}
        png_dimensions.append(record)
        if not record['matches']:
            issues.append({'kind': 'declared_png_resolution_mismatch', **record})

# Markdown navigation is checked independently of receipt hash validity.
links = []
for leaf_name in leaves:
    for md in (base / leaf_name).rglob('*.md'):
        for target in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)', md.read_text()):
            target = target.split(' "')[0].strip().strip('<>')
            if re.match(r'^[A-Za-z][A-Za-z0-9+.-]*:', target) or target.startswith('#'):
                continue
            clean = unquote(target.split('#', 1)[0].split('?', 1)[0])
            resolved = Path(clean) if clean.startswith('/') else md.parent / clean
            result = {'markdown': str(md.relative_to(repo)), 'target': target, 'exists': resolved.exists()}
            links.append(result)
            if not result['exists']:
                issues.append({'kind': 'broken_markdown_link', **result})

motion_readme = (base / 'motion/README.md').read_text()
assert '1cc13152a83c6631590d4df32ca298700a417df7' in motion_readme and '3.744' in motion_readme and '4.321' in motion_readme
assert 'frühere gemeinsame Stufe' in motion_readme and 'evade-step-final/README.md' in motion_readme
archived = base / 'motion/historical-source-02a3fc9-README.md'
assert archived.exists()
attribution_fix = {'issue_found': 'The previous authored motion README described02a3fc9/3300 as current despite the accepted1cc evade update.', 'actual_root_fix_observed': True, 'new_current_source': '1cc13152a83c6631590d4df32ca298700a417df7', 'historical02_scope_explicit': True, 'prior_authored_text_archive': str(archived.relative_to(repo)), 'archive_sha256': digest(archived), 'archive_integrity_scope': 'Archive exists and is hash-recorded now; no independent pre-edit SHA was supplied to this audit, so this audit does not claim a before/after byte comparison of the prior authored README.'}

summary = {'scope': 'Read-only completed057 feature-leaf artifact/hash/source attribution and local-link audit. No Engine, source/document edits, Git mutations or network actions. PendingCI/full-gameplay leaves and all mutable live capture files excluded. No blanket game-quality verdict.', 'leaves': leaves, 'immutable_artifact_hash_checks': sum(item['kind'] == 'immutable_artifact_hash' for item in checks), 'actual_commit_source_blob_checks': sum(item.get('actual_blobs', 0) for item in checks), 'declared_original_png_resolutions_verified': len(png_dimensions), 'markdown_local_links_checked': len(links), 'concrete_issues': issues, 'historical_scope_limitations': limitations, 'motion_authored_attribution_fix': attribution_fix}
(out / 'checks.json').write_text(json.dumps({'checks': checks, 'links': links, 'png_dimensions': png_dimensions}, indent=2) + '\n')
(out / 'report.json').write_text(json.dumps(summary, indent=2) + '\n')
print(json.dumps({key: summary[key] for key in ['immutable_artifact_hash_checks', 'actual_commit_source_blob_checks', 'markdown_local_links_checked', 'concrete_issues', 'motion_authored_attribution_fix']}))
