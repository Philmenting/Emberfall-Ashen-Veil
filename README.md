# Emberfall: Ashen Veil

Ein Android-Idle-Action-RPG im Querformat: Nyra ausrüsten, ihre Klasse und Schwüre wählen, Expeditionen beobachten und mit der verdienten Beute den nächsten Abstieg vorbereiten. Sichtbarer Kampf, Wiederholungen und Offline-Fortschritt verwenden dieselbe deterministische Simulation.

## Aktueller Entwicklungsstand

Der aktuelle Quellstand [`1cc1315`](https://github.com/Philmenting/Emberfall-Ashen-Veil/commit/1cc13152a83c6631590d4df32ca298700a417df7) liegt auf [`improve/animation-craft`](https://github.com/Philmenting/Emberfall-Ashen-Veil/tree/improve/animation-craft) und wird in [PR #5](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5) gesammelt.

- Alle elf Produktionsrollen verwenden erwachsene, vollständig animierte Quaternius-Figuren mit originalem 65-Knochen-Skelett und nativen Händen/Fingern: Arcanist, Ranger, Vowkeeper, vier gewöhnliche Gegner und vier Guardians. Die sieben zuletzt migrierten Rollen haben passende Kleidung, Rüstung, eigene PBR-Materialien und gebundene Waffen-/Zauberclips.
- Textil, Leder und Stahl unterscheiden sich deutlicher. Begrenzte Bewegung an losem Stoff, hinterer Kapuze und Haarenden ergänzt die unveränderte Anatomie; Befestigungen und Waffengriffe bleiben erhalten.
- Lauf, Angriff und echter Angriffsabbruch schließen an die gezeigte Pose an. Arcanists kurze Signatur öffnet früher außerhalb der Schulter, Rangers Zughand liegt an Schulter/Wange, Vowkeeper führen die Klinge aus einer niedrigeren Deckung. Kontaktzeitpunkte und autoritative Spielwerte bleiben erhalten.
- Gemeinsame Bodenprüfungen haben freie Boots, belastete Zehen und die späte Schwert-Rücknahme korrigiert. Der gerichtete Ausweichschritt öffnet mit dem äußeren Fuß und hält Boots und Schienbeine auch beim seitlichen Schritt auseinander. Die [begrenzte KI-Sichtung](docs/design/reference-057/gameplay/MOTION_REVIEW.md) dokumentiert den Bewegungsfluss bei Spielgröße.
- Regionale Raumlichter, ruhigere Böden und ein gezielter Konturakzent bei tatsächlicher Bossverdeckung erhalten die Lesbarkeit. Der Akzent erzeugt seine Zusatzmeshes erst bei Bedarf und vermeidet unnötige Berechnungen. Abgeleitete Kleidungs-/Normalenmeshes behalten ihre importierten Geometrie-LODs.
- Regionale Ruinen, Reliquiare und handgebundene Zaubereffekte enthalten die fortgesetzten Überarbeitungen nach dem früheren 0.48-Teststand. Die Kameralogik bleibt in 057 unverändert.
- Drei Klassen, vier Regionen, autonome Kämpfe, Schwüre, Ausrüstung, Beute, wiederholte Expeditionen und Offline-Fortschritt bleiben erhalten.
- Ein isolierter ARM64-Gerätebeobachter für normale Kämpfe, Framezeiten, Speicher und verfügbare Wärme-/Akkudaten ist vorbereitet. Der tatsächliche Verfügbarkeitstest findet keine physische adb-Verbindung; Telefonmessung und Touch-Abnahme bleiben offen.

[Qualitätsüberarbeitung 057 und Prüfstand](docs/QUALITY_057.md) · [057-Nachweise](docs/design/reference-057/README.md) · [Kampfbewegungen](docs/design/reference-057/motion/README.md) · [Korrigierte Fußfolge](docs/design/reference-057/motion/evade-step-final/README.md) · [Gegner und Guardians](assets/models/hostiles057/README.md)

Alle drei aktuellen CI-Workflows bestehen auf dem exakten 057-Quellbaum: **53 Gameplay-Suiten / 13.424 Prüfungen / null Fehler**, 59 Python-Verträge und 60 Prüfungen exportierter Figurenressourcen; dazu erfolgreiche Android-Builds, APK-Signaturen, Bundlevalidierung und fünf verifizierte Android-Emulator-Laufzeitmarker. [Originalprotokolle und Quellbindung](docs/design/reference-057/ci/README.md) dokumentieren die Ergebnisse. Die Fußkorrektur ist zusätzlich lokal mit neun betroffenen Suiten / 4.321 Checks, 6.288 tatsächlichen Ausweich-/Rückkehrposen und 18 gesichteten nativen Originalbildern geprüft. [Sechs vollständige normale Vorher-/Nachher-Expeditionen mit Ton](docs/design/reference-057/gameplay/README.md) liegen bis Guardian 0 und Beute vor; alle Prozesse, vollständigen Filmdecodes und drei Paarvergleiche bestehen. Autoritative Zustände, Kamera und vollständiges PCM stimmen je Paar überein. Die ergänzte Dokumentation bewahrt [die geprüften Produktionsbytes und Git-Dateimodi](docs/design/reference-057/integration/final-documentation-source-equivalence/README.md).

Die unabhängige KI-Sichtung beurteilt begrenzte zeitliche Ausschnitte und zusätzliche Originalbilder. Ein breiter Ranger-Rückschritt, ruhige Hexer-/Wächtervorbereitungen und ein auffälliger später Wächterübergang im Vowkeeper-Kampf bleiben konkrete Finishpunkte. Der [Qualitätsbericht](docs/QUALITY_057.md) nennt die tatsächliche Reichweite und diese Grenzen. Die Paketkennung bleibt `0.48.0-beta.1`, Android-Version-Code `54`. Smartphone-Frametimes und Touch-Abnahme fehlen weiterhin; eine allgemeine visuelle Beta-Freigabe liegt nicht vor.

Die [056-Vergleichsfilme mit Ton](docs/design/reference-056/gameplay/README.md), [vollständigen 055-Filme bis zur Beute](docs/design/reference-055/gameplay/README.md) und [054-Nachweise](docs/quality054.md) bleiben historische Belege für ihre damaligen Quellen.

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

Bei abweichendem Programmnamen setzt `GODOT_BIN` den Pfad zu Godot 4.7.2. Der vollständige Runner umfasst 53 Godot-Suiten mit isolierten Spielständen sowie die Syntax- und Laufzeitprüfung des Servermoduls. Die GitHub-Workflows prüfen Gameplay und Android separat. Der Android-QA-Export importiert die isolierte Projektkopie einmal und erzeugt daraus alle Prüf-APKs. Der genaue Nachweisstand steht im [Qualitätsbericht](docs/QUALITY_057.md). Google Play wird ausschließlich über den manuellen Veröffentlichungsworkflow bedient.

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
