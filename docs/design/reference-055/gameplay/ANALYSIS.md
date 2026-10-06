# Aufnahmeanalyse reproduzieren

[`analyze_capture055.py`](analyze_capture055.py) ist die bytegenaue Kopie des ursprünglich im Scratch ausgeführten Helpers. SHA256: `aa3f0e8c7c287cd9cd685056282a4edc4431fea1c7d08c983be33ad006b589dc` (23.303 Bytes). Er liest abgeschlossene Receipts, JSONL-Frames, Metadaten, PCM/MP4 und ausgewählte Original-PNGs. Er prüft Hashes und Chronologie und zählt tatsächliche Angriffs-/Abbruchereignisse, Raumphasen, Kameratransformen und akzeptierte Audioereignisse. Git-Quellen werden direkt anhand ihrer Blob-Bytes verglichen. Der Helper startet weder Godot noch ffmpeg und verändert keine Spielquellen.

Diese Werte belegen technische Zustände. Sie bestätigen keine visuelle Qualität, Pixel-Sichtbarkeit, physische Handy-Leistung oder Touch-Abnahme. Die PCM-Spur stammt aus nativen Decodern mit fester Aufnahmeuhr; sie ist kein Hardware-Audio-Loopback. Capture-Wartezeiten messen nicht die normale Spiel-Framerate. Die vollständige MP4-Dekodierung wird im finalen Launcher-Receipt belegt; der Analysehelper wiederholt diese Dekodierung nicht.

Die folgenden Befehle werden im Repositoryroot ausgeführt. Python 3.11+, gzip und lokale Git-Objekte beider genannten Commits werden benötigt. Beide vollständig abgeschlossenen Captureordner werden zunächst komplett in einen neuen Tempordner kopiert. Die archivierte `native-game-audio.f32le.gz` enthält die ursprünglichen PCM-Bytes; `gzip -dc` stellt sie dort für die Hash- und Längenprüfung wieder her. Es findet keine AAC-Rückkonvertierung statt. `--repo` verweist auf das echte Repository. Ohne `--output` schreibt der Helper nach stdout; die Umleitung erzeugt neue Dateien außerhalb des Repos. Seine optionale `--output`-Funktion besitzt absichtlich den ursprünglichen Scratch-Pfadschutz. Ein laufender Capture-Receipt wird abgewiesen.

```sh
emberfall_repo="$(pwd -P)"
emberfall_analysis_dir="$(mktemp -d "${TMPDIR:-/tmp}/emberfall-analysis-055.XXXXXX")"
emberfall_helper="$emberfall_repo/docs/design/reference-055/gameplay/analyze_capture055.py"

for emberfall_capture in before after; do
  cp -a "$emberfall_repo/docs/design/reference-055/gameplay/$emberfall_capture" \
    "$emberfall_analysis_dir/$emberfall_capture"
  gzip -dc "$emberfall_analysis_dir/$emberfall_capture/native-game-audio.f32le.gz" \
    > "$emberfall_analysis_dir/$emberfall_capture/native-game-audio.f32le"
done

python3 "$emberfall_helper" \
  "$emberfall_analysis_dir/before" \
  --repo "$emberfall_repo" \
  --source-commit 4b152d0fc8b99cf51569585af2695bf3554416ed \
  --allow-overlay project.godot \
  --allow-overlay scripts/audio_director.gd \
  --allow-overlay tests/arcanist_quality_gameplay_preview.gd \
  --allow-overlay tests/native_capture_audio.gd \
  --allow-overlay tools/capture_arcanist_quality.py \
  > "$emberfall_analysis_dir/before-analysis.json"

python3 "$emberfall_helper" \
  "$emberfall_analysis_dir/after" \
  --repo "$emberfall_repo" \
  --source-commit ad4d50bb9dbdc07cea42e2306a79fc65bb642489 \
  --compare-analysis "$emberfall_analysis_dir/before-analysis.json" \
  > "$emberfall_analysis_dir/after-analysis.json"
```

Die fünf BEFORE-Ausnahmen entsprechen exakt der Allowlist in [`before/analysis.json`](before/analysis.json). 153 von 158 erfassten Quellen stimmen mit dem ursprünglichen 054-Commit überein; Projekt-Importeinstellung, Audio-Beobachtung und Aufnahmefixture bleiben als einzelne Abweichungen sichtbar. AFTER erhält keine solche Ausnahme. Der Vergleich trennt Setup, autoritativen Frameverlauf, Kamera und Audio. Neue Analysedateien besitzen andere Erstellungszeiten, absolute Pfade und Helperpfade; ihre ganzen Dateihashes müssen deshalb nicht den archivierten Analysedateien entsprechen.

Die BEFORE-Guardian-Kamera ist keine vollständig statische Einstellung: Nach 58 Transformänderungen beim Raumeintritt folgen zwei einzelne Rückzüge bei den echten Warnereignissen, Frame 2099 (0,643760 m) und 2156 (0,360937 m). Beide verlaufen entlang `CAMERA_BOOM`; danach bleiben Ursprung und Basis bis Frame 2263 exakt gleich. Dies entspricht dem Produktionspfad `_position_camera()` in `scripts/dungeon_world.gd`: Reale Warnumrisse können den gespeicherten Raumrahmen einmalig erweitern. `move_toward(..., delta * 1.5)` erlaubt bei 30 Hz einen Skalenwechsel bis 0,05; die gemessenen Wechsel von etwa 0,041037 und 0,023008 passen jeweils in einen Aufnahmeframe. Der Kameracode ist zwischen den beiden Quellcommits unverändert. Die Daten belegen diese Warn-Neurahmung und kein anschließendes Hin-und-her-Pendeln. Sie geben keine visuelle Freigabe für die Übergänge. Der abgeschlossene AFTER-Abgleich bestätigt alle 225 Guardian-Kameratransformen einschließlich beider Warn-Neurahmungen als exakt identisch.

`outcome.result_ui_*` beschreibt im unveränderten Helper ausschließlich `page == "loot"`. Dies beweist keinen bereits sichtbaren Ergebnisdialog: Main verzögert den tatsächlichen UI-Aufbau um 66 Aufnahmeframes. In BEFORE beginnt der Loot-Seitenstatus bei Frame 2405; erst ab Frame 2471 fehlen Hero und Kamera im Frameprotokoll. Die letzten 25 Frames gehören damit zur aufgebauten Ergebnisansicht. Deren Erscheinungsbild erfordert weiterhin die Prüfung der echten Aufnahme.

Beide frischen Repo-Reproduktionen sind mit Exit 0 belegt: [`BEFORE-Receipt`](before/analysis-reproduction-receipt.json) und [`AFTER-Receipt`](after/analysis-reproduction-receipt.json). AFTER stimmt bei allen 22 unveränderlichen Analyseabschnitten mit dem Archiv überein; sein mit der archivierten BEFORE-Analyse erzeugter Vergleich entspricht exakt [`comparison.json`](comparison.json). Alle 168 AFTER-Quellen stimmen mit `ad4d50b` überein, und die wiederhergestellte PCM ist byteidentisch zur tatsächlich reproduzierten BEFORE-Spur. Die eigenständig angelegten Tempkopien und ihre entpackten PCM-Dateien wurden anschließend entfernt.
