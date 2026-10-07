# 30 Sekunden normaler Kampf: Vorher und Nachher

[Vorher ansehen](before/ordinary-arcanist-first30s.mp4) · [Nachher ansehen](after/ordinary-arcanist-first30s.mp4)

Beide Videos zeigen dieselben ersten **900 chronologischen Frames / 30,000 Sekunden** der gewöhnlichen Arcanist-Expedition auf Etage 1: Nyra, unveränderte Startausrüstung, Schaden, Seed, Kamera, HUD, Effekte sowie die regulär ausgerüsteten Techniken Chain und Starfall. Der Ausschnitt enthält acht Angriffsbeginne, sieben tatsächliche Freigaben, 14 Trefferereignisse und zwei echte Ausweichereignisse. Der Chain-Angriff bei Frame 791 wird bei Frame 794 durch das Ausweichen abgebrochen. Reiseabschnitte sind enthalten; innerhalb des Ausschnitts gibt es keine Schnitte.

Dies ist ein vollständiger **30-Sekunden-Ausschnitt**, kein vollständiger Dungeon: Die tatsächliche Expedition bleibt nach Frame 899 unvollendet, `won=false`, ohne Guardian-Kampf oder Beuteanzeige. Der Recorderstatus `complete_prefix` beschreibt den erfolgreichen Aufnahmeabschluss; `capture-summary.json` erhält den tatsächlichen unvollendeten Spielstand.

| Nachweis | Vorher | Nachher |
| --- | --- | --- |
| Spielquelle | `ad4d50bb9dbdc07cea42e2306a79fc65bb642489` | `5e72fc6fad38f7dc829d313d8df0de8289f52573` |
| Bilder | H.264-Decodierung und erneute Kodierung der ersten 900 Frames aus der unveränderten nativen 055-Vollaufnahme | Neue kontinuierliche native Viewportaufnahme auf exklusivem Display `:108` |
| MP4-SHA256 | `d596d3cf3a9c651204a985c78e6239b5d0fa875f5b6278267189a99f7b3a1e38` | `e70cc296afe940f75c19004da8220b9fefb4faa3fd3e8ed10518066590f007f3` |
| Originalbilder | Vier ausdrücklich als H.264-Decodes gekennzeichnete Vergleichs-PNGs | 32 unveränderte originale native PNGs mit Einzelhashes |
| Quellbindung | Alle 168 ursprünglichen Runtime-Eingaben stimmen bytegenau mit dem Git-Commit überein | Alle 188 aufgenommenen Runtime-Eingaben stimmen bytegenau mit dem Git-Commit überein |

Die Vorher-Datei ist ein weiterer verlustbehafteter Videoencode. Ihre vier [Vergleichsbilder](before/decoded-comparison-frames-receipt.json) sind unskalierte Decodes aus dem originalen 055-MP4 und werden ausdrücklich als abgeleitete Bilder geführt. Die Nachher-PNGs in [selected-frames](after/selected-frames) stammen direkt aus Godots tatsächlichem Viewport; die [Aufnahmereceipt](after/receipt.json) enthält ihre Hashes und Auswahlgründe. Es wurden keine Bilder nachbearbeitet, zusammengesetzt oder mit zusätzlichen Effekten versehen.

[Der unabhängige Vergleich](after/analysis.json) bestätigt für alle 900 Frames exakt gleiche Simulationsuhren, HP, Pending-Attacks, Raumphasen und autoritative Kampfereignisse sowie exakt gleiche Kameratransformationen. Präsentationsposen und das visuelle Ereignis `hero_release` sind in der autoritativen Prüfsumme ausdrücklich ausgespart. Die Quelle blieb während beider nativen Aufnahmen unverändert. Die [erneute Analyse nach Kopie und PCM-Kompression](after/analysis-reproduced-after-copy.json) bestand ebenfalls.

Der Ton verwendet die tatsächlich akzeptierten Spiel-Cues und Musik, nativ mit `AudioStreamPlayback` decodiert und auf der festen Aufnahmezeitachse zu Stereo-Float-PCM gemischt. Beide Ausschnitte enthalten **1.323.000 Stereo-Sampleframes bei 44.100 Hz**. Ihre PCM-Bytes sind identisch (`0cc976e2548be532070a43e12e5e1f5b6d783f8e30b9379561b4ca24ba150ffc`); der unabhängige Scan fand keine nichtendlichen Samples, Peak `0,085272` und RMS `0,007778`. Nachher wurden 27 Cues akzeptiert und 27 One-Shots natürlich beendet. Die MP4-Audiospuren sind AAC-Kodierungen dieses PCM; die geprüften Originalbytes bleiben als verlustfreie Gzip-Archive erhalten.

Die ursprünglichen Audio-Event-JSONs enthalten unterschiedliche `acceptance_wall_msec`-Zeitstempel aus den zwei Engine-Prozessen. [Ein gesonderter Vergleich](after/audio-walltime-comparison.json) entfernt ausschließlich dieses offengelegte Feld: Cue-Schlüssel, Voice-Slots, Ersatzschlüssel, Samplegrenzen, Zustandswechsel, natürliches EOF und die exakten Null-Suffixe stimmen weiterhin vollständig überein. Beide ursprünglichen JSONL-Dateien bleiben unverändert.

Für die tatsächliche 30-Hz-Darstellung stehen dichte Root-, Körper- und ausgewählte native Bone-Transformationen sowie echte Evade-Phasen im Nachher-[frames.jsonl](after/frames.jsonl). Relevante Originalbilder sind Signature-Last bei Frame 4, Basic-Last bei 46, erstes Ausweichen bei 311/314/317/320/323/326 und Starfall-Last bei 328. Der zweite Ausweichabbruch wird zusätzlich im [unabhängigen Bewegungsbericht](MOTION_REVIEW.md) beurteilt.

Die Aufnahmen liefen unter Godot 4.7.2 mit Linux/llvmpipe und Dummy-Audiotreiber. Export-Wandzeit enthält Software-Rendering, Bildauslesen, PNG-Transport und Kodierung; sie misst keine normale Spiel-FPS, Smartphoneleistung oder Audio-Hardware. Die Belege erlauben eine konkrete Sichtprüfung der veränderten Körperbewegung und Raider. Sie begründen keine allgemeine visuelle oder Beta-Freigabe. Kantige Ärmel/Kleidung, statisches Haar und die übrigen unveränderten Gegnermodelle bleiben sichtbare Grenzen.

Reproduktion aus dem Repository:

```bash
python3 tools/capture_combat_quality.py \
  --output /tmp/emberfall-after-first30 \
  --godot /path/to/Godot_v4.7.2-stable_linux.x86_64 \
  --display :108 --exclusive-render-slot

python3 tools/analyze_combat_quality.py \
  --before docs/design/reference-055/gameplay/after \
  --after docs/design/reference-056/gameplay/after \
  --source-commit 5e72fc6fad38f7dc829d313d8df0de8289f52573 \
  --before-source-commit ad4d50bb9dbdc07cea42e2306a79fc65bb642489 \
  --output /tmp/emberfall-combat-analysis.json

python3 docs/design/reference-056/gameplay/compare_audio_walltime.py \
  --before docs/design/reference-055/gameplay/after \
  --after docs/design/reference-056/gameplay/after \
  --output /tmp/emberfall-audio-comparison.json
```

Vor einer neuen nativen Aufnahme muss der einzige Godot-/Blender-Renderer exklusiv zugeteilt sein. [Ausführungsreceipt](capture-execution-receipt.json), [ursprüngliche Baseline-Prüfung](baseline-first30-native-proof.json), [Vorher-Ableitung](before/receipt.json) und das [exakte Ableitungsskript](derive_before_prefix056.py) erhalten die tatsächlichen Ausgänge und Quellenketten. Das Ableitungsskript verwendet die ursprünglichen Workspacepfade aus dieser Durchführung; seine Receipt enthält zusätzlich die vollständigen FFmpeg-Kommandos.
