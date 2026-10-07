# Native gerichtete Ausweichbewegung – 056

Arcanist, Ranger und Vowkeeper erhalten einen eigenständigen niedrigen Ausweichschritt auf ihren ursprünglichen 65 Knochen. Die tatsächliche Simulation bestimmt Richtung und Strecke; der Actor nimmt daraus die sichtbare Bewegung und kehrt nach dem realen Ausweichen in die Quellhaltung zurück. Ein tatsächlich beginnender Folgeangriff und Tod übernehmen sofort die Pose. Die Darstellung verändert weder Positionen der Simulation, Schaden, Schutzzeiten, Cooldowns noch Angriffszeitpunkte.

Die Bewegung ist eine **prozedurale anatomische Pose**, kein als Quellenanimation ausgegebener Dodge-Clip. Hüfte und Knie senken den Schwerpunkt um rund 22,5–23,0 cm in der Spielwelt; der Oberkörper folgt der Fluchtrichtung. Der Ranger stabilisiert dabei seinen tatsächlichen Quellrahmen der tragenden Schulter, damit das gewichtete Hand-/Unterarmmodell den schmalen Bogengriff weiterhin korrekt umfasst. Native Beinlängen, Finger, Skin-Binds und Bone-Skalen bleiben erhalten. Knie beugen weiterhin in die anatomische Vorwärtsebene, auch beim Rückwärtsausweichen.

## Tatsächliche Prüfung

Der abschließende Lauf mit Godot **4.7.2.stable.official.ed1daf0bf** beendet sich mit **Exit 0: 1.729 Checks, 0 Fehler**. [Originales finales Log](smoke-seventh.log) und [Hash-/Statusreceipt](evade-proof-receipt.json) bleiben unverändert erhalten.

- Alle drei Produktionsklassen, acht tatsächliche Weltrichtungen und sieben Posephasen; insgesamt 168 native Poseproben plus 24 Audits der tatsächlich indizierten, gewichteten Handdreiecke.
- Alle 65 Bone-Rests, Skalen und ursprünglichen Gliedmaßenlängen; anatomische Knieebenen; saubere Rückkehr und wiederholte, nicht aufaddierende Poseproben.
- Tatsächliche gewichtete Stiefel, sämtliche originalen Kleidungs- und Robenflächen sowie alle Accessoires bleiben mindestens 3 mm über ihrer ursprünglichen Bodenebene. Indizierte sichtbare Stab-, Bogen-, Schwert- und Sehnengeometrie bleibt ebenfalls oberhalb des Bodens.
- Maximaler Stützankeldrift in den gezielten Proben: 0,071 mm. Gemessene Griffabweichungen bleiben innerhalb der bestehenden Dreieckskontaktgrenzen: Spalt maximal 2,634 mm, Durchdringung maximal 0,825 mm; beim Stab maximal 2,465 bzw. 0,474 mm.
- Eine begrenzte Warnungsprobe mit dem ursprünglichen generierten Hexer löst ein echtes Simulationsereignis im Produktions-World aus. Bewegung, HP, ausstehende Angriffe, RNG und Belohnungen bleiben binär gleich zur Simulation ohne Darstellung. Die Probe verwendet die generierten Warnungsparameter und normale HP, Schaden und Ausrüstung; sie ist kein vollständiger Dungeon-Durchlauf.
- Tatsächlich übersetzter und gedrehter World: globales Ziel, Stützankel, feste Raumkamera und das Wiederaufnehmen eines wirklich gespeicherten Ausweichens bestehen dieselben Prüfungen.

## Unveränderte Native-Bilder

Sechs vollständige **960 × 720 PNG** stammen direkt aus dem Godot-Renderer. Der Standbildversuch beendet sich mit Exit 0; alle sechs Datensätze, originale Kameraprojektion und vollständige tatsächliche Körper-/Waffenabdeckung sind in [native-receipt.json](native-accepted/native-receipt.json) und der Hashreceipt belegt. Die feste Studio-Kamera und das neutrale Licht dienen der Kontrolle von Anatomie, Griffen und Säumen; diese Bilder sind keine kontinuierliche Spielaufnahme und keine Beta-Freigabe.

| Klasse | Ursprüngliche Kampfhaltung | Tatsächlicher niedriger Ausweichschritt |
| --- | --- | --- |
| Arcanist | [Native-PNG](native-accepted/arcanist-source-guard.png) | [Native-PNG](native-accepted/arcanist-actual-lowstep.png) |
| Ranger | [Native-PNG](native-accepted/ranger-source-guard.png) | [Native-PNG](native-accepted/ranger-actual-lowstep.png) |
| Vowkeeper | [Native-PNG](native-accepted/vowkeeper-source-guard.png) | [Native-PNG](native-accepted/vowkeeper-actual-lowstep.png) |

Renderer: Mesa llvmpipe / OpenGL Compatibility, Dummy-Audio. Daraus folgen keine Messungen von Telefon-FPS, Temperatur oder Batterie. Alle sechs Originalbilder wurden auf natürliche Kniehaltung, sichtbare Absenkung, unverformte Körper und Waffen sowie freie Säume geprüft.

## Erhaltene Fehlversuche

Die Receipt unterscheidet alle ursprünglichen Versuche und ihre tatsächlichen Prozesscodes. Dazu gehören behobene Parserfehler, zwei tatsächlich gemessene Ranger-Griffprobleme und die anschließend ergänzte Knieprüfung, die zwölf Rückwärtsbeugungen aufdeckte. Die vorübergehend nicht importierte neue Raider-Axt ließ den ersten Bildversuch nicht starten; dieser Prozess wurde mit Exit 143 beendet. Der zweite Bildversuch hatte zwar Prozesscode 0, verletzte jedoch die strikte vollständige Waffenprojektion und erzeugte nur fünf Bilder; er gilt ausdrücklich als ungültig. Erst der dritte Versuch mit sechs vollständig geprüften Originalbildern ist der akzeptierte Stand.

Die Source-Hashes wurden nach den akzeptierten Prozessen unter dem zuvor erklärten Source-Freeze aufgenommen. Sie binden die angegebenen relevanten Pose-, Rig-, World- und Asset-Dateien; die vollständige Repository-/Video-Bindung erfolgt im übergeordneten 056-Nachweis.
