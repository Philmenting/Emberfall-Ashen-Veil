# Drei vollständige Klassenexpeditionen: Vorher und Nachher

Die sechs unveränderten nativen Aufnahmen zeigen jeweils die gewöhnliche erste Expedition vom Start bis zum echten Guardian-Sieg und der ursprünglichen Beuteanzeige. Reiseabschnitte bleiben enthalten. Jeder Film enthält alle chronologischen Frames bei 30 Hz sowie die 90 ursprünglichen Abschlussframes; es gibt keine Schnitte oder ausgelassenen Aufnahmeschritte.

| Klasse | Vorher | Nachher | Frames je Film | Dauer | Guardian-Kampf / Warnframes nachher |
| --- | --- | --- | ---: | ---: | ---: |
| Arcanist | [Video](arcanist/before/ordinary-arcanist-complete.mp4) | [Video](arcanist/after/ordinary-arcanist-complete.mp4) | 2496 | 83.2 s | 225 / 87 |
| Ranger | [Video](ranger/before/ordinary-ranger-complete.mp4) | [Video](ranger/after/ordinary-ranger-complete.mp4) | 2559 | 85.3 s | 291 / 138 |
| Vowkeeper | [Video](vowkeeper/before/ordinary-vowkeeper-complete.mp4) | [Video](vowkeeper/after/ordinary-vowkeeper-complete.mp4) | 3099 | 103.3 s | 468 / 87 |

Die Spielquelle der Vorher-Aufnahmen ist `86cb1b8ec878b4ae06daba5e6c5a4fa583865dc5`, die der Nachher-Aufnahmen `1cc13152a83c6631590d4df32ca298700a417df7`. Beide Seiten verwenden dieselben offengelegten aktuellen Capture-Werkzeuge. Im historischen Export wurden ausschließlich zwei Capture-GDs ersetzt; alle 849 anderen exportierten Dateien blieben bytegleich zum ursprünglichen Git-Stand. Die [Overlay-Receipt](baseline-fixture-overlay-receipt-v2.json) nennt die Original- und Fixture-Hashes. Die Vergleiche binden die tatsächlichen Runtime-Eingaben einzeln an exakte Git-Blobs; nur sechs ausdrücklich erlaubte Capture-Identitäten dürfen den aktuellen Fixture-Commit verwenden.

Profilseed 1979, Runseed 95635017, normale Startausrüstung, HP, Schaden, Warnzeiten und Kamera bleiben gleich. Die klassenüblichen Techniken wurden über die reguläre Armory-Aktion ausgerüstet. Alle drei Vergleiche prüfen die vollständigen Simulationsuhren, autoritativen Positionen und Kampfzustände, Kameratransformationen sowie die tatsächlichen PCM-Bytes. Präsentationsposen und `hero_release` zählen ausdrücklich nicht zur autoritativen Simulationsprüfung.

- Arcanist: [vollständiger Vergleich](arcanist/comparison.json), [erneute Analyse nach Hardlink-Staging](arcanist/comparison-reproduced-after-hardlink.json); 3669120 Stereo-Sampleframes bei 44100 Hz, PCM-SHA256 `ae1553e7bb746cff82181785597ef5c7246900008be5f93d2f11cccf67c21316`.
- Ranger: [vollständiger Vergleich](ranger/comparison.json), [erneute Analyse nach Hardlink-Staging](ranger/comparison-reproduced-after-hardlink.json); 3761730 Stereo-Sampleframes bei 44100 Hz, PCM-SHA256 `0ba0d3a003f66e9c0006fd7f6fa0cc04a648bc146a194e3643084f42ea30fc94`.
- Vowkeeper: [vollständiger Vergleich](vowkeeper/comparison.json), [erneute Analyse nach Hardlink-Staging](vowkeeper/comparison-reproduced-after-hardlink.json); 4555530 Stereo-Sampleframes bei 44100 Hz, PCM-SHA256 `8665a2191f4f13bf4e7555c24f558e15608c617079dba423f1d552b13c70ddaa`.

Der Ton stammt aus tatsächlich akzeptierten Spiel-Cues und Musik, nativ mit `AudioStreamPlayback` decodiert und auf der festen Aufnahmezeitachse in Stereo-Float-PCM gemischt. Dies ist kein Mikrofon- oder Hardware-Loopback. Die MP4-Audiospuren sind AAC-Kodierungen dieses PCM; die ursprünglichen Bytes bleiben verlustfrei als Gzip erhalten. Die Originaljournale behalten ihre tatsächlichen `acceptance_wall_msec`-Zeitstempel aus unabhängigen Engine-Prozessen. Ausschließlich dieses Feld wird im zusätzlichen Cue-Inhaltsvergleich ausgespart; Samplegrenzen und alle übrigen Cue-Felder bleiben exakt geprüft.

Die ausgewählten PNGs jedes Films stammen unmittelbar aus Godots tatsächlichem 1200×536-Viewport. Auswahlgrund, chronologischer Frame und SHA256 stehen in der jeweiligen `receipt.json`. Es wurden keine PNGs skaliert, zusammengesetzt oder nachbearbeitet. `frames.jsonl` enthält dichte tatsächliche Root-, Körper-, Clip-, Attack-, Evade- und Todeszustände sämtlicher sichtbarer Akteure sowie die tatsächliche Bone-Anzahl; die umfangreiche Zwölf-Bone-Transformliste ist mit `--bone-detail none` ausdrücklich ausgelassen.

Alle Aufnahmen verwenden Godot 4.7.2, dasselbe Linux-Display und `LP_NUM_THREADS=4`. Die [Session-Receipt](capture-session-receipt.json) und ursprünglichen Ausführungslogs halten die tatsächlichen Prozesse fest. Export-Wandzeit umfasst Software-Rendering, Bildauslesen, PNG-Transport und Kodierung und misst keine normale Spiel-FPS oder physische Android-Leistung. Prozess-, Kamera- und Audioprüfungen allein bewerten weder die ästhetische Qualität noch die Beta-Reife.

Große unveränderliche Nachweise wurden im Workspace byteidentisch hardgelinkt; [Staging-Receipt](hardlink-staging-receipt.json). Die ursprünglichen Scratch-Daten bleiben erhalten. Jede Klasse wurde nach dem Staging erneut unabhängig analysiert.

Reproduktion eines Klassenvergleichs:

```bash
python3 tools/analyze_combat_quality.py \
  --before docs/design/reference-057/gameplay/arcanist/before \
  --after docs/design/reference-057/gameplay/arcanist/after \
  --source-commit 1cc13152a83c6631590d4df32ca298700a417df7 \
  --before-source-commit 86cb1b8ec878b4ae06daba5e6c5a4fa583865dc5 \
  --before-fixture-source-commit 1cc13152a83c6631590d4df32ca298700a417df7 \
  --output /tmp/emberfall-arcanist-full-comparison.json
```

Die Aufnahme-Orchestrierung lief in einer eigenen Linux-Session mit dateigebundenen Ausgaben. Der [Supervisor](detached-execution/detached-supervisor-receipt.json) protokolliert seinen tatsächlichen abschließenden `wait`-Exit 0 sowie den Hash der unveränderten finalen Session-Receipt. Ein erfolgreicher Daemon-Start allein gilt ausdrücklich nicht als erfolgreicher Film.

Ein früherer Aufnahmeversuch wurde bei 2.033 Frames durch den Neustart der Umgebung unterbrochen. Die [unveränderte Recovery-Receipt](interrupted-prior-attempt-recovery.json) hält den fehlenden Abschluss, den MP4-Probe-Fehler und die unbekannten ursprünglichen Prozess-Wait-Exits fest; [Hardlink-Provenienz](interrupted-prior-attempt-staging.json). Seine ursprünglichen Scratch-Dateien bleiben erhalten. Alle sechs hier aufgeführten Filme wurden anschließend vollständig neu aufgenommen und einzeln abgeschlossen.
