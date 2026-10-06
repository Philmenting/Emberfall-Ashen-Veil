# Qualitätsüberarbeitung 055

Stand vom 6. Oktober 2026: Die Angriffe, die vorhandenen Gegner, die Lichtgestaltung und die beiden weiteren Spielerklassen sind überarbeitet. Für die fünfte Aufgabe ist ein physischer Android-Prüflauf vorbereitet; seine tatsächliche Durchführung und die Touch-Abnahme bleiben offen. Die vollständige Regression mit 45 Godot-Suiten, der CI-Nachweis des integrierten 055-Quellstands und die beiden durchgehenden Vergleichsvideos mit Ton stehen ebenfalls noch aus. Die nachstehenden Teilprüfungen ersetzen diese Abnahmen nicht.

Die Integration gehört zu [`improve/animation-craft`](https://github.com/Philmenting/Emberfall-Ashen-Veil/tree/improve/animation-craft) und [PR #5](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5). Die gespeicherte Paketkennung bleibt `0.48.0-beta.1`, Android-Version-Code `54`. „055“ bezeichnet den Arbeits- und Nachweisstand, keinen veröffentlichten Release.

## 1. Angriffe und Trefferreaktionen

Arcanist behält den originalen erwachsenen Quaternius-Charakter mit seinem vollständigen 65-Knochen-Skelett, der übernommenen Kleidung und dem korrigierten Stabgriff. Basiszauber, Signatur und Starfall verwenden weiterhin unterschiedliche Vorbereitung, Auslösung und Erholung. Die überarbeiteten kubischen Bewegungskurven führen die Hand durch Zwischenposen, statt an jedem Schlüsselbild anzuhalten. Becken und Brust leiten die Bewegung zeitlich versetzt ein; der Arm folgt. Nach der Auslösung läuft die Hand kurz weiter und kehrt dann in die Haltung zurück.

Die ursprünglichen Spell-Enter-/Shoot-/Exit-Clips liefern die Ausgangsbewegung. Die zusätzlichen Hand- und Körperkurven arbeiten auf dem unveränderten nativen Skelett; die ursprünglichen Arm-, Bein- und Fingerlängen bleiben erhalten. Gepflanzte Sohlen werden während der Körperdrehung gehalten. Ein echter Treffer bewegt Brust und Kopf mit begrenzter Kompression und Rückfederung. Ein abgebrochener Zauber wechselt aus der aktuellen sichtbaren Pose zurück in die Fortbewegung. Schaden, Mana, Abklingzeit und Auslösezeit gehören weiterhin der Simulation; die Kamera erhält durch diese Bewegungen keine neuen Impulse.

Die lokale Angriffsprüfung besteht mit **120 Checks, 0 Fehlern**; die erhaltene Griffprüfung mit **296 Checks, 40 tatsächlichen Posen, 0 Fehlern**. Geprüft werden unter anderem der tatsächliche gewichtete Handschuh, Geschwindigkeit durch Zwischenposen, Nachschwingen, native Kettenlängen, wiederholte Posen und echte Abbrüche. Quellen: [Angriffskurven](../scripts/source_avatar_combat.gd), [Angriffsprüfung](../tests/source_avatar_attack_smoke.gd), [Griffprüfung](../tests/source_avatar_grip_smoke.gd). Die Wahrnehmung im vollständigen Spieltempo gehört noch zum Videovergleich.

## 2. Gegner und erster Wächter

Die vier normalen Gegnerrollen und die vier regionalen Wächter behalten ihre bisherigen modularen Modelle und ihre ursprünglichen 29-Knochen-Skelette. Ihre Materialien unterscheiden nun gealtertes Metall, Stoff, Leder, Knochen und zurückhaltende leuchtende Einlagen. Die Farb- und Materialwerte werden einmal in die vorhandenen Mesh-Kanäle übernommen; die Animation verändert keine Quellvertices.

Angriffsrollen erhalten passendere Vorbereitung, Kontakt und Erholung: ein kompakter Klauenstoß, eine gerichtete Zauberhaltung, ein Angriff mit vorgeschobenem Schild und ein freier diagonaler Klingenschlag. Der Bell Warden hebt seinen Glockenkolben asymmetrisch, hält das Gegengewicht in der anderen Hand und fängt den schweren Schlag mit den Knien ab. Warnhaltung und tatsächlicher Schlag bleiben getrennte Zustände. Die Trefferreaktion arbeitet auf dem echten Körper; ein vorhandener Umhangsprung beim Wechsel von Kontakt zu Erholung wurde korrigiert.

Die [Gegnerprüfung und Originalbilder](design/reference-055/hostile/README.md) belegen **81 Checks, 0 Fehler** über alle acht Erscheinungen. Sie prüfen gewichtete Körper-/Waffen-/Stoffgeometrie, Bodenkontakt, anatomische Längen, Kontaktkontinuität und Warn-/Erholungszustände. Die zusätzlich gespeicherte 164-Check-Prüfung wurde vor der Migration der Spielerklassen ausgeführt und ist ausdrücklich ein Zwischenbeleg. Die fünf Bilder sind unveränderte native Studioaufnahmen auf dem Desktop; sie zeigen keine normale durchgehende Expedition und messen keine Handy-Leistung.

## 3. Licht, Boden und Gefahrenlesbarkeit

Vier regionale Lichtprofile stimmen die vorhandenen Raumlichter auf das jeweilige Mauerwerk ab. Neutrales Figurenlicht und das Kantenlicht treffen die sichtbaren Körper, Kleidung und Waffen auf deren eigener Render-Ebene. Das mitlaufende Fülllicht beleuchtet diese Figuren und hellt den Boden unter Nyra nicht mehr mit einer wandernden Lichtpfütze auf. Das vorhandene Raumlicht erhält den Bodenkontakt und seinen einzelnen Schattenpass.

Der Boden komprimiert kleinteilige Farbkontraste um den gemessenen mittleren Farbwert seiner Originaltextur. Trockener Stein reflektiert weniger stark; feuchte Archive-Flächen behalten ihren Glanz. Die Innenflächen großer Warnzonen sind ruhiger, während die feste Kontur und die tatsächliche Gefahrengeometrie unverändert bleiben. Die Lichtüberarbeitung fügt keine zusätzlichen Lichter, Schatten- oder Postprocessing-Pässe und keine zusätzlichen Bodentexturabfragen hinzu. Daraus folgt keine Behauptung, dass der gesamte neue Figurenbestand dieselbe Renderlast wie 054 hat.

Die lokale [Lichtprüfung](../tests/dungeon_lighting_smoke.gd) besteht mit **60 Checks, 0 Fehlern**. Sie inspiziert die effektiven Licht-/Mesh-Masken in zwölf echten Welten, die erhaltene Raumbeleuchtung, den einzelnen Schattenpass und unveränderte Simulation und Kamera. Dieser Teilbeleg entstand vor der abschließenden Klassenintegration; die gemeinsame Regression und die normale Gameplay-Aufnahme müssen den integrierten Stand noch bestätigen.

## 4. Ranger und Vowkeeper auf dem nativen Figurenstandard

Beide Klassen verwenden jetzt kompatible erwachsene Quaternius-Anatomie auf dem ursprünglichen **65-Knochen-Skelett**, einschließlich nativer Hände und Finger. Kopf, Augen und Brauen stammen aus dem bereits akzeptierten Originalmodell. Ranger trägt das vollständige originale Ranger-Outfit mit Kapuze, Armschutz, Gürtel, Beinen und Stiefeln. Vowkeeper verwendet die kompatible Körper-/Kleidungsquelle mit entfernter Kapuze sowie separat angepassten Stahlflächen für Brust, Schultern und Unterarme. Seine vollständigen originalen Lederstiefel bleiben erhalten. Quellkörper, UVs, native Bindungen und anatomische Ruhelängen bleiben unangetastet.

Vowkeeper nutzt die echten originalen **Sword Regular A/B/C**-Clips aus Quaternius' Universal Animation Library 2 Standard. Die Bewegungen werden anhand der Quell- und Ziel-Ruhelage übertragen; Wegbewegung bestimmt weiterhin die Simulation. Der bestehende Spielschwertgriff ist an den tatsächlichen Fingerraum angepasst.

Die Seltenheit ausgerüsteter Gegenstände erreicht außerdem wieder die tatsächlichen nativen Materialflächen. Zurückhaltende Farb- und Rauheitsakzente sitzen auf vorhandenen Waffen, Kleidung und Stahlteilen; Haut, Haare und Augen bleiben unverändert. Common und Ablegen stellen die ursprünglichen Materialwerte exakt wieder her. Wo das feste Modell kein separates Itemteil besitzt, nutzt der Akzent ein vorhandenes passendes Detail (Vowkeepers Schulterschutz für Helmet, Arcanists Bronze-Schulterschutz für Gloves). Diese Darstellung erzeugt keine neue Ausrüstungsgeometrie. Die neue [Materialprüfung und Zuordnung](design/reference-055/native-equipment/README.md) besteht mit **129 Checks, 0 Fehlern**; sie prüft echte sichtbare Materialien, alle sechs Slots, Wiederherstellung, Klassenwechsel und unabhängige Porträts.

Ranger behält die originalen Idle-/Walk-/Death-Clips. Für Ziehen und Auslösen des Bogens wurde eine eigene Bewegung mit zwei anatomisch gelösten Armen entwickelt; das verwendete Standardpaket enthält keinen Künstler-Bogenziehclip. Der vorhandene Bogengriff ist an die Hand angepasst, die gerenderte Sehne berührt den tatsächlichen gewichteten Finger und der Pfeil liegt oberhalb der Greiffinger. Sein Ursprung folgt der echten Pfeilspitze; der eingelegte Pfeil verschwindet bei der simulationsbestätigten Auslösung.

Die [Klassenbelege](design/reference-055/classes/README.md) enthalten **398 Checks, 0 Fehler und 50 an der gewichteten Geometrie gemessene Griffposen**, einschließlich echter Trefferreaktionen. Der größte gemessene Fingerabstand beträgt 2,644 mm, die größte Griffdurchdringung 0,823 mm. Die maximale sichtbare Geometrie umfasst 33.294 Dreiecke für Ranger einschließlich Pfeil und Sehne sowie 31.440 für Vowkeeper einschließlich Stahlteilen und Schwert. Die sieben ausgewählten unveränderten Studio-PNGs stammen aus einem tatsächlichen 14-Bilder-Lauf. Sie belegen Modell-/Griffzustände und sind keine Gameplay- oder Android-Aufnahmen. Es gibt weiterhin keine Gesichts-Blendshape-Animationen und keinen neuen hochauflösenden Rüstungs-Bake. [Herkunft, Lizenzen und Wiederaufbau](../assets/models/classes055/README.md) dokumentieren die originalen CC0-Standardquellen.

## 5. Physische Android-Prüfung vorbereiten

Der [Gerätebeobachter](device-quality-055.md) prüft vor der Installation eine separate, debuggable, offline nutzbare ARM64-QA-App. Das reguläre Spiel und sein Spielstand werden nicht gelöscht. Der Standardlauf beobachtet drei Klassen in Balanced und Battery jeweils 200 Sekunden lang: normale Startausrüstung, reale zeitgesteuerte Kämpfe, Reise und Wächterkampf; Wiederholungen verbessern die Ausrüstung nicht. Frame-Abstände, CPU-/Renderzeiten, tatsächliche Rendergrößen einschließlich automatischer Auflösungsreduzierung, Speicher und verfügbare Wärme-/Akkudaten werden getrennt festgehalten. Nicht verfügbare GPU-Zeitstempel oder Sensoren bleiben als solche gekennzeichnet. Der Commit ist eine zugeordnete Exportangabe; der APK-Hash wird tatsächlich berechnet.

Die 13 Python-Verträge prüfen den Beobachter mit Fake-adb. Der [tatsächliche Verfügbarkeitstest](design/reference-055/device-observer/physical-availability.json) ergibt **`unavailable`, Exit 3, `physical_device_measured: false`**: In dieser Umgebung gibt es keine verfügbare adb-Verbindung zu einem physischen Android-Gerät. Eine echte Messung von Framerate, Speicher, Wärme und Akku sowie die Bedienungsprüfung mit Finger, Android Back und Lebenszyklus stehen deshalb offen. Eine kurze Desktop-Prüfung der QA-Szene kann diese Lücke nicht schließen.

## Vergleich mit Ton und verbleibende Nachweise

Die Aufnahmewerkzeuge beobachten die tatsächlich akzeptierten Musik-/Soundstreams, sechs Effektplätze und Lautstärke-/Pausenzustände des vorhandenen AudioDirectors. Native Godot-Decoder erzeugen eine chronologische Stereo-PCM-Spur passend zu den festen 30-Hz-Videobildern; daraus wird die AAC-Spur des MP4 kodiert. Beobachtungssignale verändern die normalen Produktionsklänge nicht. Die Aufnahme ist eine native, feste Schritte verwendende Mischung und keine physische Lautsprecher- oder Echtzeit-AudioServer-Aufzeichnung. Capture-Wartezeit, Readback und PNG-Transport sind kein Spiel-FPS-Maßstab.

Der lokale Audiofixture-Teiltest besteht mit **79 Checks, 0 Fehlern** und prüft auch die tatsächlichen letzten Samples kurzer Effekte, gepufferte native Resampler-Daten und exakt stille Restframes. Die [lokalen Integrationsbelege](design/reference-055/verification/receipt.json) enthalten außerdem 1.394 erfolgreiche Checks aus neun abschließend korrigierten Suiten, 39 Python-Verträge und die saubere 20-Check-Prüfung der kalt importierten Paketressourcen. Der erste 44-Suiten-Lauf hatte fünf Fehler in Migration und alten Erwartungen; diese wurden behoben und gezielt erneut geprüft. Der gesamte aktuelle 45-Suiten-Lauf bleibt bis zum CI-Ergebnis offen. Die zusätzlichen Python-Verträge für Audio-/Videouhr, Export und Android-Beobachtung ergeben insgesamt **39 erfolgreiche Tests**. Die ausgegebenen Fake-adb-Erfolgsberichte sind simulierte Testfälle. Die zwei vorgesehenen vollständigen Audioaufnahmen — Referenzstand 054 und integrierter Stand 055 — sind noch **pending**; aus den vorhandenen Studio-PNGs wird kein bestandener Spieltempovergleich abgeleitet.

| Nachweis | Stand |
| --- | --- |
| Native Klassen, Waffenhaltungen und Studioaufnahmen | Belegt; [398-Check-Receipt](design/reference-055/classes/receipt.json) |
| Vorhandene Gegner und Studioaufnahmen | Belegt; [81-Check-Receipt](design/reference-055/hostile/receipt.json) |
| Arcanist-Kurven, erhaltener Stabgriff, Licht und Audiofixture | Lokale Teilprüfungen bestanden; integrierter Gesamtbeleg pending |
| Vollständige 45-Godot-Suiten-Regression mit Serverprüfungen | **Pending** |
| CI für den integrierten 055-Quellstand einschließlich Android | **Pending** |
| Zwei vollständige Vergleichsexpeditionen mit Ton | **Pending** |
| Physische Telefonmessung und Touch-/Lebenszyklus-Abnahme | **Offen; Hardware nicht verfügbar** |
| Allgemeine visuelle Beta-/Veröffentlichungsfreigabe | **Offen** |

Die [054-Prüfungen und damalige Aufnahme](quality054.md) bleiben ihrem damaligen Quellstand zugeordnet. Ihre grünen CI-Läufe bestätigen keine späteren 055-Änderungen. Die neue Implementierung wird anhand der aktuellen Quellen, Receipts, Gesamtprüfungen und tatsächlichen Vergleichsaufnahme beurteilt.
