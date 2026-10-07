# Körperbetonte Arcanist-Angriffe, Prüfung 056

Basiszauber, Signatur und Starfall belasten jetzt die echte native Hüfte, beugen beide Knie, übertragen das Gewicht seitlich und schwingen mit Brust und Schultern durch. Die freie Hand behält ihre drei unterschiedlichen Bahnen. Der Kopf kontert Hüfte und Brust gemeinsam, damit die größere Körperdrehung den Blick nicht vom Ziel wegzieht. Die 65 ursprünglichen Bones, ihre Resttransforms, Segmentlängen, Skins und der angenommene Stabgriff bleiben erhalten. Damage, Cooldown, Simulation-Release und die bestehenden 0,34 Sekunden Recovery wurden nicht geändert.

Die [Sichtprüfung 055](../../reference-055/gameplay/MOTION_REVIEW.md) beschreibt den Vorgänger im tatsächlichen Spielbild: Die Handkurven waren verbessert, Torso und Boots aber noch sehr ruhig. Der veröffentlichte Vorgänger `ad4d50bb9dbdc07cea42e2306a79fc65bb642489` bestand [120 Attack- und 296 Grip-Checks](../../reference-055/ci/gameplay-receipt.json). Diese Checkzahlen sind eine technische Baseline und keine Bewertung der Bildqualität. Für 055 existiert in diesem Beleg keine vergleichbare numerische Ganzkörper-RMS-Messung; ein entsprechender Verbesserungsfaktor wird deshalb nicht behauptet.

Die folgenden **nativen Meterwerte** vergleichen die 056-Pose mit einem zweiten echten Arcanist, der zur identischen Phase denselben unüberarbeiteten Künstlerclip sampelt. Auch der Vergleichsactor erhält normale Bodenausrichtung und Stabstütze. Bei der Kniebeugung wird der tatsächliche Winkel zwischen Hüfte, Knie und Knöchel gemessen. Die sichtbare Body-Bewegung rekonstruiert alle vier Original-Skinweights der **1.730 tatsächlich indizierten Vertices** des ursprünglichen Body-Meshes; ein bewegter Socket genügt nicht.

| Phrase | Lastphase | Reale Hüftsenkung gegen Originalclip | Zusätzliche mittlere Kniebeugung | Body-RMS bei Last | Body-RMS im Catch |
| --- | ---: | ---: | ---: | ---: | ---: |
| Basis | 0,33 | 4,41 cm | 18,84° | 6,08 cm | 9,44 cm |
| Signatur | 0,34 | 6,46 cm | 25,52° | 9,41 cm | 12,19 cm |
| Starfall / Heavy | 0,32 | 9,47 cm | 34,45° | 13,16 cm | 16,31 cm |

Catchphasen sind 0,14 / 0,16 / 0,18 der 0,34 Sekunden Recovery, also 47,6 / 54,4 / 61,2 ms nach dem bestätigten Release. Der tatsächliche seitliche Hüfttransfer zwischen Last und Catch beträgt ungefähr 5,81 / 7,28 / 7,15 cm. Alle Angaben beziehen sich auf den nativen Rigraum samt normaler Motionnode-Ausrichtung, vor der zusätzlichen Actor-Body-Skalierung im Dungeon.

| Phrase | Größte horizontale Verschiebung des gewichteten Boot-Mittelpunkts im Windup | Größte einzelne gewichtete Bootfloor-Vertexverschiebung im Windup | Größter Body-RMS-Schritt je 1/60 Windup |
| --- | ---: | ---: | ---: |
| Basis | 1,20 mm | 11,26 mm | 10,37 mm |
| Signatur | 1,71 mm | 15,51 mm | 12,56 mm |
| Starfall / Heavy | 2,09 mm | 18,14 mm | 18,46 mm |

Diese Sohlenwerte sind bewusst Messungen der **wirklich gewichteten Geometrie** und nicht nur der `foot_l`-/`foot_r`-Bones. Von 356 indizierten Original-Bootfloorvertices unter Sourcehöhe 0,055 m tragen 204 zusätzlich Calfgewichte; deren maximaler Calfanteil beträgt 0,491. Eine fixierte Knöchelpose bedeutet daher keine völlig starre Bootoberfläche. Beide ursprünglichen Knöcheltransforms bleiben fest; die original calfgewichtete Geometrie verformt sich begrenzt beim Beugen. Der Mittelpunkt ist hier der Mittelwert der indizierten Floorprobes pro Boot, keine Druckmessung.

Die Tabellen enthalten die im unveränderten Log ausgegebenen **Windup-Maxima**. Recovery wird ebenfalls mit allen gewichteten Floorprobes geprüft: mindestens 2,9 mm Bodenfreiheit, weniger als 8 mm horizontale Mittelpunktabweichung und weniger als 20 mm Einzelvertexabweichung gegen den entsprechenden Originalclip. Die Recovery-Maxima werden im Log nicht numerisch ausgegeben; die Windup-Werte werden deshalb nicht als Maxima der gesamten Attacke bezeichnet.

Die drei unveränderten Erfolglogs sind:

- [Attack: 172 Checks, 0 Fehler](attack.log): 61 Windup- und 60 Recoveryphasen je Phrase, alle nativen Segmentlängen, Rest/Scale, gewichtete Body-/Bootgeometrie, targetgerichteter Blick, Handkontinuität, sauberer Recover-Endzustand, Wiederholung und tatsächliche Cancel-/Release-Abläufe.
- [Zusätzlicher Kontakt-Audit: 295 Checks, 39 Posen, 0 Fehler](attack-contact.log): übernimmt den bestehenden Audit der wirklich indizierten Arm-/Fingertriangles und prüft zusätzlich die stärksten Last- und Catchposen einschließlich gewöhnlicher simulationsgesteuerter Attacken. Das aktuelle Log stammt vom erneuten tatsächlichen Exit-0-Lauf mit dem für den Beta-Runner normalisierten `SOURCE AVATAR ATTACK CONTACT SMOKE`-Banner. Gemessene maximale Shaftpenetration 0,473 mm, maximale Fingerlücke 2,465 mm.
- [Bestehender Grip-Audit: 296 Checks, 40 Posen, 0 Fehler](grip.log): ursprüngliche Walk-/Stop-/Cast-/Recover-Übergänge bleiben unterstützt; maximal 0,472 mm Shaftpenetration und 2,465 mm Fingerlücke.

Alle drei separaten Godot-4.7.2-Headless-Prozesse endeten tatsächlich mit Exit 0. [receipt.json](receipt.json) bindet die ungekürzten Logbytes und die jetzt unveränderten eigenen Combat-/Testdateien per SHA-256. Die gleichzeitig bearbeitete gesamte Spielquelle war für diese lokale Probe noch nicht eingefroren. Diese Blattdatei-Hashes sind daher ausdrücklich kein vorgetäuschter finaler Git-Source-SHA, keine vollständige CI-/Exportbestätigung und keine Aussage über Hardware-Frametimes.

Die RMS-Körpermessung zählt weder Haar, Gesicht noch getrennte Mantelaccessoires mit. Die separaten groben Boundsprüfungen rekonstruieren alle acht ursprünglichen Hauptoberflächen einschließlich Haar. Die 3.501 indizierten Haarvertices bleiben ausschließlich am originalen Head-Bone geskinnt; es wurde keine Haarphysik hinzugefügt. Bounds und unveränderte Skinweights belegen weder kontinuierliche Haar-/Mantelkollisionen noch hochwertige Faltenbewegung. Die tatsächliche Knierichtung und das Gewicht der Figur müssen im dargestellten Bewegungsablauf geprüft werden; Winkel- und Kontaktchecks ersetzen diese Sichtprüfung nicht.

Die ältere Studiofixture `tests/source_avatar_grip_scene_preview.gd` liefert feste Basisposen bei Windup 0,65 / 1,0 und Recovery 0,14 Sekunden. Sie bietet keine Phasenargumente für Last und frühen Catch aller drei Phrasen und wurde hier nicht als deren Sichtnachweis ausgegeben.

Die neue begrenzte Fixture `tests/source_avatar_attack_preview.gd` hat sechs originale 1200×1200-PNGs aufgenommen: Last und früher Catch jeder Phrase an den oben genannten Phasen. Sie behält die ursprüngliche Studiokamera und Beleuchtung samt ReflectionSky bei und rekonstruiert zusätzlich alle acht Hauptskin-, elf separaten Garment- und tatsächlichen Propflächen für World-Floor- und Framefit-Prüfungen. [Originales Renderlog](native/native-preview.log) und [unveränderter nativer Receipt](native/receipt.json) belegen 49 Checks, sechs Bilder und null Fehler; der separate Godot-4.7.2-Prozess auf Display `:108` mit Dummy-Audio endete tatsächlich mit Exit 0. Der Softwaretreiber meldet lediglich, dass V-Sync nicht umgestellt werden kann. Es gibt keine Script-, Shader- oder Compilefehlermeldung.

| Phrase | Originale Lastpose | Originaler früher Catch |
| --- | --- | --- |
| Basis | [basic-load.png](native/basic-load.png) | [basic-catch.png](native/basic-catch.png) |
| Signatur | [skill-load.png](native/skill-load.png) | [skill-catch.png](native/skill-catch.png) |
| Starfall / Heavy | [heavy-load.png](native/heavy-load.png) | [heavy-catch.png](native/heavy-catch.png) |

Alle sechs **originalen nativen PNGs** wurden einzeln in voller Auflösung gesichtet; sie sind keine MP4-Dekodierungen und wurden nicht bearbeitet. Die Knie beugen sich in den Lastposen sichtbar, bei Heavy am stärksten. In dieser Kamera ist keine invertierte Kniefalte und kein gestrecktes Glied sichtbar. Die vergleichbaren Last-/Catchpaare zeigen den seitlichen Hüfttransfer und eine stärkere Brust-/Schulterdrehung; kompakte, hohe und niedrige Handvorbereitung bleiben unterscheidbar. Die rechte Hand unterstützt den vollständigen aufrechten Stab plausibel. Sämtliche gewichteten Hauptskin- und Mantelvertices haben in allen sechs Posen mindestens 3,486 mm **World-Bodenfreiheit nach normaler Actor-Skalierung**; die tatsächlichen Stabvertices liegen mindestens 0,939 m über dem Boden. Alle sechs kompletten Body-/Mantel-/Stabbounds passen in dieselbe Kamera.

Die Stillbilder zeigen weiterhin kantige Sleeve- und Mantelteilformen, statische Haarbuns und wenig Materialdetail in dunklen Boots und Coattails. Die Beinrichtung und die unterscheidbaren Ganzkörperposen sind damit an diesen sechs Phasen sichtbar belegt; Übergangsgeschwindigkeit, Bewegungsgewicht und Qualität in der normalen kleinen Spielfigur lassen sich aus Einzelbildern weiterhin nicht beurteilen.

Der gewöhnliche Bewegungsablauf ist inzwischen im tatsächlich abgeschlossenen [30-Sekunden-Spielclip](../gameplay/after/ordinary-arcanist-first30s.mp4) und seiner [unabhängigen Sichtprüfung](../gameplay/MOTION_REVIEW.md) belegt. Der Capture auf Display `:108` enthält die chronologischen ersten 900 Frames bei normaler HUD/Kamera vom eingefrorenen Source `5e72fc6fad38f7dc829d313d8df0de8289f52573`; der Aufnahmeprozess endete tatsächlich mit Exit 0, der vollständige H.264-/AAC-Decode bestand. [Aufnahmebedingungen und Receipts](../gameplay/README.md) geben den tatsächlich ausgeführten Befehl und die unveränderten Inputs an. Dies ist ein Präfix des gewöhnlichen Dungeons, kein abgeschlossener Dungeon oder Standard-Bossfight.

In [frames.jsonl](../gameplay/after/frames.jsonl) geben `hero_pose.clip`, `attack_time`, `release_time`, `prefix_pose_markers` und die unveränderten Welttransforms von pelvis, Brust, Händen und Füßen die wirklich gespielten Posen an. Die gesichteten nativen Folgen umfassen Signature 4–19, Basic 44–56, erstes Evade 311–317 und Starfall 320–351; die dokumentierte MP4-Decodefolge 791–806 prüft zusätzlich den echten frühen Chain-Abbruch bei 794. Sämtliche drei Phrasen kommen im Präfix tatsächlich vor. Die jeweiligen Original-PNGs und ausdrücklich als verlustbehaftet gekennzeichneten BEFORE-/Cancel-MP4-Dekodierungen werden im Sichtbericht getrennt benannt.

Im normalen Bild stehen die Knie beim Basic-Load 46 und Starfall-Load 328 sichtbar breiter, die Hüfte tiefer; der Vortrieb und die anschließende Rückkehr sind erkennbar. Der Stab bleibt in den geprüften Bildern aufrecht unterstützt. Die tatsächliche Amplitude bleibt moderat, die Signatur besonders kurz und kompakt. Kantiger Robensaum, starres Haar und die kleine Spielfigur begrenzen die Wirkung. Millimetergenaue Finger-/Sohlenkontakte sind aus diesen Pixeln nicht zuverlässig abzulesen; deren Geometriebelege ersetzen keine lückenlose Sichtprüfung.

Die geometrischen Ergebnisse begründen keine AAA-, Diablo-Immortal- oder visuelle Releasefreigabe.
