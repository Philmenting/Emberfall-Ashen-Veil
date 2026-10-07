#!/usr/bin/env python3
"""Read-only source-preserving derivative of the exact055native first900frames."""
from pathlib import Path
import gzip,hashlib,json,subprocess,sys,time
ROOT=Path('/workspace/Emberfall-Ashen-Veil')
sys.path.insert(0,str(ROOT/'tools'))
from capture_arcanist_quality import digest,write_json,verify_record,verify_audio_record
from analyze_combat_quality import scan_pcm,compare_rows
SOURCE=ROOT/'docs/design/reference-055/gameplay/after'
OUT=Path('/workspace/scratch/emberfall-quality-056/before-first30')
FRAMES=900
SECONDS=30
RATE=44100
SAMPLE_FRAMES=SECONDS*RATE
PCM_BYTES=SAMPLE_FRAMES*8
start=time.monotonic()
if OUT.exists() and any(OUT.iterdir()):raise SystemExit('Refusing to overwrite baseline derivative evidence')
OUT.mkdir(parents=True,exist_ok=True)
source_receipt=json.loads((SOURCE/'receipt.json').read_text())
source_movie=SOURCE/'ordinary-arcanist-complete.mp4'
assert source_receipt['status']=='complete'
assert digest(source_movie)==source_receipt['mp4_sha256']
original_log=SOURCE/'frames.jsonl'
assert digest(original_log)==source_receipt['frame_log_sha256']
lines=original_log.read_bytes().splitlines(keepends=True)[:FRAMES]
rows=[json.loads(line) for line in lines]
assert len(rows)==FRAMES
clock,sample,rate=0.0,0,None
for frame,row in enumerate(rows):
 clock=verify_record(row,frame,clock)
 sample,rate=verify_audio_record(row,frame,sample,rate)
assert sample==SAMPLE_FRAMES and rate==RATE and not rows[-1]['finished'] and not rows[-1]['won']
(OUT/'frames.jsonl').write_bytes(b''.join(lines))
# Preserve exact original float32 bytes. AAC is encoded from these samples,
# rather than trimming/reencoding the earlierAACwithitspriming/framepadding.
with gzip.open(SOURCE/'native-game-audio.f32le.gz','rb') as stream,(OUT/'native-game-audio.f32le').open('wb') as dest:
 remaining=PCM_BYTES
 while remaining:
  block=stream.read(min(65536,remaining))
  if not block:raise RuntimeError('Baseline nativePCM unexpectedly ended before30seconds')
  dest.write(block);remaining-=len(block)
video_command=['ffmpeg','-hide_banner','-loglevel','warning','-i',str(source_movie),'-map','0:v:0','-frames:v',str(FRAMES),'-an','-c:v','libx264','-preset','veryfast','-crf','20','-threads','2','-pix_fmt','yuv420p','-movflags','+faststart',str(OUT/'derived-video-only.mp4')]
with (OUT/'ffmpeg-derive.log').open('wb') as log:subprocess.run(video_command,check=True,stdout=subprocess.DEVNULL,stderr=log,timeout=120)
mux_command=['ffmpeg','-hide_banner','-loglevel','warning','-i',str(OUT/'derived-video-only.mp4'),'-f','f32le','-ar',str(RATE),'-ac','2','-i',str(OUT/'native-game-audio.f32le'),'-map','0:v:0','-map','1:a:0','-c:v','copy','-c:a','aac','-b:a','128k','-movflags','+faststart',str(OUT/'ordinary-arcanist-first30s.mp4')]
with (OUT/'ffmpeg-mux.log').open('wb') as log:subprocess.run(mux_command,check=True,stdout=subprocess.DEVNULL,stderr=log,timeout=120)
probe_command=['ffprobe','-v','error','-count_frames','-show_entries','stream=index,codec_type,codec_name,width,height,nb_read_frames,r_frame_rate,duration,sample_rate,channels','-of','json',str(OUT/'ordinary-arcanist-first30s.mp4')]
probe=json.loads(subprocess.run(probe_command,check=True,capture_output=True,text=True,timeout=120).stdout)
video,audio=probe['streams']
assert video['codec_type']=='video' and int(video['nb_read_frames'])==900 and video['r_frame_rate']=='30/1' and float(video['duration'])==30.0
assert video['width']==1200 and video['height']==536
assert audio['codec_name']=='aac' and int(audio['sample_rate'])==44100 and audio['channels']==2 and float(audio['duration'])==30.0
check=subprocess.run(['ffmpeg','-v','error','-i',str(OUT/'ordinary-arcanist-first30s.mp4'),'-f','null','-'],capture_output=True,text=True,timeout=120)
assert check.returncode==0 and not check.stderr.strip()
pcm=scan_pcm(OUT,SAMPLE_FRAMES,require_exact_length=True)
assert pcm['nonfinite_samples']==0 and 0<pcm['peak']<=1
baseline_pcm=scan_pcm(SOURCE,SAMPLE_FRAMES,require_exact_length=False)
assert baseline_pcm['full_source_sha256']==source_receipt['native_pcm_sha256'] and baseline_pcm['sha256']==pcm['sha256']
raw=OUT/'native-game-audio.f32le';archive=OUT/'native-game-audio.f32le.gz'
with raw.open('rb') as original,archive.open('wb') as dest,gzip.GzipFile(filename='',mode='wb',fileobj=dest,mtime=0) as packed:
 for block in iter(lambda:original.read(65536),b''):packed.write(block)
archive_receipt={'schema':1,'compression':'gzip lossless unchanged first1323000 native stereofloat32sampleframes','native_pcm_sha256':pcm['sha256'],'native_pcm_bytes':PCM_BYTES,'archive_sha256':digest(archive),'archive_bytes':archive.stat().st_size}
write_json(OUT/'native-pcm-archive-receipt.json',archive_receipt)
raw.unlink();(OUT/'derived-video-only.mp4').unlink()
metadata=json.loads((SOURCE/'capture-metadata.json').read_text())
receipt={'schema':1,'status':'verified_derived_prefix','recording_kind':'ordinary_expedition_prefix_derivative','frames':900,'playback_seconds':30,'simulation_finished':False,'won':False,'source_commit':'ad4d50bb9dbdc07cea42e2306a79fc65bb642489','source_mp4_file':str(source_movie.relative_to(ROOT)),'source_mp4_sha256':source_receipt['mp4_sha256'],'source_receipt_sha256':digest(SOURCE/'receipt.json'),'source_full_frame_log_sha256':digest(original_log),'prefix_frame_log_sha256':digest(OUT/'frames.jsonl'),'mp4_file':'ordinary-arcanist-first30s.mp4','mp4_sha256':digest(OUT/'ordinary-arcanist-first30s.mp4'),'first_video_frame':0,'last_video_frame':899,'native_audio':pcm,'baseline_full_native_pcm_sha256':baseline_pcm['full_source_sha256'],'decoded_video':video,'encoded_audio':audio,'full_decode_passed':True,'source_pngs_regenerated':False,'new_native_frames_rendered':False,'pixel_scope':'H264decode/reencode derivative of the unchanged055native MP4 first900frames. This is a second-lossy-encode video; its images are not new originalnativePNGcaptures. No edits, cuts inside the prefix or overlays.','audio_scope':metadata['audio_scope'],'video_derive_command':video_command,'audio_mux_command':mux_command,'stream_probe_command':probe_command,'derivation_script_sha256':digest(Path(__file__)),'chronological_prefix_verified':True,'authority_sha256':compare_rows(rows,rows)['before_authority_sha256'],'world_seed':metadata['world_seed'],'run_seed':metadata['run_seed'],'initial_stats':metadata['initial_stats'],'selected_skill_loadout':metadata['selected_skill_loadout'],'wall_seconds':round(time.monotonic()-start,3),'physical_device_performance':False}
write_json(OUT/'receipt.json',receipt)
print('BEFORE_DERIVED_PREFIX_VERIFIED',receipt['frames'],'frames,30s,source preserved,actual audio/video decode passed',receipt['mp4_sha256'])
