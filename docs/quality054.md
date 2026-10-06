# Qualitätsüberarbeitung 054

Diese Überarbeitung konzentriert sich auf Nyra Arcanist und ihren vollständigen Kampf gegen den ersten Guardian. Die Paketkennung bleibt `0.48.0-beta.1`, Android-Version-Code `54`. Die übrigen Klassen behalten ihre bisherigen Figurenmodelle.

## Umgesetzte Änderungen

| Punkt | Änderung | Nachweisumfang |
| --- | --- | --- |
| Android-Prüfung | Eine isolierte Projektkopie, ein serieller Asset-Import und mehrere QA-Exporte ersetzen wiederholte kalte Importe. Exportfehler stoppen den Ablauf; Log und Paketverträge werden geprüft. Ein Prozessmonitor bewahrt vollständige Android-Logs und Exitgründe und erkennt einen verlorenen Prozess sofort. | Der serielle Import und alle vier APK-Exporte bestehen im Android-Workflow. Der anschließende AFK-Lauf muss noch vollständig durchlaufen. |
| Angriffe | Basiszauber, Signatur und Starfall erhalten eigene Vorbereitung, Torso- und Armbewegung und Erholung. Starfall nutzt seine vorhandene lange Vorbereitung; Schadensformeln, Cooldowns und Simulation bleiben maßgeblich. | `source_avatar_attack` prüft tatsächliche Posen, Kontaktzeiten, Stabgriff, Bodenkontakt und die Unabhängigkeit von vorherigen Animationen. |
| Figur | Eine zusätzliche dunkle Kleidungsschicht, Mantelpartien und Metallakzente binden an das ursprüngliche Skelett. Haut, Haare und vorhandene PBR-Materialien werden abgestimmt. | `source_avatar_style` prüft die tatsächlich gewichteten Zubehörflächen und ihre Bodenfreiheit. |
| Kampfinszenierung | Vordergründige Gegner geben im Bereich der verdeckten Figur Sicht frei; ihre vollständigen Schatten bleiben erhalten. Vorbereitung folgt der echten Zauberhand, Projektile und Treffer dem tatsächlichen Kontakt. Sound unterscheidet Sammlung, Auslösung und Kontakt; Mehrfachtreffer stapeln keine Kontaktstimmen. | `guardian_presentation` prüft die reale gewichtete Figur, Kamera- und Simulationskonstanz. `combat_audio` prüft PCM, Ereigniszuordnung, Pegel und die verwendeten Stimmen. |
| Durchgehendes Gameplay | Eine neue Aufnahmeszene zeichnet dieselbe Expedition vom Start bis zu ihrem tatsächlichen Ende und der Ergebnisanzeige auf. | [83,2 Sekunden ohne Schnitte](design/reference-054/gameplay/README.md), 2.496 Frames; Wächter und Expedition tatsächlich besiegt, Ergebnisanzeige erreicht. Vollständige Dekodierung und unveränderte Quellen-Hashes geprüft. |

## Erhaltene Quellen und Grenzen

Das ursprüngliche [Quaternius-Modell](../assets/models/nyra052/README.md) bleibt bytegleich: SHA-256 `d489ad6a55510a5bd36f0215fcb3be1a596cab6094500f19476e3fc172e7e4e1`. Seine acht ursprünglichen Flächen, UVs, 65 Knochen, Resttransformationen und Hautgewichte werden erhalten. Die [zusätzliche Kleidung](../assets/models/nyra054/README.md) ist getrennte Geometrie mit 3.936 Dreiecken an demselben Skelett. Der korrigierte Stab und sein Griffprofil bleiben die Quelle aus [Überarbeitung 053](design/nyra-staff-grip-correction-053.md).

Vor jedem neuen Animationssample wird die unveränderte native Ausgangspose wiederhergestellt. Auch wiederholte Samples stellen ihre ursprüngliche Pose wieder her, bevor zusätzliche Bewegung und Armstützung angewandt werden. Dadurch sammeln sich auf Knochen, deren konstante Tracks Godot beim Import entfernt, keine vorherigen Torso- oder IK-Korrekturen an. Der Cache speichert native Quaternionen, Positionen und Skalierungen direkt; die unveränderten Stillstandsprüfungen ergeben exakt null Abweichung.

Dies ist eine Überarbeitung des vorhandenen stilisierten Modells und seiner Darstellung. Es gibt kein neues hochauflösendes Gesichtssculpt, keine Gesichtsanimation und keine Freigabe als Diablo-Immortal-Qualität.

## Kontinuierliche Aufnahme

Die [Aufnahmeszene](../tests/arcanist_quality_gameplay_preview.gd) verwendet gewöhnliche Anfangsausrüstung und Seed 1979. Chain und Starfall werden über die reguläre Armory-Auswahl ausgerüstet; die Klassen-Signatur bleibt vorhanden. Jeder Welt-Schritt beträgt `1/30` Sekunde. Reise, Kämpfe und Warnungen werden vollständig aufgezeichnet; es gibt keine übersprungenen Zeitabschnitte oder erhöhten Kampfwerte.

[Der Streaming-Aufnehmer](../tools/capture_arcanist_quality.py) überträgt die unveränderten PNG-Frames über localhost an ffmpeg. Die MP4 enthält alle chronologischen Frames, ausgewählte Original-PNGs bleiben einzeln erhalten. JSONL erfasst Simulation, Ausrüstung, Posen, Angriffsereignisse, Kamera und konservativ projizierte Figurenbounds. Diese Rechtecke ersetzen keine Sichtprüfung der tatsächlichen Bilder. Quellen-Hashes vor und nach der Aufnahme sowie Framezahl, durchgehende Simulationszeit und vollständige MP4-Dekodierung werden verglichen.

Die Ergebnisanzeige verwendet die ursprünglichen Main-Funktionen. Ihr normaler 2,2-Sekunden-Übergang wird für die feste Aufnahme auf 66 aufgezeichnete Frames bezogen, damit langsamer PNG-Transport die Animation nicht vorzeitig beendet.

Nach dem gewöhnlichen Szenen-Warmup deaktiviert ausschließlich die Aufnahme-Szene die automatischen GPU-Zeichnungen. Zwei SceneTree-Ticks verarbeiten ausstehende Szenenänderungen; `force_sync` und `force_draw` zeichnen anschließend genau einen unveränderten Viewport pro aufgezeichnetem Simulationsschritt. Während der Transport wartet, entstehen dadurch keine zusätzlichen teuren Software-Renderings. Auflösung, Qualitätsmodus, Kamera und Spielressourcen bleiben unverändert; bei Ende oder Fehler wird die Render-Schleife wiederhergestellt.

Die Aufnahme verwendet Dummy-Audio: `captured_audio=false`. Sie belegt weder aufgezeichnete Kampftöne noch Geräte-FPS. Ihre Wiedergabe läuft mit 30 Bildern pro Sekunde; die Capture-Zeiten enthalten Renderer-Readback, PNG-Kompression und Transport.

Die [vollständige Aufnahme samt Originalbildern und Protokollen](design/reference-054/gameplay/README.md) wurde am 6. Oktober 2026 mit Quellstand `c788464` erzeugt. Sie zeigt alle sechs Stationen, Basiszauber, Signatur, Chain und Starfall, die tatsächlichen Wächterphasen und eine erfolgreiche Expedition nach 80,2 Sekunden mit 357 Life. Im abgeschlossenen Wächterkampf bleiben 108 aufeinanderfolgende Kameratransformationen exakt gleich, obwohl Zauber, Warnung und ein Heldentreffer stattfinden. Das belegt die Ruhe dieses Abschnitts; Raumwechsel und Reise verwenden weiterhin die reguläre Kamerabewegung.

```sh
python3 tools/capture_arcanist_quality.py --godot /path/to/godot \
  --display :107 --output /absolute/new/evidence-directory --exclusive-render-slot
```

Ein kleinerer Wert für `--max-simulation-seconds` dient ausschließlich dem Probelauf und wird ausdrücklich als unvollständig bezeichnet.

## Aktueller Prüfstand

| Prüfung | Stand |
| --- | --- |
| Regression | Godot 4.7.2: 40 Suiten, 4.530 Prüfungen, null Fehler; beide Node-Prüfungen bestanden. [Finales Protokoll](design/reference-054/regression.log). |
| Quellen und Export | Frischer serieller Import; finale Skripte im selben Cache exportiert. Ressourcenpaket außerhalb des Checkouts: zwölf Prüfungen, null Fehler. 21 Python-Prüfungen einschließlich Prozessverlust-, Start-, Fehler- und Neustartdiagnostik bestanden. [Paketnachweise](design/reference-054/package-receipt-final.json), [Python-Protokoll](design/reference-054/android-runtime-contracts.log). |
| Figur | [Front](design/reference-054/idle-front.png), [Dreiviertelansicht](design/reference-054/idle-threequarter.png), [Gesicht](design/reference-054/face.png) und [Quellen-Hashes](design/reference-054/studio-provenance.json) zeigen unveränderte native PNGs unter diagnostischem Licht. |
| Kontinuierliche Aufnahme | Vollständig bestanden: 2.496 Frames, 83,2 Sekunden, tatsächlicher Sieg und Beuteanzeige, vollständige MP4-Dekodierung und identische Quellen-Hashes. [Receipt](design/reference-054/gameplay/receipt.json). |
| Android | [Debug-APK/Play-Bundle-Workflow](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37476531577) und [Gameplay-Workflow](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37476531594) bestehen auf `c788464`. [Runtime-Lauf](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37476531574): serieller Import und vier QA-APKs bestehen; nach `cooperative=true` fehlt der AFK-Abschluss, abschließend ist der Launcher sichtbar. Der Exitgrund ist mit dem bisherigen gefilterten Log ungeklärt. Vollständige Prozessdiagnostik ist ergänzt; der instrumentierte Emulatorlauf steht noch aus. |
| Laufzeitmessung | Die vorhandenen lokalen Frame-Metriken können aktive Kämpfe messen. Für diesen Stand sind noch keine Gerätewerte eingetragen. |

Die lokale Arbeitsumgebung besitzt keinen angeschlossenen Android-Runtime oder physischen Testapparat. Der Android-Workflow verwendet einen Android-16-Emulator mit Software-Renderer. Dessen gemessene Intervalle gelten für diesen Emulator; Pixel-Fold-Framerate, Wärme, Akkuverbrauch und Touchqualität erfordern weiterhin einen physischen Gerätelauf.
