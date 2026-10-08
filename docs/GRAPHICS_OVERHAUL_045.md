# Grafiküberarbeitung · 0.45.0-beta.1

Die vom Nutzer genannte Richtung ist **Diablo Immortal**: eine düstere,
isometrische Fantasywelt mit lesbaren Kämpfen und unterscheidbaren Materialien.
Emberfall verwendet eigene Figuren, Architektur, Bilder und Spielregeln.
Version-Code **51**.

## Umsetzung

- Fünf neue originale Umgebungsbilder für Lager, Hollow Spire, Drowned Archive,
  Glass Ossuary und Cinder Citadel. Die Bilder liegen hinter echter 3D-Geometrie.
- Verwitterte Steinflächen mit Farb-, Rauheits- und Normalmaps; durchgehender
  Untergrund unter den Kammern. Verbundene Rückwände, Pfeiler, Bögen und regionale
  Einrichtung umschließen die aktive Kammer; niedrigere Pflasterflächen tragen
  die vorhandenen Warnungsflächen bis über den früheren Spielfeldrand hinaus.
  Neue Mauern und ganze Einrichtungsobjekte lassen die tatsächlichen Laufwege
  mit 0,20 Welteinheiten Abstand frei; Durchgänge bleiben vollständig offen.
- Gedämpftes Eisen, Silber, Bronze, Stoff und Leder. Vowkeeper erhält geschichtete
  Schulterplatten, Arcanist Kragen und Armabschlüsse, Ranger Gurte und Nieten.
  Eine originale Materialtextur ergänzt Holzmaserung, Leder, Leinen und Stahl;
  Materialdetails bleiben beim Bewegen am Körper. Alle elf Figuren bleiben
  vollständig räumlich, mit 29 Knochen, neun nativen Clips und einer gemeinsamen
  deckenden GPU-Oberfläche pro Figur; jede bleibt unter 40.000 Dreiecken.
- Nyras Kopf ist für alle drei Klassen neu aufgebaut: zusammenhängende Wangen-,
  Kiefer- und Nasenflächen, geformte Augenlider, zurückhaltende Lippen und feinere
  silberne Haarsträhnen. Eine originale Hauttextur wird anhand gemessener
  Gesichtsmerkmale auf die räumliche Oberfläche gelegt. Die Live-Porträts zeigen
  das Gesicht größer und verwenden dieselbe Geometrie wie Lager und Kampf.
- Eine steilere, feste Kampfperspektive und eine auf den freien HUD-Bereich
  gerichtete Kamera. Treffer, Waffenbewegung und Zielwechsel erzeugen weiterhin
  kein Kamerawackeln. Tatsächliche Warnungsflächen behalten ihre volle Größe.
- Schmiede, Expeditionstisch und Portal als echte 3D-Objekte. Die neue Schmiede
  enthält Feuerraum, Amboss, Werkzeuge und Blasebalg; der Tisch trägt eine Karte,
  ein Buch und eine Kerze. Vier leere steinerne Fassungen zeigen die Siegelsammlung;
  Wächtersiegel erscheinen nur nach dem entsprechenden Sieg.
- Durchsichtige Schutzflächen für Guard und Mana Ward, gebunden an den echten
  Kampfzustand. Reduced Motion hält die Portalbewegung an; Battery reduziert
  Schatten, Zusatzlicht und Materialrelief.

Die Kampfsimulation, gespeicherte Ausrüstung, Beute, AFK-Abrechnung und die
Lesepause aus 0.44 verwenden dieselben Regeln. Die vorhandenen Skelettclips
wurden in diesem Grafikausbau weiterverwendet, nicht als neue Motion-Capture-
Animationen ausgegeben.
Die Gesichtsüberarbeitung ergänzt keine separate Mimik- oder Sprachanimation.

## Native Nachweise

Die [Ansichten](previews/graphics-overhaul/) umfassen 2424×1080, 1040×1080 und
854×480 mit Large Text: Lager, drei Klassen, Lesepause, Manareserve und alle vier
Wächter. Die Porträtansicht zeigt das tatsächliche Modell in zwei Ausrüstungs-
Qualitäten. Wächteraufnahmen erhöhen Life ausschließlich für die Erreichbarkeit
der Warnungszustände; sie sind keine Balancebelege.

Der [fünfzehnsekündige Gameplay-Clip](previews/graphics-overhaul/emberfall-graphics-045.mp4)
verwendet normale Arcanist-Startausrüstung. Sekunden 5–8 zeigen die echte
Lesepause. Er besteht aus nativen Godot-Bildern mit 30 exportierten Bildern je
Sekunde, ohne beschleunigte Simulation und ohne Tonspur. Er zeigt den Durchgang bis zur
Ankunft in der nächsten Kammer am Pilgerbrunnen. Dies misst keine
Bildrate auf einem Smartphone. Quellen und Prüfsummen stehen in `provenance.json`.

Der Bibliotheks-Export bündelt 236 zuvor getrennte Meshes zu acht
Materialgruppen. Im geprüften Archive-Layout (Seed 1979) sinkt die Zahl statischer
Batches von 2.750 auf 315. Das ist eine gemessene Verringerung der
Rendergeometrie-Aufteilung, keine Bildratenmessung auf einem Gerät.

Die unabhängige Bildabnahme und ihre genaue Reichweite werden in
[graphics-review-045-final.md](design/graphics-review-045-final.md) dokumentiert.
Lokal bestehen 32 Godot-Testsuiten mit 3.555 Prüfungen, die Server-Regression
und fünf Android-Paketprüfer-Tests. Davon prüfen 40 neue Fälle die tatsächliche
Architekturgeometrie, freie Passagen und begrenzte Mesh-/Batchzahlen.
[Regressionsprotokoll](previews/graphics-overhaul/local-regression.txt).

Test- und Android-Build-Ergebnisse für den jeweiligen Commit stehen in
[PR 5](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5).

Die Referenz bestimmt die gestalterische Richtung; diese Umsetzung behauptet
keine Gleichwertigkeit mit der Produktion von Diablo Immortal. Leistung,
Temperatur, Akkuverbrauch und Bedienung auf einem physischen Pixel Fold sind
durch die Rendering- und Emulatortests nicht belegt. Google Play wurde nicht
veröffentlicht.

```sh
GODOT_BIN=/path/to/godot-4.7.2 python3 scripts/run_beta_checks.py
godot --path . tests/graphics_overhaul_preview.tscn -- --capture-dir=/tmp/graphics
godot --path . --fixed-fps 30 tests/graphics_overhaul_preview.tscn -- --video --capture-dir=/tmp/graphics-clip
blender -b -t 2 --python tools/art/build_camp_furniture.py
```
