extends Node
## Original synthesized score and cues. Never called by offline/forecast simulation.
const Preferences = preload("res://scripts/game_preferences.gd")
const RATE := 11025
const VOICES := 6
static var bank: Dictionary = {}
var preferences := Preferences.DEFAULTS.duplicate()
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
var suspended := false
var context := ""
var last_played: Dictionary = {}
var last_haptic := -1000

func _ready() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	for i in range(VOICES):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	apply_preferences(preferences)

func _exit_tree() -> void:
	# Explicitly detach paused streams before AudioServer releases their playback.
	if is_instance_valid(music):
		music.stream_paused=false
		music.stop()
		music.stream=null
	for voice in voices:
		voice.stop()
		voice.stream=null
	bank.clear()

func apply_preferences(values: Dictionary) -> void:
	preferences = Preferences.normalize(values)
	if not is_instance_valid(music): return
	music.volume_db = _volume(preferences.master*preferences.music*0.25)
	music.stream_paused = suspended or preferences.master*preferences.music<=0.0
	for voice in voices:
		voice.volume_db = _volume(preferences.master*preferences.effects*0.3)
		if preferences.master*preferences.effects<=0.0: voice.stop()

func _volume(value: float) -> float:
	return linear_to_db(value) if value>0.0 else -80.0

func set_context(in_dungeon: bool) -> void:
	var next := "dungeon" if in_dungeon else "camp"
	if context==next: return
	context=next
	music.stream=stream_for(next)
	if AudioServer.get_driver_name()!="Dummy": music.play()
	music.stream_paused=suspended or preferences.master*preferences.music<=0.0

func set_suspended(value: bool) -> void:
	suspended=value
	if not is_instance_valid(music): return
	music.stream_paused=value or preferences.master*preferences.music<=0.0
	if value:
		for voice in voices: voice.stop()

func cue(key: String) -> void:
	if suspended or voices.is_empty() or preferences.master*preferences.effects<=0.0: return
	var now:=Time.get_ticks_msec()
	# A multi-target hit produces one contact sound, not a stack of identical peaks.
	if now-int(last_played.get(key,-1000))<80: return
	last_played[key]=now
	var voice:=voices[cursor]
	cursor=(cursor+1)%VOICES
	voice.stream=stream_for(key)
	if AudioServer.get_driver_name()!="Dummy": voice.play()

func combat_events(events: Array,class_key: String) -> void:
	if not suspended and preferences.haptics and OS.has_feature("android"):
		var pulse:=haptic_duration(events)
		var now:=Time.get_ticks_msec()
		if pulse>0 and now-last_haptic>=180:
			Input.vibrate_handheld(pulse,0.35)
			last_haptic=now
	for event in events:
		match String(event.type):
			"hero_attack":
				if event.has("ability_id"):
					var key: String=event.ability_id
					cue("lightning" if key=="chain" else "starfall" if key=="starfall" else "ward" if key in ["bastion","frost_ward","smoke"] else "oath" if key in ["sunder","judgment"] else "volley")
					continue
				cue("oath" if class_key=="Vowkeeper" else ("nova" if class_key=="Arcanist" else "volley")) if event.skill else cue("swing" if class_key=="Vowkeeper" else "bolt")
			"hit": cue("impact" if class_key=="Vowkeeper" else "arcane_contact" if class_key=="Arcanist" else "arrow_contact")
			"hero_hit": cue("hurt")
			"warning": cue("warning")
			"ward": cue("ward")
			"evade", "backstep": cue("step")

static func stream_for(key: String) -> AudioStreamWAV:
	if bank.has(key): return bank[key]
	var ambient:=key in ["camp","dungeon"]
	var duration:=12.0 if ambient else float({"ui":0.07,"swing":0.24,"bolt":0.22,"impact":0.18,"hurt":0.25,"oath":0.8,"nova":0.85,"volley":0.6,"warning":0.55,"step":0.12,"ward":0.3,"lightning":0.45,"starfall":0.65,"victory":1.8,"defeat":1.3}.get(key,0.2))
	var count:=int(duration*RATE)
	var bytes:=PackedByteArray()
	bytes.resize(count*2)
	var random:=RandomNumberGenerator.new()
	random.seed=key.hash()
	var filtered:=0.0
	for i in range(count):
		var t:=float(i)/RATE
		var progress:=t/duration
		var noise:=random.randf_range(-1.0,1.0)
		filtered=lerpf(filtered,noise,0.08)
		var sample:=0.0
		if ambient:
			# Frequencies have integral cycles over 12 seconds; loop edges fade to zero.
			var root:=55.0 if key=="camp" else 49.0
			sample=0.19*sin(TAU*root*t)+0.09*sin(TAU*root*1.5*t)+0.06*sin(TAU*(65.5 if key=="camp" else 58.25)*t)
			sample*=0.6+0.25*sin(TAU*t/6.0)
			var bell_time:=fmod(t,1.5)
			var note: float=[220.0,261.6256,293.6648,329.6276,293.6648,261.6256,246.9417,220.0][int(t/1.5)%8]
			var overtone:=2.756 if key=="dungeon" else 2.0
			sample+=(0.11*sin(TAU*note*bell_time)+0.035*sin(TAU*note*overtone*bell_time)*exp(-bell_time*4.0))*exp(-bell_time*2.6)*minf(1.0,bell_time*50.0)
			sample*=minf(1.0,t/0.25)*minf(1.0,(duration-t)/0.25)
		else:
			match key:
				"ui": sample=0.25*sin(TAU*660*t)*exp(-t*60)
				"swing", "step": sample=filtered*2.3+noise*0.12
				"bolt", "volley": sample=0.2*sin(TAU*(500*t-180*t*t))+filtered*1.2
				"impact": sample=0.33*sin(TAU*130*t)*exp(-t*24)+noise*0.24*exp(-t*48)
				"arcane_contact": sample=0.22*sin(TAU*(420*t-350*t*t))*exp(-t*16)+noise*0.09*exp(-t*30)
				"arrow_contact": sample=noise*0.3*exp(-t*60)+0.2*sin(TAU*210*t)*exp(-t*26)
				"hurt": sample=0.27*sin(TAU*(100*t-90*t*t))+filtered*0.6
				"oath": sample=0.24*sin(TAU*82.5*t)+0.11*sin(TAU*330*t)*exp(-t*4)+filtered*0.8
				"nova": sample=0.2*sin(TAU*(180*t+160*t*t))+0.08*sin(TAU*523.25*t)+filtered
				"warning": sample=0.2*sin(TAU*155.5*t)*(0.65+0.35*sin(TAU*8*t))
				"lightning": sample=0.12*sin(TAU*780*t)*exp(-t*5)+noise*0.3*exp(-t*8)+filtered*0.4
				"starfall": sample=0.24*sin(TAU*(130*t-80*t*t))+filtered*1.2*exp(-t*4)
				"ward": sample=0.11*sin(TAU*392*t)*exp(-t*8)+0.05*sin(TAU*587.33*t)*exp(-t*12)
				"victory":
					for n in range(3):
						var age:=t-n*0.17
						if age>=0: sample+=0.16*sin(TAU*float([220,261.6256,329.6276][n])*age)*exp(-age*2.6)*minf(1.0,age*80)
				"defeat": sample=0.25*sin(TAU*(98*t-12*t*t))+0.12*sin(TAU*58.25*t)
			sample*=minf(1.0,t*250.0)*pow(1.0-progress,1.5)*minf(1.0,(duration-t)*100)
		bytes.encode_s16(i*2,int(clampf(sample,-0.5,0.5)*32767))
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=RATE
	stream.data=bytes
	if ambient:
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		stream.loop_end=count
	bank[key]=stream
	return stream

static func haptic_duration(events: Array) -> int:
	var duration:=0
	for event in events:
		if event.get("type")=="hero_hit": duration=maxi(duration,24)
		elif event.get("type")=="hit" and event.get("critical",false): duration=maxi(duration,14)
		elif event.get("type")=="warning": duration=maxi(duration,32)
	return duration
