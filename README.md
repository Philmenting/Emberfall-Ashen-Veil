# Emberfall: Ashen Veil

Ein Android-Idle-Action-RPG im Querformat: Nyra ausrüsten, ihre Klasse und Schwüre wählen, Expeditionen beobachten und mit der verdienten Beute den nächsten Abstieg vorbereiten. Sichtbarer Kampf, Wiederholungen und Offline-Fortschritt verwenden dieselbe deterministische Simulation.

## Aktueller Entwicklungsstand

Der aktuelle Quellstand liegt auf [`improve/animation-craft`](https://github.com/Philmenting/Emberfall-Ashen-Veil/tree/improve/animation-craft) und wird in [PR #5](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5) gesammelt.

- Alle drei Spielerklassen verwenden kompatible erwachsene Quaternius-Figuren mit vollständigem 65-Knochen-Skelett und nativen Händen/Fingern. Ranger trägt das originale Ranger-Outfit; Vowkeeper erhält angepasste Stahlteile auf der kompatiblen Körper-/Kleidungsquelle.
- Der Stabgriff wurde anhand der tatsächlich animierten Handgeometrie korrigiert: angepasste Finger, passender Schaft und eine Stützarmhaltung ohne gestreckte Knochen.
- Arcanists Basiszauber, Signatur und Starfall erhalten weiterlaufende Bewegungskurven, Nachschwingen, Trefferreaktion und saubere Abbruchübergänge. Vowkeeper verwendet originale Sword-Regular-A/B/C-Clips; Rangers Bogenziehen und Auslösen sind eigene Bewegungen auf den unveränderten nativen Armlängen.
- Die vorhandenen Gegner-/Wächtermodelle behalten ihre bisherigen 29-Knochen-Skelette und erhalten abgestimmte Metall-/Stoffmaterialien sowie passendere Vorbereitung, Schlag und Erholung. Der erste Wächter fängt seinen schweren Glockenschlag sichtbar ab.
- Regionale Raumlichter und neutralere Figurenfüllung trennen Körper, Kleidung und Waffen deutlicher vom ruhigeren Boden. Warnkonturen bleiben erhalten; die Lichtüberarbeitung fügt keine zusätzlichen Lichter oder Renderpässe hinzu.
- Die Kampfinszenierung verbessert Nyras Sichtbarkeit vor großen Gegnern, setzt Zaubereffekte an der tatsächlichen Hand und am Treffer an und unterscheidet Vorbereitung, Auslösung und Kontakt auch im Sound.
- Regionale Ruinen, Reliquiare, Zaubereffekte und Bodenkontakt enthalten die fortgesetzten Überarbeitungen nach dem früheren 0.48-Teststand.
- Drei Klassen, vier Regionen, autonome Kämpfe, Schwüre, Ausrüstung, Beute, wiederholte Expeditionen und Offline-Fortschritt bleiben erhalten.
- Ein isolierter ARM64-Gerätebeobachter für normale Kämpfe, Framezeiten, Speicher und verfügbare Wärme-/Akkudaten ist vorbereitet. Der tatsächliche Verfügbarkeitstest findet keine physische adb-Verbindung; Telefonmessung und Touch-Abnahme bleiben offen.

[Qualitätsüberarbeitung 055 und Prüfstand](docs/QUALITY_055.md) · [Native Klassenbilder](docs/design/reference-055/classes/README.md) · [Gegnerbilder](docs/design/reference-055/hostile/README.md) · [Erhaltener Stabgriff](docs/design/reference-053/grip-idle-0.4-front.png) · [Künstlerquellen und Lizenzen](assets/models/classes055/README.md)

Die aktuellen Klassen- und Gegnerbilder zeigen echte Spielmodelle unter diagnostischem Desktoplicht. Die vollständige aktuelle Gameplay-CI besteht mit 45 Godot-Suiten und 5.300 Prüfungen. Auch beide Android-CI-Läufe sind erfolgreich. Die [beiden vollständigen Vergleichsvideos mit Ton](docs/design/reference-055/gameplay/README.md) sind geprüft: jeweils 83,2 Sekunden vom ersten Kampf bis zur Beuteanzeige, mit identischem autoritativem Spielablauf. Die Quellen- und Griffprüfungen belegen konkrete technische Eigenschaften; eine allgemeine visuelle Beta-Freigabe oder Diablo-Immortal-Qualität wird damit nicht behauptet. Die gespeicherte Paketkennung bleibt `0.48.0-beta.1`, Android-Version-Code `54`; diese Integration erhöht keine Release-Version. Die [054-Nachweise](docs/quality054.md) bleiben historische Belege für ihren damaligen Quellstand.

## Lokal starten

Benötigt werden **Godot 4.7.2** und für die Serverprüfungen **Node.js**. Python 3 führt die gebündelte Regression aus. Der normale Spielstart benötigt keinen laufenden Server; die Online-Testfunktionen sind separat.

```sh
git clone --branch improve/animation-craft https://github.com/Philmenting/Emberfall-Ashen-Veil.git
cd Emberfall-Ashen-Veil
godot --headless --path . --editor --import --quit
godot --path .
```

Godot erzeugt Importcache und die aus dem eingebetteten Charakter-GLB extrahierten Texturen selbst. Diese Dateien gehören nicht zum Git-Upload. Die benötigten Laufzeit-JSONs für Griff und Bodenanpassung sind ausdrücklich in den Android-Exportprofilen enthalten.

## Prüfen

```sh
python3 scripts/run_beta_checks.py
python3 scripts/run_beta_checks.py --suite source_avatar_attack --suite class_avatar_quality --suite hostile_quality --suite dungeon_lighting --suite native_capture_audio
python3 -m unittest discover -s tests -p test_android_release.py -v
python3 -m unittest discover -s tests -p test_android_device_probe.py -v
```

Bei abweichendem Programmnamen setzt `GODOT_BIN` den Pfad zu Godot 4.7.2. Der vollständige Runner umfasst 45 Godot-Suiten mit isolierten Spielständen sowie die Syntax- und Laufzeitprüfung des Servermoduls. Die GitHub-Workflows prüfen Gameplay und Android separat. Der Android-QA-Export importiert die isolierte Projektkopie einmal und erzeugt daraus alle Prüf-APKs. Der genaue Nachweisstand steht im [Qualitätsbericht](docs/QUALITY_055.md). Google Play wird ausschließlich über den manuellen Veröffentlichungsworkflow bedient.

## Projekt und Quellen

| Bereich | Inhalt |
| --- | --- |
| `scripts/` | Spiel, Simulation, Speicherstände, Figuren und Benutzeroberfläche |
| `assets/` | Aktive Spielmodelle, Texturen, Animationen, Shader und Lizenzen |
| `art-source/` | Bearbeitbare Konvertierung des verwendeten Charaktermodells; vom Spieleexport ausgeschlossen |
| `tools/art/` | Reproduzierbare Asset- und Konvertierungswerkzeuge |
| `tests/` | Regressionen und klar bezeichnete Aufnahme-Szenen |
| `docs/` | Design, tatsächliche Aufnahmen, Prüfnachweise und Android-Unterlagen |
| `server/` | Separater Nakama-Online-Test und serververwalteter Fortschritt |

Die Quaternius-Standardpakete für Körper, Kleidung und Animationen stehen unter **CC0 1.0**. Die Original-Lizenzen, Herstellerhinweise, Quell-Hashes und der Wiederaufbau sind [hier dokumentiert](assets/models/nyra052/README.md). Die enthaltene Blender-Datei ist eine bearbeitbare Konvertierung, kein ursprüngliches Künstler-Sculpt. Weitere Assetherkünfte bleiben bei ihren jeweiligen Dateien dokumentiert.

[Produktziel](PRODUCT.md) · [Designsystem](DESIGN.md) · [Quellintegration](docs/design/nyra-authored-integration-052.md) · [Griffkorrektur und Prüfungen](docs/design/nyra-staff-grip-correction-053.md) · [Repository- und Exportprüfung](docs/design/repository-cleanup-053.md) · [Historische Entwicklungsberichte](HISTORY.md)
