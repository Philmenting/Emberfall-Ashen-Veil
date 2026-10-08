# Erfolgreicher Android-Lauf, Quellstand 6872262

Der [Android Beta Runtime-Workflow](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37484063576) und Job `112339436443` bestehen vollständig am 6. Oktober 2026 auf `6872262cb17f987d29f0c7fd710a2b7f599e8623`. Alle drei originalen `runtime-status.json` melden `passed`, alle `diagnostic_errors` sind leer. Die APK- und Quellen-Hashes bleiben in diesen Dateien erhalten.

Das heruntergeladene GitHub-Evidence-Artefakt `11423899483` umfasst 56.343.296 Bytes. Sein unabhängig berechneter SHA-256 entspricht exakt dem GitHub-Digest `1ddf2aa7570cc4a397fbde79a11898fcb83972850508ae824a9b3a7fbe041c56`. Diese Ablage bewahrt sechs begrenzte Original-PNGs und die originalen JSON-Dateien bytegleich; [Provenienz](provenance.json) enthält Pfade, Größen und Hashes. Die `*.markers.log` enthalten ausgewählte, unveränderte PASS-/Messwert-Zeilen aus den ursprünglichen Godot-Logs. Vollständige Systemlogs und alle Bildfolgen bleiben im GitHub-Artefakt und werden hier nicht dupliziert.

## Tatsächliche Runtime-Ergebnisse

| Prüfung | Erkannter Pass-Marker | Beobachtungsdauer |
| --- | --- | --- |
| AFK | Exakte Abrechnung, `runs=44`, `serial=45` | 853,797 s |
| AFK-Neustart | Keine doppelte Auszahlung | 13,797 s |
| Erster Spielablauf | Expedition, Klassenreliquie und kombinierte Oath-UI | 85,517 s |
| Spielablauf-Neustart | Kombinierte Oaths erhalten | 18,048 s |
| Grafiklauf | Alle vier Regionen und Bewegungsprüfungen | 609,114 s |

Die AFK-Deadline bleibt unverändert 900 Sekunden. Diese Beobachtungsdauern sind reale Emulator-Laufzeiten und keine Zeiten innerhalb der beschleunigten Testszenen. Der frühere native Musikabsturz trat nicht mehr auf.

## Geprüfte Originalbilder

Die vier Grafikbilder stammen aus der QA-Szene mit erhöhten Überlebenswerten, eingefrorener Auto-Simulation und separat geschrittener nativer Guardian-Animation. Diese Werte und der Paused-Hinweis gehören zum Testaufbau; die Bilder ersetzen keine gewöhnliche Expedition. Die Gameplayaufnahme und der Success-Lauf verwenden dagegen reguläre Anfangsausrüstung.

| Originalbild | Inhalt |
| --- | --- |
| [Region 0](android-motion-region-0-17.png) | Bell Warden, Nahkampfklasse und Bodenwarnung |
| [Region 1](android-motion-region-1-17.png) | Silt Abbot, überarbeitete Arcanist mit Stab und Kleidung |
| [Region 2](android-motion-region-2-17.png) | Mourning Queen, bisherige Ranger-Klasse und Beschwörungen |
| [Region 3](android-motion-region-3-17.png) | Cinder Sovereign, überarbeitete Arcanist und Kreuzwarnung |
| [Erster Kampf](android-success-first-fight.png) | Arcanist mit regulären 380 Life im ersten Raum |
| [Erste Reliquie](android-success-first-relic.png) | Tatsächlicher Expeditionserfolg und Beuteanzeige |

Alle sechs PNGs wurden visuell geprüft. Im Original-Artefakt hat jede Region vier unterschiedliche Bewegungsbilder; ihre Hashes wurden unabhängig verglichen. Die Bewegungsmetriken betreffen die Guardians mit 29 Knochen und neun nativen Clips: jeweils 20 Schritte, 17/17/12/17 veränderte Knochen. Diese Zahlen messen nicht Nyras Finger oder den Stabgriff; dafür bestehen die gesonderten nativen Avatar-Prüfungen.

## Emulator-Messwerte

Gerät: `sdk_gphone64_x86_64`, Android 16 / API 36, ANGLE SwiftShader, Godot `gl_compatibility`. Der eingefrorene Guardian-Renderaufbau misst jeweils 30 Frames; die Motion-Prüfung läuft getrennt. Die [Original-JSON](android-render-performance.json) enthält die Einzelzusammenfassungen, Auflösung und Drawcalls. `target_fps` ist eine Einstellung, keine erreichte Framerate.

| Region | Balanced Median / P95 (ms) | Drawcalls | Battery Median / P95 (ms) | Drawcalls |
| --- | --- | --- | --- | --- |
| 0 | 1798,083 / 4183,128 | 229 | 746,513 / 1311,674 | 191 |
| 1 | 1354,936 / 2667,024 | 303 | 605,132 / 762,346 | 250 |
| 2 | 1680,538 / 3310,217 | 229 | 719,162 / 1363,473 | 194 |
| 3 | 1357,224 / 2692,045 | 292 | 609,711 / 1149,045 | 253 |

Balanced rendert 1212×540, Battery 606×270; die originalen Android-Screenshots umfassen 2424×1080. Die niedrige Software-Renderer-Geschwindigkeit erlaubt keine Aussage über Handy-FPS, Wärme oder Akkuverbrauch. Ein physischer Android-Gerätelauf steht weiterhin aus. Der erfolgreiche funktionale Lauf ist keine visuelle Beta-Freigabe.
