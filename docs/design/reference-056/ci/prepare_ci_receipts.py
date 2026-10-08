#!/usr/bin/env python3
"""Summarize locally saved, original current-source Actions evidence.

No network, engine, branch mutation or binary artifact download. Inputs are
real completed job metadata and unchanged original decoded GitHub job logs.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse, hashlib, json, re

parser=argparse.ArgumentParser()
parser.add_argument('--source',required=True)
parser.add_argument('--directory',type=Path,required=True)
args=parser.parse_args()
assert re.fullmatch(r'[a-f0-9]{40}',args.source)
directory=args.directory
timestamp=datetime.now(timezone.utc).isoformat()
mapping={'gameplay':'Gameplay Quality','android-debug':'Android Debug APK','android-runtime':'Android Beta Runtime'}
all_receipts=[]
for key,name in mapping.items():
 metadata=json.loads((directory/f'{key}-run.json').read_text())
 jobs=json.loads((directory/f'{key}-jobs.json').read_text())['jobs']
 assert metadata['name']==name and metadata['head_sha']==args.source,(key,'run identity')
 assert metadata['status']=='completed', (key,'unfinished run')
 main_jobs=[job for job in jobs if job.get('name') in ('regression','android-debug','build','offline-runtime')]
 assert len(main_jobs)==1,(key,'unexpected main job inventory',[job.get('name') for job in jobs])
 job=main_jobs[0]
 assert job['status']=='completed',(key,'unfinished job')
 path=directory/f'{key}-original-job.log'
 raw=path.read_bytes();text=raw.decode('utf-8')
 checkout_lines=re.findall(r'git log -1 --format=%H\r?\n[^\n]*?([a-f0-9]{40})\r?\n',text)
 assert len(checkout_lines)==1,(key,'actual checkout SHA not recorded exactly once')
 python_results=[int(n) for n in re.findall(r'Ran (\d+) tests in ',text)]
 suite_results=[]
 if key=='gameplay':
  for title,checks in re.findall(r'PASS ([A-Z][A-Z /]+(?:SMOKE)?): (\d+) checks',text):
   suite_results.append({'suite':title,'checks':int(checks),'failures':0})
  beta=re.findall(r'BETA CHECKS: (\d+) Godot suites, (\d+) checks, (\d+) failures',text)
  beta_result=dict(zip(('godot_suites','godot_checks','godot_failures'),map(int,beta[-1]))) if beta else None
 else:
  for title,checks,failures in re.findall(r'([A-Z][A-Z /]+ SMOKE|SOURCE AVATAR(?: GRIP| ATTACK)?): (\d+) checks, (?:\d+ actual poses, )?(\d+) failures',text):
   suite_results.append({'suite':title,'checks':int(checks),'failures':int(failures)})
  beta_result=None
 exported=[{'checks':int(n),'failures':int(f)} for n,f in re.findall(r'EXPORTED AVATAR SMOKE: (\d+) checks, (\d+) failures',text)]
 markers=[{'launch':int(launch),'elapsed_seconds':float(elapsed),'pids':json.loads(pids),'marker':marker.strip(),'original_line':line} for line,launch,elapsed,pids,marker in re.findall(r'([^\n]*ANDROID_RUNTIME_MARKER verified launch=(\d+) elapsed_seconds=([\d.]+) pids=(\[[^\]]*\]) marker=([^\n]*))',text)]
 diagnostics=[line for line in text.splitlines() if re.search(r'SCRIPT ERROR:|SHADER ERROR:|Shader compilation failed|Parse Error:|Compile Error:|ERROR:|Process completed with exit code [1-9]',line)]
 summary_lines=[line for line in text.splitlines() if re.search(r'HEAD is now|git log -1|BETA CHECKS:|PASS [A-Z][A-Z /]+(?:SMOKE)?: \d+ checks|EXPORTED AVATAR SMOKE:|Ran \d+ tests in|ANDROID_RUNTIME_MARKER|ANDROID.*VERIFIED|Exporting res://tests/.*\.apk|Verified using v[234] scheme|\.aab.*valid|Bundle.*valid|SCRIPT ERROR:|SHADER ERROR:|Shader compilation failed|Parse Error:|Compile Error:|ERROR:',line)]
 summary='\n'.join(summary_lines)+'\n'
 summary_path=directory/f'{key}-summary.log';summary_path.write_text(summary)
 receipt={'schema':1,'observed_at':timestamp,'source_commit':args.source,'actual_checkout_commit':checkout_lines[0],'workflow':name,'workflow_run':metadata['id'],'job_id':job['id'],'run_url':metadata['html_url'],'job_url':job.get('html_url') or metadata['html_url']+'/job/'+str(job['id']),'run_conclusion':metadata['conclusion'],'job_conclusion':job['conclusion'],'python_test_runs':python_results,'suites':suite_results,'exported_pck_results':exported,'verified_android_markers':markers,'diagnostic_lines':diagnostics,'original_log_sha256':hashlib.sha256(raw).hexdigest(),'original_log_bytes':len(raw),'summary_sha256':hashlib.sha256(summary_path.read_bytes()).hexdigest(),'scope':'Actual current-source hosted CI source-tree, resource/package, and Android emulator checks only. No physical phone frame-time, thermals, battery, touch or beta-readiness assertion.'}
 if beta_result:receipt.update(beta_result)
 if suite_results and key!='gameplay':receipt.update(godot_suites=len(suite_results),godot_checks=sum(s['checks'] for s in suite_results),godot_failures=sum(s['failures'] for s in suite_results))
 (directory/f'{key}-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
 all_receipts.append(receipt)
print(json.dumps([{'workflow':r['workflow'],'run_conclusion':r['run_conclusion'],'job_conclusion':r['job_conclusion'],'checkout':r['actual_checkout_commit'],'suites':r.get('godot_suites'),'checks':r.get('godot_checks'),'failures':r.get('godot_failures'),'python_test_runs':r['python_test_runs'],'markers':len(r['verified_android_markers']),'diagnostic_lines':len(r['diagnostic_lines'])} for r in all_receipts],indent=2))
