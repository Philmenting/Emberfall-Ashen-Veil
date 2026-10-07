# Kampfbewegungen 057

**Aktueller Bewegungsstand: [`1cc13152a83c6631590d4df32ca298700a417df7`](https://github.com/Philmenting/Emberfall-Ashen-Veil/commit/1cc13152a83c6631590d4df32ca298700a417df7).** Die [anschließende Ausweichkorrektur](evade-step-final/README.md) besteht mit neun betroffenen Suiten / **4.321 Prüfungen / null Fehler**, darunter fünf Bewegungssuiten / **3.744/0**. Ihre 18 neuen Originalbilder zeigen getrennte Boots und einen breiten Ausfallschritt. Die vollständige zeitliche Spielsichtung ist noch offen.

Die folgenden Abschnitte dokumentieren ausdrücklich die frühere gemeinsame Stufe **`02a3fc905e55a4e64cbece4eb6b07c65c1bf4afb`**, Tree `ae378f958570263701f4b80a048766c7723ec882`, vor dieser Ausweichkorrektur. Alle **905** damals gebundenen Source-, Asset-, QA- und Workflowdateien stimmen mit diesem Commit überein und blieben bei seinem nativen Preview byte-identisch. [Originale Proof-Quittung](final-motion-proof-receipt.json) und [vollständige damalige Sourcebindung](native-final/final-source-binding.json) enthalten die tatsächlichen Dateihashes und Ausführungswerte. Dateinamen mit `final` bleiben als ursprüngliche Nachweispfade erhalten; sie bezeichnen hier diese damalige Stufe. Der [vorherige Leaf-Text](historical-source-02a3fc9-README.md) ist unverändert archiviert.

Die drei Helden führen Lauf, Angriff und abgebrochenen Angriff durch eine gemeinsame Übergangsschicht auf ihrem originalen 65-Bone-Skelett. Sie bewahrt die zuletzt gezeigte Grundpose vor dem frischen Trefferimpuls; gehaltene Frames verstärken den Rückstoß dadurch nicht. Anatomische Segmentlängen, Child-Offsets, Restmatrizen, Skin-Binds und Gelenkskalen bleiben original. Nur die ursprünglichen Root-/Hüftgelenke dürfen ihre Poseposition ändern. Originale Kontaktzeitpunkte, Angriffsdauern, Projektilfreigaben und Simulationswerte bleiben bestehen.

Arcanist öffnen ihre kurze Signaturbewegung früher außerhalb der Schulter. Ranger laden den Bogen über die Hüfte und halten die echte Zughand auf Schulter-/Wangenhöhe. Vowkeeper tragen die Klinge beim Laufen in einer niedrigen Deckung und führen Eintritt beziehungsweise Abbruch über die tatsächliche globale Schwerthand.

## Tatsächliche Prüfungen der gemeinsamen Stufe 02a3fc9

Diese fünf Suites liefen im akzeptierten abschließenden Integrationstest nach den Fuß- und Recovery-Korrekturen. Sie wurden für den neuen Preview nicht erneut ausgeführt. Godot **4.7.2.stable.official.ed1daf0bf** und Dummy-Audio beendeten jeden Prozess tatsächlich mit Exitcode 0; die fünf Logs enthalten keine Script-, Shader-, Parse-, Compile-, Track- oder Engine-Fehler.

| Suite | Prüfungen | Fehler |
| --- | ---: | ---: |
| [Native Motion Transition](focused-final/focused-native_motion_transition.log) | 706 | 0 |
| [Source Avatar Attack](focused-final/focused-source_avatar_attack.log) | 172 | 0 |
| [Source Avatar Attack Contact](focused-final/focused-source_avatar_attack_contact.log) | 295, an 39 tatsächlichen Posen | 0 |
| [Class Avatar Quality](focused-final/focused-class_avatar_quality.log) | 398 | 0 |
| [Source Avatar Evade](focused-final/focused-source_avatar_evade.log) | 1.729 | 0 |
| Gesamt | **3.300** | **0** |

Zusätzlich bestätigen [Character3D **168/0**](focused-final/focused-character_3d.log) und [AnimationCraft **74/0**](focused-final/focused-animation_craft.log) den tatsächlich gewichteten Stand und alle drei Schwertphrasen. [Originale abschließende Ausführungsquittung](focused-final/execution.json) bewahrt ihren vollständigen damaligen 905-Datei-Snapshot. Die allgemeine lokale [53-Suite-Abdeckung](../integration/combined-local-coverage.json) kombiniert ausdrücklich 41 frühere und 12 finale Suites; sie wird hier nicht als ein gemeinsamer neuer 53-Suite-Lauf ausgegeben.

Die Kontaktprüfung rekonstruiert gewichtete, indexierte Hand-/Arm-Dreiecke und wirkliche Griff-/Sehnenflächen. Die bestehenden Grenzen bleiben: höchstens 1,5 mm Eindringen in den Klassengriff, mindestens drei Finger innerhalb 3 mm mit gegenüberliegendem Daumen sowie Pfeil-/Sehnenpunkte innerhalb 0,1 mm ihres Hooks. Der finale Klassentest misst maximal **0,8233 mm** Eindringen und **2,6440 mm** Fingerspalt; Arcanist-Angriffskontakt maximal **0,4729 mm** beziehungsweise **2,4648 mm**.

Echte Cancel-Events bei 32 %, 67 % und 93 % des Angriffs wurden für jede Klasse mit anschließender bewegter Flucht geprüft. Beide Welt-Fußanker springen beim Eintritt maximal **0,000521 mm**, unter derselben Grenze von 0,1 mm. Vier Wiederholungen mit Delta 0 ergeben eine bit-identische Pose und Waffe. Die Freigabe erreicht für alle 65 Bones den ursprünglichen Kontaktpunkt.

Die Vowkeeper-Klingenspitze bewegt sich während der ersten neun normalen 60-Hz-Eintrittsframes maximal **0,201806 m**. Der größte Schritt im gesamten gesampelten Schlag beträgt separat **0,478005 m**, während einer abgebrochenen bewegten Flucht **0,282389 m**. [Aus den finalen Originallogs extrahierte Bewegungsmetriken](final-transition-metrics.json) enthalten alle Klassen. Diese Werte messen konkrete Testsequenzen, keine gestalterische Veröffentlichungsreife.

## Standfüße, Zehen und Schwert-Rücknahme

Die gemeinsame Laufkorrektur hält beide frisch gesampelten ursprünglichen Fußtransforms vor einer erforderlichen Hüftsenkung. Sie löst anschließend beide Originalketten und bewahrt die native Thigh-/Calf-Roll. Dadurch sinkt der freie Fuß bei der gemeinsamen Hüftkorrektur nicht mehr mit ab. Am tatsächlichen Touchdown werden zusätzlich die ursprünglichen lokalen Ball-/BallLeaf-Quaternions für diesen Stand gehalten; freie Zehen behalten ihre Originalanimation. Die zuvor weiter rotierenden Standzehen hatten die wirklich gewichtete Sohle durch den Boden bewegt. Die [unabhängige Rekonstruktion dieses historischen Fehlers](independent-toe-audit/) bleibt erhalten und beansprucht keinen neuen Renderer-Lauf.

Character3D prüft alle elf nativen Figuren über 120 Frames mit 60 Hz bei tatsächlicher gerader Weltbewegung. Die unveränderten Kriterien verlangen weniger als 8 mm Standankel-Drift, belastete Sohlen innerhalb 40 mm der Bodenhöhe, freie Sohlen über −35 mm, freien Fußhub über 70 mm und mehr als 30 stabile Standproben. Im finalen Lauf sind alle gewichteten Boot-Minima positiv: Helden mindestens **+3,486 mm**, Guardians mindestens **+7,623 mm**. Die größte tatsächliche Standdrift beträgt **1,615 mm**. [Originalmessungen aller elf Figuren](final-foot-support-metrics.json) bewahren belastete und freie Sohlen getrennt.

Die zusätzliche Weltprüfung fand einen echten Schwertfehler: **294,373 mm** Fußdrift in der späten Rücknahme, obwohl Actor-Position, Skalierung und Blickrichtung fest blieben. Der Code löste zuerst die Standbeine und überschrieb sie danach durch den Recovery-Settle aller Bones. Jetzt läuft derselbe Settle vor der vorhandenen Standlösung und Hüftlast. Originalclips, Upper-Body-Recovery, Bindings, Segmentlängen und Simulationsbewegung bleiben erhalten. [Rote Transformdiagnose](rejected-sword-recovery/sword-world-diagnostic.log), [fehlgeschlagener Lauf](rejected-sword-recovery/focused-animation_craft.log) und [damalige unveränderte ClassRig-Quelle](rejected-sword-recovery/class_avatar_rig_before_recovery_order_fix.gd) dokumentieren den Fehler.

Das aktuelle Standorakel prüft einen bereits auf sein Ziel ausgerichteten Actor über 31 Vorbereitungs- und 30 Recovery-Zwischenframes. Es verwendet die echten Spieleraktionen: Basic → SwordA, Signature → Skill/SwordB und Sunder → Heavy/SwordC. Die Welt-Fußdrift beträgt jetzt **1,066 / 1,422 / 1,309 Mikrometer**, unter derselben 8-mm-Grenze. Alle zwischenzeitlichen Foot-Transforms bleiben an der nativen Deckung; gewichtete Sohlen erreichen mindestens 2,9 mm, die Freigabe bleibt kontinuierlich und die finale Stütze liegt bei 3 mm mit beiden Boots unter 20 mm.

Die vollständigen Hüftkurven sind im Originallog erhalten. Basic senkt die Hüfte tatsächlich um **74,452 mm**; die B/C-Vorbereitung hat **165,146 / 169,173 mm** Höhenumfang. Diese Umfänge werden nicht als Absenkung vom ersten Frame ausgegeben. Der ursprüngliche SwordA-Zweifußhop bleibt unabhängig über direkte native Source-Samples geprüft: die alten Grenzen von über 10 cm Hub und über 25/20 cm Fußweg gelten weiterhin für das Original. Der Produktionsangriff hält seine belasteten Deckungsfüße. Die [Integration-Dokumentation](../integration/README.md) erläutert QA-Migration und verworfene Versuche.

Beim Ranger wurde nach der Fixture-Korrektur auf die tatsächliche `.085 s`-Projektilfreigabe eine echte zusätzliche Recovery-Hüftsenkung entfernt. Die vorhandene Bogenprüfung bestätigt **0 mm** Sehnen-/Nock-/Aim-Grip-Bewegung am frühen Übergang und den erhaltenen Zughand-Follow-through. Die 0,1-mm-Kontaktgrenzen wurden nicht gelockert.

## Originale native Bilder der Stufe 02a3fc9

Der neue einzelne native Prozess erzeugte **18 unveränderte PNGs mit 1.000 × 1.000 Pixeln** aus dem echten Viewport: OpenGL Compatibility, Mesa llvmpipe, Xvfb `:108`, `LP_NUM_THREADS=4`, Dummy-Audio. Tatsächlicher Engine- und Runner-Exitcode sind 0, die Laufzeit beträgt **9,232 Sekunden**. Die einzige Warnung betrifft die vom Software-Treiber nicht unterstützte Änderung des V-Sync-Modus; sie bleibt im [Originallog](native-final/native-preview.log) erhalten.

| Gezeigter tatsächlicher Actor-Zustand | Arcanist | Ranger | Vowkeeper |
| --- | --- | --- | --- |
| Signatur laden | [PNG](native-final/arcanist-signature-load.png) | [PNG](native-final/ranger-signature-load.png) | [PNG](native-final/vowkeeper-signature-load.png) |
| Signatur freigeben | [PNG](native-final/arcanist-signature-release.png) | [PNG](native-final/ranger-signature-release.png) | [PNG](native-final/vowkeeper-signature-release.png) |
| Früh nachführen (+65 ms) | [PNG](native-final/arcanist-signature-follow.png) | [PNG](native-final/ranger-signature-follow.png) | [PNG](native-final/vowkeeper-signature-follow.png) |
| Unmittelbar vor Abbruch | [PNG](native-final/arcanist-cancel-departure.png) | [PNG](native-final/ranger-cancel-departure.png) | [PNG](native-final/vowkeeper-cancel-departure.png) |
| Echter Abbruch-Eintritt | [PNG](native-final/arcanist-cancel-entry.png) | [PNG](native-final/ranger-cancel-entry.png) | [PNG](native-final/vowkeeper-cancel-entry.png) |
| Diagonaler LowStep-Zwischenstand | [PNG](native-final/arcanist-evade-low-step.png) | [PNG](native-final/ranger-evade-low-step.png) | [PNG](native-final/vowkeeper-evade-low-step.png) |

Alle 18 Originalbilder wurden einzeln in Originalauflösung betrachtet. Körper, Boots und Stabkrone bleiben vollständig im Bild; Waffen und Gliedmaßen wirken an diesen Posen zusammenhängend. Die Cancel-Paare erhalten die sichtbare Ausgangshaltung. Die Ranger-Zughand liegt neben Schulter/Wange; Bogen und Sehne sind lesbar. Im diagonalen LowStep-Zwischenstand kreuzen die Boots sichtbar. Bewegungsfluss und Lesbarkeit werden zusätzlich anhand der vollständigen normalen Expeditionen beurteilt. Das Follow-Bild zeigt die frühe Nachführung, nicht den vormals fehlerhaften späten Recovery-Abschnitt; dessen Beleg sind die Zwischenframe-Prüfungen oben.

[Bildsichtung mit genauer Reichweite](final-native-visual-review.json), [tatsächliche Actor-Clips und Welt-Bones](native-final/native-motion-poses.json), [originale Ausführungsquittung](native-final/execution.json) und [Dateihashes mit Originalpfaden](final-motion-proof-receipt.json) binden die Bilder an den finalen Stand. Diese stillen Detailansichten bestätigen keine vollständige zeitliche Gameplay-Qualität, Tonqualität, Smartphone-Leistung oder allgemeine Veröffentlichungsreife.

## Erhaltene frühere Nachweise

Die ursprünglichen **3.300/0** Motion-Checks, ihre damaligen 18 PNGs und alle Originalquittungen bleiben unverändert unter [focused-accepted](focused-accepted/), [native-accepted](native-accepted/) und [motion-proof-receipt.json](motion-proof-receipt.json). Ihre damaligen Source-Hashes liegen vor den letzten Lauf-/Zehen-/Bow-/Recovery-Korrekturen. Der [frühere Leaf-Text](historical-before-walk-recovery-README.md) ist ebenfalls byte-identisch erhalten. Die getrennten `focused-final`- und `native-final`-Artefakte gehören zur anschließenden Stufe 02a3fc9; die aktuelle zusätzliche Korrektur ist separat unter [evade-step-final](evade-step-final/README.md) gebunden.

Der frühere verworfene Held-Frame-Lauf bleibt erhalten: **706 Prüfungen, acht Fehler, tatsächlicher Exitcode 1**. Seine Weltanker-Umrechnung führte die Bodenkorrektur des vorherigen Redraws zurück und änderte wiederholt Kniequaternions trotz Delta 0. Die feste Rig-Bezugsbasis des echten Cancel-Events beseitigte diese Rückkopplung ohne gelockerte Grenzen. [Originaler verworfener Lauf](rejected-held-entry/execution.json) und [Diagnose](rejected-held-entry/trace-final-anchors-beforefix.log) bleiben unverändert.
