# Kampfbewegungen 057

Die drei Helden führen Lauf, Angriff und abgebrochenen Angriff durch eine gemeinsame Übergangsschicht auf ihrem originalen 65-Bone-Skelett. Die Schicht bewahrt die zuletzt gezeigte Grundpose vor dem frischen Trefferimpuls; gehaltene Frames verstärken den Rückstoß deshalb nicht. Anatomische Segmentlängen, Child-Offsets, Restmatrizen, Skin-Binds und Gelenkskalen bleiben original. Nur die ursprünglichen Root-/Hüftgelenke dürfen ihre Poseposition ändern.

Der Arcanist öffnet seine kurze Signaturbewegung früher außerhalb der Schulter. Ranger laden den Bogen über die Hüfte und halten die echte Zughand auf Schulter-/Wangenhöhe. Vowkeeper tragen die Klinge beim Laufen in einer niedrigen Deckung und führen den Eintritt beziehungsweise Abbruch über die tatsächliche globale Schwerthand. Die originalen Kontaktzeitpunkte, Angriffsdauern, Projektilfreigaben und Simulationswerte werden dadurch nicht verändert.

## Tatsächliche Prüfungen

Godot **4.7.2.stable.official.ed1daf0bf** führte den abschließenden Lauf mit Dummy-Audio aus. Jeder Prozess beendete sich tatsächlich mit Exitcode 0; die Logs enthalten keine Script-, Shader-, Parse-, Compile-, Track- oder Engine-Fehler. Der aktuelle Quellenstand wurde vor den Tests vollständig importiert.

| Suite | Prüfungen | Fehler |
| --- | ---: | ---: |
| Native Motion Transition | 706 | 0 |
| Source Avatar Attack | 172 | 0 |
| Source Avatar Attack Contact | 295, an 39 tatsächlichen Posen | 0 |
| Class Avatar Quality | 398 | 0 |
| Source Avatar Evade | 1.729 | 0 |
| Gesamt | **3.300** | **0** |

[Originale Ausführungsquittung und Quelldatei-SHA256](focused-accepted/execution.json), [unveränderte Logs](focused-accepted/) und [aus dem Originallog extrahierte Bewegungsmetriken](transition-metrics.json) sind abgelegt. Die großen Zahlen sind funktionale beziehungsweise körperliche Prüfungen und keine Bewertung der gestalterischen Qualität.

Die Kontaktprüfung rekonstruiert tatsächlich gewichtete, indexierte Hand-/Arm-Dreiecke und die wirklichen Griff- beziehungsweise Sehnenflächen. Die vorhandenen Grenzen bleiben bestehen: höchstens 1,5 mm Eindringen in den Klassengriff, Kontakt von mindestens drei Fingern innerhalb 3 mm mit gegenüberliegendem Daumen, tatsächliche Pfeil-/Sehnenpunkte innerhalb 0,1 mm ihres Hooks. Der finale Klassentest misst maximal **0,8233 mm** Eindringen und **2,6440 mm** Fingerspalt. Arcanist-Angriffskontakt misst maximal **0,4729 mm** Eindringen und **2,4648 mm** Fingerspalt.

Echte Cancel-Events bei 32 %, 67 % und 93 % des Angriffs wurden für jede Klasse mit einer anschließenden bewegten Flucht geprüft. Beide tatsächlichen Welt-Fußanker springen beim Eintritt maximal **0,000521 mm**, unter der unveränderten Grenze von 0,1 mm. Die Held-Frame-Prüfung wiederholt den echten Übergang viermal mit Delta 0 und verlangt eine bit-identische Pose und Waffe. Die echte Freigabe erreicht für alle 65 Bones den ursprünglichen Kontaktpunkt.

Die maximale Vowkeeper-Klingenspitzenbewegung während der ersten neun normalen 60-Hz-Eintrittsframes beträgt **0,201806 m**. Der größte Schritt im gesamten gesampelten Schlag beträgt separat **0,478005 m**; die spätere schnelle Klingenbewegung wird nicht als Eintrittsfehler ausgegeben. Der größte Schritt einer abgebrochenen, bewegten Flucht beträgt **0,282389 m**. Diese Werte gelten für die aufgezeichneten realen Testsequenzen.

## Originale native Bilder

Die 18 PNGs entstanden unverändert aus dem echten Godot-Viewport mit **1.000 × 1.000 Pixeln**, OpenGL Compatibility und Mesa llvmpipe unter Xvfb. Der separate native Prozess beendete sich mit Exitcode 0 und ohne Fehlerdiagnostik. Eine allgemeine V-Sync-Warnung des Software-Treibers ist im Originallog erhalten. Audio war Dummy; diese Diagnosebilder machen keine Ton- oder Smartphone-Leistungsbehauptung.

| Gezeigter tatsächlicher Actor-Zustand | Arcanist | Ranger | Vowkeeper |
| --- | --- | --- | --- |
| Signatur laden | [PNG](native-accepted/arcanist-signature-load.png) | [PNG](native-accepted/ranger-signature-load.png) | [PNG](native-accepted/vowkeeper-signature-load.png) |
| Signatur freigeben | [PNG](native-accepted/arcanist-signature-release.png) | [PNG](native-accepted/ranger-signature-release.png) | [PNG](native-accepted/vowkeeper-signature-release.png) |
| Signatur nachführen | [PNG](native-accepted/arcanist-signature-follow.png) | [PNG](native-accepted/ranger-signature-follow.png) | [PNG](native-accepted/vowkeeper-signature-follow.png) |
| Unmittelbar vor Abbruch | [PNG](native-accepted/arcanist-cancel-departure.png) | [PNG](native-accepted/ranger-cancel-departure.png) | [PNG](native-accepted/vowkeeper-cancel-departure.png) |
| Echter Abbruch-Eintritt | [PNG](native-accepted/arcanist-cancel-entry.png) | [PNG](native-accepted/ranger-cancel-entry.png) | [PNG](native-accepted/vowkeeper-cancel-entry.png) |
| Diagonaler LowStep-Zwischenstand | [PNG](native-accepted/arcanist-evade-low-step.png) | [PNG](native-accepted/ranger-evade-low-step.png) | [PNG](native-accepted/vowkeeper-evade-low-step.png) |

Alle 18 Originalbilder wurden visuell geprüft. Stabkrone und Füße bleiben vollständig im Bild. Die Abbruch-Paare erhalten Körper und gehaltene Waffen durchgehend; die Ranger-Zughand liegt sichtbar neben Schulter/Wange. Im diagonalen LowStep-Zwischenstand kreuzen die Boots während des Schrittes sichtbar. Bewegungsfluss und Lesbarkeit im Spiel werden zusätzlich an den vollständigen normalen Expeditionen beurteilt. Die Diagnosebilder sind dafür ergänzende Detailansichten und bestätigen keine allgemeine Veröffentlichungsreife oder einen kommerziellen Grafikstandard.

[Tatsächliche Actor-Clips und native Welt-Bones](native-accepted/native-motion-poses.json), [native Ausführungsquittung](native-accepted/execution.json), [Originallog](native-accepted/native-preview.log) und [Dateihashes mit Originalpfaden](motion-proof-receipt.json) binden diese Bilder an den aufgezeichneten Lauf. Die unveränderten Originalquittungen nennen ihre ursprünglichen Scratch-Pfade; die Dateizuordnung im Proof-Receipt bindet sie an die hier byte-identisch kopierten Artefakte.

## Erkannter und behobener Rückkopplungsfehler

Der erste abschließende Testversuch wurde verworfen: **706 Prüfungen, acht Fehler, tatsächlicher Exitcode 1**. Bei Phase 0 verwendete die neue Weltanker-Umrechnung die Bodenkorrektur des vorherigen Redraws. Das änderte wiederholt die Kniequaternions durch Float32-Rundung, obwohl der sichtbare Welt-Ankersprung bereits klein war.

Der Produktionscode verwendet jetzt die feste Rig-Bezugsbasis des echten Cancel-Events unter dem aktuellen Actor-Transform. Dadurch bleibt auch der gehaltene Frame wieder bit-identisch. Die körperlichen Grenzen wurden nicht gelockert. [Erster verworfener Lauf](rejected-held-entry/execution.json), [Originalfehlerlog](rejected-held-entry/native_motion_transition.log) und [Diagnose der tatsächlichen wiederholten Bones/Bodenkorrekturen](rejected-held-entry/trace-final-anchors-beforefix.log) bleiben erhalten.

Die historischen ersten Motion-Versuche, das verworfene ALSA-Audio-Geräte-Preview und das verworfene enge/ungenügend beleuchtete Studio-Preview bleiben im ursprünglichen Scratch-Proof-Verzeichnis erhalten. Sie werden hier nicht als finale Belege gezählt.
