# Android-Audiopuffer: gesicherter Fehler 054

Der [instrumentierte Lauf 37481573580](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37481573580) beendet die QA-Prüfung nach beobachtetem Prozessverlust. [Android Exit-info](failure-exit-info.txt) bestätigt einen nativen Absturz mit Signal 11; [der ursprüngliche Crashauszug](native-crash-excerpt.log) nennt den Thread `AudioTrack`. [Status und APK-Hash](runtime-status.json), [Artefakt-Provenienz](provenance.json).

Die Camp-Musik enthält 264.600 Mono-Frames mit jeweils zwei Bytes: 529.200 Bytes. Die bisherige Schleifengrenze `loop_end=count` liegt einen Frame hinter dem letzten gültigen Sample. [Godot 4.7.2](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/resources/audio_stream_wav.cpp#L344) mischt bis zu dieser Grenze einschließlich und fügt dem PCM-Puffer beim Zuweisen keine Padding-Samples hinzu.

Der Crash zeigt `rsi=0x40998`, also Sample 264.600. Fehleradresse `0x7b3c93724000` minus PCM-Basis `r13=0x7b3c936a2cd0` ergibt genau 529.200 Bytes: den ersten Zugriff hinter den Puffer. Die Godot-Frames im Android-Binary sind nicht symbolisiert; Register, Speicheradresse, Samplezahl und der Mixer-Quelltext stimmen jedoch exakt überein.

Die Korrektur setzt für Camp und Dungeon `loop_end=count-1`, den letzten gültigen Frame. PCM, 22.050-Hz-Abtastrate und Kampfsounds bleiben erhalten. Die Audio-Regression muss beide tatsächlichen WAV-Playbacks mehrfach über die Schleifengrenze mischen; die endgültige Bestätigung erfolgt im erneuten vollständigen Android-Lauf.
