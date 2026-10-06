extends SceneTree
## Check actual PCM, event timing and the live preference/voice path.
const Audio=preload("res://scripts/audio_director.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run_checks.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if value: print("PASS: ",label)
	else: failures+=1; push_error("FAIL: "+label)
func rms(data: PackedByteArray,start: float,finish: float) -> float:
	var first:=int(start*Audio.RATE); var last:=mini(data.size()/2,int(finish*Audio.RATE))
	var total:=0.0
	for frame in range(first,last):
		var sample:=float(data.decode_s16(frame*2))/32767.0
		total+=sample*sample
	return sqrt(total/maxi(1,last-first))

func check_native_ambient_loops(key: String) -> void:
	var stream:=Audio.stream_for(key)
	var frame_count:=stream.data.size()/2
	check(stream.loop_begin==0 and stream.loop_end==frame_count-1 and stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"%s: native inclusive loop endpoint is inside the actual PCM allocation" % key)
	var playback:=stream.instantiate_playback()
	playback.start()
	var output_rate:=AudioServer.get_mix_rate()
	# Drive the actual native resampler/decoder through two full 12-second
	# loops. This exercises the formerly out-of-bounds decode on every wrap;
	# it does not rely on the muted/Dummy AudioStreamPlayer shortcut.
	var remaining:=int(ceil((stream.get_length()*2.0+.25)*output_rate))
	var expected_frames:=remaining
	var mixed_frames:=0; var wraps:=0
	var previous:=playback.get_playback_position()
	var finite:=true; var lengths_valid:=true; var stereo_valid:=true
	var energy:=0.0; var peak:=0.0
	while remaining>0:
		var request:=mini(4093,remaining)
		var output: PackedVector2Array=playback.mix_audio(1.0,request)
		lengths_valid=lengths_valid and output.size()==request
		for frame: Vector2 in output:
			finite=finite and frame.is_finite()
			stereo_valid=stereo_valid and is_equal_approx(frame.x,frame.y)
			energy+=frame.length_squared()
			peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)))
		mixed_frames+=output.size(); remaining-=request
		var position:=playback.get_playback_position()
		if position<previous: wraps+=1
		previous=position
	check(lengths_valid and mixed_frames==expected_frames,"%s: native mixing returns every requested output frame across both wraps" % key)
	check(finite and stereo_valid and peak>.01 and energy>1.0,"%s: native loop output stays finite and audibly nonzero in both channels" % key)
	check(wraps>=2 and playback.is_playing(),"%s: native decoder wraps twice and remains active without replacing or muting the stream" % key)
	playback.stop()

func run_checks() -> void:
	var fingerprints: Dictionary={}
	var maximum_peak:=0.0
	for key in ["arcane_gather","arcane_gather_power","arcane_gather_heavy","arcane_release","arcane_contact","arcane_critical","nova","starfall","bow_draw","impact_critical"]:
		var stream:=Audio.stream_for(key)
		var data:=stream.data
		var peak:=0
		for frame in range(data.size()/2): peak=maxi(peak,absi(data.decode_s16(frame*2)))
		maximum_peak=maxf(maximum_peak,float(peak)/32767.0)
		check(stream.mix_rate>=22050 and stream.format==AudioStreamWAV.FORMAT_16_BITS and peak>100 and peak<=16384,"%s: actual PCM has useful bandwidth, audible energy and bounded peaks" % key)
		check(data.decode_s16(0)==0 and absi(data.decode_s16(data.size()-2))<50,"%s: attack and tail have quiet edges" % key)
		check(rms(data,.25,.50)>.005 if key=="arcane_gather_heavy" else rms(data,.02,.10)>.005,"%s: actual cue has sustained audible content beyond its initial impulse" % key)
		var fingerprint:=data.hex_encode().sha256_text()
		check(not fingerprints.has(fingerprint),"%s: gather, basic release, Nova, heavy descent and contact have distinct PCM" % key)
		fingerprints[fingerprint]=true
	check(rms(Audio.stream_for("arcane_gather").data,.08,.16)>rms(Audio.stream_for("arcane_gather").data,.0,.035),"basic anticipation rises toward the visible release")
	check(rms(Audio.stream_for("arcane_contact").data,.02,.07)>rms(Audio.stream_for("arcane_contact").data,.14,.20),"body contact loses energy promptly instead of becoming a sustained alarm")
	for key in ["camp","dungeon"]: check_native_ambient_loops(key)
	check(Audio.combat_cues([{"type":"hero_attack","skill":false}],"Arcanist")==["arcane_gather"],"committing a basic cast starts anticipation alone")
	check(Audio.combat_cues([{"type":"hero_release","skill":false}],"Arcanist")==["arcane_release"],"the actual palm/projectile release starts the basic discharge")
	check(Audio.combat_cues([{"type":"hero_release","skill":true}],"Arcanist")==["nova"],"signature release uses the radial Nova phrase")
	check(Audio.combat_cues([{"type":"hero_release","skill":true,"ability_id":"starfall"}],"Arcanist")==["starfall"],"committed heavy descent uses its separate low mineral phrase")
	check(Audio.combat_cues([{"type":"hero_attack","skill":true,"ability_id":"starfall"}],"Arcanist")==["arcane_gather_heavy"],"long committed heavy cast has its own rising anticipation phrase")
	var hits: Array=[{"type":"hit","critical":false},{"type":"hit","critical":true},{"type":"hit","critical":false},{"type":"hit","critical":true}]
	check(Audio.combat_cues(hits,"Arcanist")==["arcane_critical"],"mixed multi-target hits produce one strongest contact rather than stacked peaks")
	check(Audio.combat_cues([{"type":"warning"},{"type":"warning"},{"type":"ward"},{"type":"ward"}],"Arcanist")==["warning","ward"],"duplicate warnings and wards share one cue per batch")
	var audio:=Audio.new(); root.add_child(audio)
	audio.apply_preferences({"master":1.0,"effects":1.0,"music":1.0})
	var voice_gain:=db_to_linear(audio.voices[0].volume_db)
	var music_gain:=db_to_linear(audio.music.volume_db)
	check(Audio.VOICES*voice_gain*maximum_peak+music_gain*.5<.9,"six live effects plus a bounded music bed retain mix headroom at full preferences")
	var initial:=audio.cursor
	audio.combat_events(hits,"Arcanist")
	check(audio.cursor==(initial+1)%Audio.VOICES and audio.last_played.has("arcane_critical"),"actual live multi-target batch allocates exactly one contact voice")
	initial=audio.cursor; audio.combat_events(hits,"Arcanist")
	check(audio.cursor==initial,"the existing wall-clock throttle also rejects duplicate deliveries")
	audio.apply_preferences({"master":0.0,"effects":1.0})
	audio.combat_events([{"type":"hero_release","skill":false}],"Arcanist")
	check(audio.cursor==initial,"master mute rejects new discharge voices")
	audio.free()
	print("COMBAT AUDIO SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
