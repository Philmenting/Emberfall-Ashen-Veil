# Kampfbewegungen und Räume · 0.46.0-beta.1

Ausgangspunkt ist die Rückmeldung, das Spiel wirke trotz funktionierender
Spielmechanik noch konzeptmäßig. Während des Ausbaus präzisierte der Nutzer:
„Mir geht's halt auch um die Animationen beim Angriffen und so.“ Die Richtung
bleibt eine originale düstere Fantasywelt mit Diablo Immortal als Referenz.
Version-Code **52**.

## Angriffsbewegungen

Grundangriff und Fähigkeit besitzen getrennte Bewegungsphrasen für Lastaufnahme,
Beschleunigung, Kontakt, Nachlauf und Rückkehr. Beim Schwert bleiben Schild und
Stützfüße kontrolliert, beim Stab führen Becken und Zauberhand die Bewegung,
beim Bogen bleiben Bogenarm und Nockbindung während des Auszugs zusammen.
Normale Gegner nutzen ihre tatsächliche verbleibende Abklingzeit zum Ausholen.
Schwere Gegner besitzen eigene Bewegungen; die Citadel-Axt hat einen zweiten Griff.

Die Übergänge berücksichtigen die wirkliche Dauer eines Angriffs. Der bereits
bestehende Geschossstart 85 ms vor dem Schaden wird jetzt auch für die Pose
verwendet. In einer reproduzierten 300-ms-Zaubervorbereitung bei 60 Prüfschritten
pro Sekunde fällt der Sprung der Arcanist-Waffenspitze am Release von **1,19147
Weltmetern auf 0,00000**. Die Kamera oder der Schadenszeitpunkt werden dadurch
nicht verändert. Fünf neue Regressionen sichern diesen Übergang und die
Gegnervorbereitung; elf weitere prüfen die tatsächlichen liegenden Körpervarianten.

Treffer drücken Schulter, Brust und Becken kurz unterschiedlich zusammen.
Fest zugesagte Angriffe behalten Vorrang; die Füße bleiben unterstützt. Die
vorhandenen neun nativen Clips und 0,34 Sekunden Rückbewegung bleiben erhalten.
Es handelt sich um neu gezeichnete räumliche Posen und Übergänge im bestehenden
Skelett, nicht um Motion-Capture-Aufnahmen.

Die vertiefte Überarbeitung verbindet belastetes Knie, vorlaufendes Becken und
verzögert aufdrehende Brust. Beim normalen 300-ms-Grundangriff steigt die gemessene
Beckenauslenkung gegenüber der vorherigen 0.46-Fassung von 11,1 auf 30,2 cm
(Schwert), 7,1 auf 24,4 cm (Stab) und 5,4 auf 14,5 cm (Bogen). Diese Messungen
belegen den Bewegungsumfang; die visuelle Bewertung nutzt die normalen Kämpfe.
Ein eigener QA-Clip blendet Effekte und Zahlen zur Prüfung der Körperbewegung aus.

Die Kamera passt Bildmitte und Abstand gemeinsam an die vollständige Raum- und
Warngeometrie an und hält diese Komposition während des Kampfes. In den festen
Vergleichsfällen erscheinen normale Kämpfer 23 % größer im breiten und 42 %
größer im kompakten Querformat. Gefallene normale Gegner verschwinden nach
ihrer vollständigen Fallbewegung nach 2,15 Sekunden; Belohnungen bleiben gleich.
Schadenszahlen sind kleiner und kürzer sichtbar.

## Begehbare Welt und Figuren

Der Boden besteht aus einer durchgehenden beleuchteten Fläche mit originaler
unregelmäßiger Steintextur und großflächigen Abnutzungsspuren. Gebrochene Mauersteine,
tragende Glockenpfeiler, versenkte Archivwände, Grabnischen und Ofenschächte
geben den vier Regionen unterschiedliche Bauformen.
Hollow Spire nutzt Glocken und Grabnischen, Drowned Archive Bücherregale und
echte ausgesparte Wasserkanäle mit gemauerten Ufern, Glass Ossuary Gräber und Reliquien, Cinder Citadel Öfen und Eisen.
Die Architektur berücksichtigt die tatsächlichen Laufwege samt Abstand;
Warnflächen werden weiterhin aus der Kampfsimulation gezeichnet.

Alle elf Figuren haben angepasste Schulterpanzer, Kragen, dickere Stoffbahnen,
Falten und Säume, greifende Hände sowie passende Waffengriffe. Die Modelle
umfassen 20.380 bis 39.184 Dreiecke und behalten 29 Knochen und neun native Clips.
Nyras Gesicht, Augen, Lippen und Haare behalten dieselbe Geometrie wie in 0.45.
Diese Fassung ergänzt keine separate Mimik oder Sprachanimation.

Das Lager erhält tragende Seiten- und Rückwände sowie verbundene Stationen.
Die Kampfanzeige bündelt Fähigkeiten und Befehle in einer mittigen Leiste;
Status und Kammerziel erhalten weniger Fläche. Die schmale Lesesicht ordnet
Fähigkeit und Route untereinander an und behält Schließen/Zurück/Resume.

## Nachweise und Grenzen

Die nativen Ansichten umfassen 2424×1080, 1040×1080 und 854×480 mit Large Text.
Wächter-Stills nutzen erhöhte Life-Werte als Geometrie-Fixture. Die Kampfclips
verwenden normale Startausrüstung; Schnitte überspringen Wege, verändern aber
nicht die Spielgeschwindigkeit der aufgenommenen Angriffe. Die separate
Motion-Galerie zeigt die tatsächlichen Runtime-Modelle mit Prüfabläufen.

Die Bilder und Clips sind Renderer-Nachweise. Sie messen keine Bildrate,
Temperatur oder Akkulaufzeit auf einem physischen Smartphone. Die Referenz
bestimmt die gestalterische Richtung, belegt aber keine Gleichwertigkeit mit
der Produktion von Diablo Immortal. Google Play wird durch diesen Ausbau
nicht veröffentlicht.

Die abschließende lokale Regression besteht aus **32 Godot-Suiten mit
3.580 Prüfungen ohne Fehler** sowie den serverseitigen Fortschrittsregeln. Darunter prüfen
153 Fälle die räumlichen Figuren, 50 die Bewegungsabläufe und 900 die
Kamerabildgrenzen. Die Play-Quelldatenprüfung und fünf Tests der Android-
Paketprüfung bestehen ebenfalls; dies ist keine Play-Veröffentlichung.

- [Angriffe aller drei Klassen, normale Ausrüstung, 24 s](previews/scene-finish/emberfall-attacks-046.mp4)
- [Angriffe ohne Effekte zur Bewegungsprüfung, 12 s](previews/scene-finish/emberfall-attacks-bare-046.mp4)
- [Native Bewegungsansicht aller elf Figuren, 24 s](previews/scene-finish/emberfall-motion-046.mp4)
- [Kampf, echte Lesepause und Raumwechsel, 15 s](previews/scene-finish/emberfall-graphics-046.mp4)
- [31 native Ansichten, Herkunft und Quell-Hashes](previews/scene-finish/provenance.json)
- [Gemessene Angriffsphrasen](previews/scene-finish/attack-effort.json)
- [Vergleich der Kamerakomposition](previews/scene-finish/framing-gain.json)
- [Vollständiges lokales Prüfprotokoll](previews/scene-finish/regression.log)
- [Unabhängige Gesamtprüfung](design/graphics-review-046-final.md)

Die erneute unabhängige Gesamtprüfung lautet **`rebuild`**. Sie bestätigt valide
Nachweise, räumliche Figuren, eine stabile Kamera und lesbare Warnflächen,
bewertet die visuelle Produktionsqualität aber weiterhin als unzureichend.
Offen bleiben insbesondere die Lesbarkeit von Stab-/Bogenbewegung im normalen
Kamerabild, die Ausarbeitung der Körper und Materialien, zusammenhängende
Raumtiefe sowie die Darstellung des deaktivierten Loot-Befehls beim Lesen.
Der vollständige Bericht stammt aus einem unabhängigen Ersatz-Review anhand
nativer Einzelbilder und Zeitfolgen; er zertifiziert kein kontinuierliches
Videoplayback. Der vorherige Neuaufbau-Bericht bleibt separat erhalten.

Dies ist ein nachvollziehbarer **Teststand ohne visuelle Beta-Freigabe**.

## Android-Teststand

Alle drei CI-Läufe sind auf dem unveränderten Spielquellstand
[`883d65e`](https://github.com/Philmenting/Emberfall-Ashen-Veil/commit/883d65eeb304f18aeb999f8ace53d9f359cbf46f)
erfolgreich abgeschlossen. Die anschließende Ergänzung dieser Nachweise ändert
weder den Spielcode noch die aufgenommenen Animationen.

- [Gameplay Quality](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37189036398):
  32 Godot-Suiten, 3.580 Prüfungen ohne Fehler, dazu die Server-Regression.
- [Android-Paketierung](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37189076124):
  Test-APK, Closed-Beta-Test-APK und AAB; Version 0.46 / Code 52, ARM64,
  Ziel-API 36 und 16-KB-kompatible native ELF-Segmente bestätigt.
- [Android-16-Emulator](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37189077582):
  erster Kampf, echte Lesepause mit Fortsetzen über Back, einmaliges Klassenrelikt,
  Ausrüstungsschutz, Taschenfilter, kombinierte Eide und Kaltstart bestehen.
  Alle vier Regionen rendern in Balanced und Battery. Jede Bewegungsfolge
  enthält vier unterschiedliche native Bilder. Die Pose des geprüften
  Wächterknochens (Index 3) ändert sich in 12 bis 17 von 20 Schritten;
  das Modell besitzt 29 Knochen und neun Clips. `graphics_only` war aktiviert;
  die separate Android-AFK-Abrechnung wurde in diesem Lauf nicht wiederholt.

[Prüfbericht, Artefakt- und Bildprüfsummen](audit/2026-10-04/android-046/ci-summary.json),
[originale Messwerte](audit/2026-10-04/android-046/render-performance.json),
[erster Kampf](audit/2026-10-04/android-046/android-success-first-fight.png) und
[Lesepause](audit/2026-10-04/android-046/android-success-skill-reading.png)
sind archiviert. Alle 28 Emulatorbilder wurden dekodiert und über Kontaktbögen
geprüft; Kampf und Lesesicht wurden zusätzlich einzeln geöffnet. Der bekannte
deaktivierte Loot-Zustand bleibt sichtbar fehlerhaft.

Der Pixel-6-Emulator verwendet **Software-Rendering**. Seine Medianzeiten liegen
bei 1.651–1.879 ms pro Bild in Balanced und 592–635 ms in Battery. Der Test
bestätigt Rendering und fortschreitende Animationen, nicht das Erreichen der
60/30-FPS-Ziele. Leistung und Bedienung auf einem echten Telefon bleiben offen.
Diese technische Prüfung ersetzt die gestalterische Abnahme nicht.

Das [Download-Artefakt](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37189076124/artifacts/11298032981)
enthält `emberfall-closed-beta-ci.apk`. Es ist nur ein CI-Testpaket mit einem
für diesen Lauf erzeugten Schlüssel; es ist kein Play-Release und kein
verlässliches Update über früher anders signierte Installationen.

## Grundlage für weitere Angriffsarbeit

Die [Prüfung freier Animationsquellen](design/animation-source-study-046.md)
findet verwendbare Schwertbewegungen, aber keinen Bogensatz und keinen
überzeugenden Ganzkörper-Zauberangriff in den untersuchten Standard-Paketen.
Dateiimporte und Quellkurven wurden überprüft. Eine Übertragung auf Emberfalls
Skelett und eine sichtbare Qualitätsverbesserung sind damit noch nicht belegt;
keines dieser Pakete wurde in diesen Teststand integriert.
