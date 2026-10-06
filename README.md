# Emberfall: Ashen Veil

Ein Android-Idle-Action-RPG im Querformat: Nyra ausrüsten, ihre Klasse und Schwüre wählen, Expeditionen beobachten und mit der verdienten Beute den nächsten Abstieg vorbereiten. Sichtbarer Kampf, Wiederholungen und Offline-Fortschritt verwenden dieselbe deterministische Simulation.

## Aktueller Entwicklungsstand

Der aktuelle Quellstand liegt auf [`improve/animation-craft`](https://github.com/Philmenting/Emberfall-Ashen-Veil/tree/improve/animation-craft) und wird in [PR #5](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5) gesammelt.

- Arcanist verwendet einen originalen, erwachsenen Quaternius-Charakter mit vollständigem 65-Knochen-Skelett, animierten Fingern, Künstler-Kleidung und übernommenen Animationen. Die übrigen Klassen und Gegner behalten ihre bisherigen Modelle.
- Der Stabgriff wurde anhand der tatsächlich animierten Handgeometrie korrigiert: angepasste Finger, passender Schaft und eine Stützarmhaltung ohne gestreckte Knochen.
- Regionale Ruinen, Reliquiare, Zaubereffekte und Bodenkontakt enthalten die fortgesetzten Überarbeitungen nach dem früheren 0.48-Teststand.
- Drei Klassen, vier Regionen, autonome Kämpfe, Schwüre, Ausrüstung, Beute, wiederholte Expeditionen und Offline-Fortschritt bleiben erhalten.

[Aktuelle Figur](docs/design/reference-053/figure-idle-front.png) · [Stabgriff](docs/design/reference-053/grip-idle-0.4-front.png) · [Gameplay-Aufnahme und genaue Reichweite](docs/design/nyra-staff-grip-correction-053.md) · [Künstlerquellen und Lizenzen](assets/models/nyra052/README.md)

Die Nahaufnahmen zeigen das echte Spielmodell unter diagnostischem Licht. Die gewöhnliche Gameplay-Aufnahme verwendet die vorhandene Spielkamera und Ausrüstung. Die Quellen- und Griffprüfungen belegen konkrete technische Eigenschaften; eine allgemeine visuelle Beta-Freigabe oder Diablo-Immortal-Qualität wird damit nicht behauptet. Die gespeicherte Paketkennung bleibt `0.48.0-beta.1`, Android-Version-Code `54`; diese Integration erhöht keine Release-Version.

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
python3 scripts/run_beta_checks.py --suite source_avatar --suite source_avatar_grip
python3 -m unittest discover -s tests -p test_android_release.py -v
```

Bei abweichendem Programmnamen setzt `GODOT_BIN` den Pfad zu Godot 4.7.2. Der vollständige Runner umfasst 36 Godot-Suiten mit isolierten Spielständen sowie die Syntax- und Laufzeitprüfung des Servermoduls. Die GitHub-Workflows prüfen Gameplay und Android separat. Google Play wird ausschließlich über den manuellen Veröffentlichungsworkflow bedient.

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
