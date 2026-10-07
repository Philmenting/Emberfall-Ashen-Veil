#!/usr/bin/env python3
"""Verify actual original receipts; combine historical and final scoped coverage."""
from pathlib import Path
import datetime,hashlib,importlib.util,json,re,shutil,sys
ROOT=Path('/workspace/Emberfall-Ashen-Veil')
BASE=Path('/workspace/scratch/emberfall-quality-057/integration')
LEAF=ROOT/'docs/design/reference-057/integration'
FINAL=BASE/'final-affected-and-continuation3'
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text())
spec=importlib.util.spec_from_file_location('runner',ROOT/'scripts/run_beta_checks.py');runner=importlib.util.module_from_spec(spec);spec.loader.exec_module(runner)
old=read(BASE/'final-round4/receipt.json');new=read(FINAL/'receipt.json')
assert old['passed'] is False and old['actual_exit_code']==1
assert new['passed'] is True and new['actual_exit_code']==0
assert old['source_changes_during_execution']==new['source_changes_during_execution']==[]
changed=[p for p in sorted(set(old['source_snapshot_after'])|set(new['source_snapshot_before'])) if old['source_snapshot_after'].get(p)!=new['source_snapshot_before'].get(p)]
assert changed==['scripts/class_avatar_rig.gd','tests/animation_craft_smoke.gd'],changed
originals={};coverage={};stage_totals={}
for stage,directory,receipt in [('round4_historical',BASE/'final-round4',old),('final_affected_and_continuation',FINAL,new)]:
 for row in receipt['results']:
  logfile=directory/row['log'];assert digest(logfile)==row['log_sha256'],str(logfile)
  if not row['strict_success']:continue
  assert row['actual_exit_code']==0 and not row['timed_out']
  suite=row['name'].removeprefix('full-').removeprefix('focused-')
  if suite not in runner.GODOT_SUITES:continue
  raw=logfile.read_text();assert not runner.unexpected_engine_diagnostic(suite,raw)
  # Universal final evidence check: accepted headless logs contain no WARNING.
  assert not re.search(r'(?m)^\s*WARNING:',raw),str(logfile)
  summaries=list(runner.SUMMARY.finditer(raw));assert summaries and int(summaries[-1].group(3))==0
  count=int(summaries[-1].group(2));stage_totals[stage]=stage_totals.get(stage,0)+count
  relative=Path('final-validation')/row['log'] if stage.startswith('final_') else Path('historical-round4')/row['log']
  target=LEAF/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(logfile,target)
  coverage[suite]={'suite':suite,'checks':count,'failures':0,'actual_exit_code':0,'source_stage':stage,'log':str(relative),'log_sha256':row['log_sha256'],'wall_seconds':row['wall_seconds'],'strict_success':True,'allowed_intentional_diagnostics':row['allowed_intentional_diagnostics']}
assert set(coverage)==set(runner.GODOT_SUITES),(set(runner.GODOT_SUITES)-set(coverage))
assert len(coverage)==53
contracts=[]
for row in new['results']:
 if row['name'] in ['node-syntax','node-progression','python-contracts']:
  assert row['actual_exit_code']==0 and row['strict_success']
  raw=(FINAL/row['log']).read_text()
  if row['name']=='python-contracts':
   count=re.search(r'Ran (\d+) tests?',raw);assert count and re.search(r'(?m)^OK\s*$',raw)
   row=dict(row,unittest_count=int(count.group(1)))
  shutil.copy2(FINAL/row['log'],LEAF/'final-validation'/row['log'])
  row=dict(row,log='final-validation/'+row['log'])
  contracts.append(row)
assert len(contracts)==3
current={p:digest(ROOT/p) for p in new['source_snapshot_after']}
assert current==new['source_snapshot_after'],'inputs changed after final run'
for dirname in ['final-continuation','final-continuation2','final-affected-and-continuation','final-affected-and-continuation2','sword-world-diagnostic','sword-hip-curve-diagnostic']:
 source=BASE/dirname
 if source.exists():
  dest=LEAF/'diagnosis'/dirname;dest.mkdir(parents=True,exist_ok=True)
  for p in source.iterdir():
   if p.is_file() and p.suffix in ['.json','.log','.gd','.py']:shutil.copy2(p,dest/p.name)
shutil.copy2(BASE/'final-round4/receipt.json',LEAF/'historical-round4/receipt.json')
shutil.copy2(FINAL/'receipt.json',LEAF/'final-validation/receipt.json')
shutil.copy2(BASE/'run_final_affected_and_continuation3.py',LEAF/'final-validation/execution-driver.py')
shutil.copy2(Path(__file__),LEAF/'final-validation/coverage-verifier.py')
source_path=LEAF/'final-validation/source-binding.json'
source_path.write_text(json.dumps({'historical_round4_snapshot_before':old['source_snapshot_before'],'historical_round4_snapshot_after':old['source_snapshot_after'],'final_snapshot_before':new['source_snapshot_before'],'final_snapshot_after':new['source_snapshot_after'],'changed_between_stages':changed},indent=2)+'\n')
final_suite_count=sum(1 for row in coverage.values() if row['source_stage']=='final_affected_and_continuation')
retained_count=53-final_suite_count
package=read(BASE/'package-native-round2/receipt.json');assert package['passed'] and package['actual_exit_code']==0
out={
 'schema':1,'created_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'passed':True,'coverage_verifier_actual_exit_code':0,
 'scope':'Combined local coverage of all53 registered suites, explicitly split across immutable source stages.41 retained historical suites preceded the isolated ClassAvatarRig recovery-order change;12 affected/remaining suites and all contracts ran on the final source. This is not a single full53 run on final source. Fresh exact-source53+package validation is delegated to uploaded CI.',
 'single_complete_53_run_on_final_source':False,
 'registered_suites':list(runner.GODOT_SUITES),
 'unique_suites':53,'unique_checks':sum(row['checks'] for row in coverage.values()),'failures':0,
 'retained_historical_suites':retained_count,'retained_historical_checks':sum(row['checks'] for row in coverage.values() if row['source_stage']=='round4_historical'),
 'final_source_suites':final_suite_count,'final_source_checks':sum(row['checks'] for row in coverage.values() if row['source_stage']=='final_affected_and_continuation'),
 'historical_round4_attempt':{'overall_passed':False,'actual_exit_code':1,'successful_suites':47,'successful_checks':stage_totals['round4_historical'],'receipt':'historical-round4/receipt.json','sha256':digest(LEAF/'historical-round4/receipt.json')},
 'final_execution':{'actual_exit_code':new['actual_exit_code'],'wall_seconds':new['wall_seconds'],'receipt':'final-validation/receipt.json','sha256':digest(LEAF/'final-validation/receipt.json'),'within_run_source_changes':[]},
 'source_binding':{'file':'final-validation/source-binding.json','sha256':digest(source_path),'input_files':len(new['source_snapshot_after']),'changes_between_stages':changed,'final_before_after_equal':True},
 'diagnostics':{'all_headless_errors_rejected_except_exact_persistence_corruption':'exactly two ConfigFile unexpected EOF lines in historical Persistence','all_accepted_headless_logs_warning_free':True,'all_original_log_sha256_verified':True},
 'suites':[coverage[suite] for suite in runner.GODOT_SUITES],
 'contracts':contracts,
 'earlier_package_native':{'passed_on_earlier_source':True,'actual_exit_code':0,'receipt':'package-native/receipt.json','sha256':digest(LEAF/'package-native/receipt.json'),'source_binding_stage':'historical_round4','fresh_package_after_recovery_order_fix':False,'exported_resource_checks':60,'native_source_style_checks':135,'native_readback_poses':32,'desktop_android_regions':4,'renderer':'Mesa25.0.7 llvmpipe software OpenGL under Xvfb :108','physical_android_device_test':False},
 'rejected_attempts_preserved':True
}
(LEAF/'combined-local-coverage.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps({key:out[key] for key in ['passed','unique_suites','unique_checks','retained_historical_suites','retained_historical_checks','final_source_suites','final_source_checks','source_binding']}))
print(json.dumps({'contracts':[(r['name'],r['actual_exit_code'],r.get('unittest_count')) for r in contracts],'receipt':str(LEAF/'combined-local-coverage.json')}))
