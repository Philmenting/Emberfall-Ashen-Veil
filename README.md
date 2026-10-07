# Emberfall: Ashen Veil

Ein Android-Idle-Action-RPG im Querformat: Nyra ausrüsten, ihre Klasse und Schwüre wählen, Expeditionen beobachten und mit der verdienten Beute den nächsten Abstieg vorbereiten. Sichtbarer Kampf, Wiederholungen und Offline-Fortschritt verwenden dieselbe deterministische Simulation.

## Aktueller Entwicklungsstand

Der aktuelle Quellstand liegt auf [`improve/animation-craft`](https://github.com/Philmenting/Emberfall-Ashen-Veil/tree/improve/animation-craft) und wird in [PR #5](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5) gesammelt.

- Alle drei Spielerklassen verwenden kompatible erwachsene Quaternius-Figuren mit vollständigem 65-Knochen-Skelett und nativen Händen/Fingern. Ranger trägt das originale Ranger-Outfit; Vowkeeper erhält angepasste Stahlteile auf der kompatiblen Körper-/Kleidungsquelle.
- Der Stabgriff wurde anhand der tatsächlich animierten Handgeometrie korrigiert: angepasste Finger, passender Schaft und eine Stützarmhaltung ohne gestreckte Knochen.
- Arcanists Basiszauber, Signatur und Starfall verlagern jetzt das Körpergewicht über Hüfte, gebeugte Knie, Brust und Schultern. Die Figur fängt ihre Bewegung nach dem Auslösen ab; der Stab bleibt an der tatsächlich animierten Hand. Vowkeeper verwendet originale Sword-Regular-A/B/C-Clips; Rangers Bogenziehen und Auslösen sind eigene Bewegungen auf den unveränderten nativen Armlängen.
- Der gewöhnliche Raider verwendet einen zusammenhängenden bekleideten Quaternius-Körper mit erwachsenem Gesicht, 65 nativen Knochen, originalen Bewegungs- und Trefferclips sowie einer angepassten Quaternius-Axt. Die übrigen sieben Gegner-/Wächtertypen behalten ihre 29-Knochen-Skelette. Der erste Wächter fängt seinen schweren Glockenschlag sichtbar ab.
- Alle drei Spielerklassen erhalten einen eigenen niedrigen, gerichteten Ausweichschritt mit Bodenkontakt und einem Übergang zurück in die Kampfhaltung. Der Schritt folgt der tatsächlichen Ausweichbewegung der Simulation.
- Regionale Raumlichter und neutralere Figurenfüllung trennen Körper, Kleidung und Waffen deutlicher vom ruhigeren Boden. Warnkonturen bleiben erhalten; die Lichtüberarbeitung fügt keine zusätzlichen Lichter oder Renderpässe hinzu.
- Ein dezenter Konturpass macht Nyra bei tatsächlicher Verdeckung durch große Gegner erkennbar. Gegner und Schatten bleiben geschlossen; das bisherige Dither-Ausblenden entfällt. Zaubereffekte sitzen an der tatsächlichen Hand und am Treffer; Vorbereitung, Auslösung und Kontakt unterscheiden sich auch im Sound.
- Regionale Ruinen, Reliquiare, Zaubereffekte und Bodenkontakt enthalten die fortgesetzten Überarbeitungen nach dem früheren 0.48-Teststand.
- Drei Klassen, vier Regionen, autonome Kämpfe, Schwüre, Ausrüstung, Beute, wiederholte Expeditionen und Offline-Fortschritt bleiben erhalten.
- Ein isolierter ARM64-Gerätebeobachter für normale Kämpfe, Framezeiten, Speicher und verfügbare Wärme-/Akkudaten ist vorbereitet. Der tatsächliche Verfügbarkeitstest findet keine physische adb-Verbindung; Telefonmessung und Touch-Abnahme bleiben offen.

[Qualitätsüberarbeitung 056 und Prüfstand](docs/QUALITY_056.md) · [Angriffsposen](docs/design/reference-056/attacks/README.md) · [Ausweichposen](docs/design/reference-056/evade/README.md) · [Bossverdeckung](docs/design/reference-056/combat-readability/README.md) · [Raider-Quellen und Lizenzen](assets/models/raider056/README.md)

Die vollständige aktuelle Gameplay-CI besteht mit **49 Godot-Suiten und 7.734 Prüfungen**, 48 Python-Tests sowie 32 Prüfungen exportierter Figurenressourcen. Auch Android-Builds, Bundlevalidierung und Android-Laufzeitprüfung sind erfolgreich; [Originalprotokolle und Quellbindung](docs/design/reference-056/ci/README.md) dokumentieren alle drei Läufe. Die [30-Sekunden-Vergleichsfilme mit Ton](docs/design/reference-056/gameplay/README.md) zeigen den normalen Kampf mit denselben 900 autoritativen Spiel- und Kameraframes. Der [Sichtbericht](docs/design/reference-056/gameplay/MOTION_REVIEW.md) bestätigt tiefere Lastposen, gerichtetes niedriges Ausweichen und den lesbareren Raider; Signatur und Starfall bleiben bei der kleinen Figur kurz beziehungsweise moderat. Die Studio- und Griffnachweise belegen einzelne technische Eigenschaften. Die Paketkennung bleibt `0.48.0-beta.1`, Android-Version-Code `54`. Die [vollständigen 055-Filme bis zur Beute](docs/design/reference-055/gameplay/README.md) und [054-Nachweise](docs/quality054.md) bleiben historische Belege für ihre damaligen Quellen; eine allgemeine visuelle Beta-Freigabe wird hier nicht behauptet.

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
python3 scripts/run_beta_checks.py --suite source_avatar_attack_contact --suite source_avatar_evade --suite raider_native --suite combat_occlusion
python3 -m unittest discover -s tests -p test_android_release.py -v
python3 -m unittest discover -s tests -p test_android_device_probe.py -v
```

Bei abweichendem Programmnamen setzt `GODOT_BIN` den Pfad zu Godot 4.7.2. Der vollständige Runner umfasst 49 Godot-Suiten mit isolierten Spielständen sowie die Syntax- und Laufzeitprüfung des Servermoduls. Die GitHub-Workflows prüfen Gameplay und Android separat. Der Android-QA-Export importiert die isolierte Projektkopie einmal und erzeugt daraus alle Prüf-APKs. Der genaue Nachweisstand steht im [Qualitätsbericht](docs/QUALITY_056.md). Google Play wird ausschließlich über den manuellen Veröffentlichungsworkflow bedient.

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
