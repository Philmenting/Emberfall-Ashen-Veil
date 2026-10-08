#!/usr/bin/env python3
"""Strict sequential integration and full regression; exclusive Engine slot."""
from pathlib import Path
import hashlib,importlib.util,json,os,re,subprocess,sys,time
ROOT=Path('/workspace/Emberfall-Ashen-Veil')
OUT=Path('/workspace/scratch/emberfall-quality-057/integration/final-affected-and-continuation3')
GODOT='/workspace/scratch/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
FOCUSED=('character_3d','presentation','hostile_quality','guardian_presentation','source_avatar_style','character_equipment','authored_art')
ERROR=re.compile(r'(?:^|\n)\s*(?:(?:SCRIPT|SHADER)\s+)?ERROR:|Parse Error:',re.I)
BAD_WARNING=re.compile(r'WARNING:.*(?:couldn.t resolve|shader|script|track|rendering|gpu|vulkan|opengl|uniform|material|parse)',re.I)
OUT.mkdir(parents=True,exist_ok=True)
env=os.environ.copy();env.update(GODOT_BIN=GODOT,LP_NUM_THREADS='4',DISPLAY=':108')
spec=importlib.util.spec_from_file_location('beta_check_contract',ROOT/'scripts/run_beta_checks.py');runner=importlib.util.module_from_spec(spec);spec.loader.exec_module(runner)
def snapshot():
 paths=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','--','scripts','tests','assets','tools','addons','third_party','server','.github','.gitignore','project.godot','export_presets.cfg','Main.tscn'],cwd=ROOT,text=True).splitlines()
 return {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sorted(set(paths)) if (ROOT/p).is_file()}
before=snapshot();results=[];started=time.monotonic();failed=False

def run(name,command,*,summary=None,timeout=300,scope='headless',cwd=ROOT,persistence=False):
 global failed
 run_env=env.copy()
 for key,suffix in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:run_env[key]=str(OUT/'isolated'/name/suffix)
 begin=time.monotonic()
 try:
  result=subprocess.run(command,cwd=cwd,env=run_env,capture_output=True,text=True,timeout=timeout,check=False)
  output=result.stdout+result.stderr;code=result.returncode;timed_out=False
 except subprocess.TimeoutExpired as error:
  output='\n'.join(v.decode(errors='replace') if isinstance(v,bytes) else (v or '') for v in (error.stdout,error.stderr));code=None;timed_out=True
 path=OUT/(name+'.log');path.write_text(output)
 diagnostics=runner.unexpected_engine_diagnostic('persistence' if persistence else name,output)
 exceptions=[]
 if persistence and output.splitlines().count(runner.INTENTIONAL_CORRUPT_CONFIG)==2:
  exceptions=[runner.INTENTIONAL_CORRUPT_CONFIG]*2
 matches=list(runner.SUMMARY.finditer(output)) if summary else []
 if summary:
  matches=[m for m in matches if summary in m.group(1)]
 passed=code==0 and not diagnostics and not BAD_WARNING.search(output) and (not summary or bool(matches) and int(matches[-1].group(3))==0)
 entry={'name':name,'command':command,'cwd':str(cwd),'scope':scope,'actual_exit_code':code,'timed_out':timed_out,'wall_seconds':round(time.monotonic()-begin,3),'strict_success':bool(passed),'engine_error':bool(diagnostics),'bad_warning':bool(BAD_WARNING.search(output)),'allowed_intentional_diagnostics':exceptions,'summary_matches':[list(m.groups()) for m in matches],'log':path.name,'log_sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
 results.append(entry);failed=failed or not passed
 (OUT/'live-results.json').write_text(json.dumps(results,indent=2)+'\n')
 print(json.dumps(entry),flush=True)
 return passed

version=subprocess.run([GODOT,'--version'],capture_output=True,text=True,check=False)
if version.returncode or not version.stdout.startswith('4.7.2'):raise SystemExit('wrong Godot version')
for suite in ('animation_craft','source_avatar_attack','source_avatar_attack_contact','source_avatar_evade','native_motion_transition','class_avatar_quality','character_3d','camp_hud','combat_readability','fellowship_ui','cloud_identity','mana_ward'):
 if not run('focused-'+suite,[GODOT,'--headless','--audio-driver','Dummy','--path',str(ROOT),'--fixed-fps','60','--script',f'res://tests/{suite}_smoke.gd'],summary='SOURCE AVATAR' if suite in ['source_avatar_attack'] else 'SMOKE',persistence=suite=='persistence'):
  break
if not failed:
 for name,command in [('node-syntax',['node','--check',str(ROOT/'server/modules/emberfall.js')]),('node-progression',['node',str(ROOT/'tests/progression_runtime_test.js')]),('python-contracts',[sys.executable,'-m','unittest','discover','-s','tests','-p','test_*.py','-v'])]:
  if not run(name,command,timeout=120,scope='Python/Node contracts; no external Android device'):break
after=snapshot();changes=[p for p in sorted(set(before)|set(after)) if before.get(p)!=after.get(p)]
passed=not failed and not changes
receipt={'passed':passed,'actual_exit_code':0 if passed else 1,'wall_seconds':round(time.monotonic()-started,3),'godot_version':version.stdout.strip(),'source_snapshot_before':before,'source_snapshot_after':after,'source_changes_during_execution':changes,'scope':'Seven affected headless suites after the minimal Vowkeeper recovery method-order fix, five previously unexecuted headless suites, and all Python/Node contracts. Earlier47 suites and desktop packaging/native probes belong to their own historical source bindings. No fresh package or physical-device claim.','results':results}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({'passed':passed,'source_changes_during_execution':changes,'commands_completed':len(results),'wall_seconds':receipt['wall_seconds']}),flush=True)
raise SystemExit(0 if passed else 1)
