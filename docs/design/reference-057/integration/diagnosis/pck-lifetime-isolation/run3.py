from pathlib import Path
import subprocess,os,json,hashlib,time
out=Path('/workspace/scratch/emberfall-quality-057/integration/pck-lifetime-isolation');entries=[]
env=os.environ.copy();env.update(LP_NUM_THREADS='4')
for name in ['new_without_class_preload','single_hexer_without_class_preload','single_hexer']:
 cmd=['/workspace/scratch/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64','--headless','--audio-driver','Dummy','--main-pack','/workspace/scratch/emberfall-quality-057/integration/package-native/native-avatar-smoke.pck','--script',str(out/(name+'.gd'))]
 start=time.monotonic();result=subprocess.run(cmd,cwd=out,env=env,capture_output=True,text=True,timeout=60);log=out/(name+'.log');log.write_text(result.stdout+result.stderr)
 entry={'name':name,'command':cmd,'actual_exit_code':result.returncode,'seconds':time.monotonic()-start,'log_sha256':hashlib.sha256(log.read_bytes()).hexdigest()};entries.append(entry);print(json.dumps(entry),flush=True)
(out/'receipt3.json').write_text(json.dumps(entries,indent=2)+'\n')
