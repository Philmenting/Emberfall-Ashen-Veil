extends RefCounted
## Sustained frame pressure changes presentation resolution only, never simulation time.
const WARMUP_SECONDS=6.0
const WINDOW_SECONDS=2.0
var age:=0.0
var seconds:=0.0
var frames:=0
var slow_windows:=0
var fast_windows:=0
var long_frames:=0
var reduced:=false

func reset() -> void:
	age=0.0; seconds=0.0; frames=0; slow_windows=0; fast_windows=0; long_frames=0; reduced=false

func sample(delta: float,active: bool) -> bool:
	# Ignore paused play and isolated stalls such as app resume or shader import.
	if not active or delta<=0.0:
		seconds=0.0; frames=0; slow_windows=0; fast_windows=0; long_frames=0
		return reduced
	long_frames=long_frames+1 if delta>0.25 else 0
	if delta>0.25 and long_frames<3: return reduced
	# Repeated very slow frames are pressure too; cap one frame's contribution.
	delta=minf(delta,0.25)
	age+=delta
	if age<WARMUP_SECONDS: return reduced
	seconds+=delta
	frames+=1
	if seconds<WINDOW_SECONDS: return reduced
	var frame_ms:=seconds*1000.0/frames
	seconds=0.0; frames=0
	slow_windows=slow_windows+1 if frame_ms>24.0 else 0
	fast_windows=fast_windows+1 if frame_ms<18.0 else 0
	if not reduced and slow_windows>=3:
		reduced=true; slow_windows=0; fast_windows=0
	elif reduced and fast_windows>=10:
		reduced=false; slow_windows=0; fast_windows=0
	return reduced
