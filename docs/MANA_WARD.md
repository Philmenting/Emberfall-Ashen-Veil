# Mana-Barriere und Balance — 0.8

## Spielregel

Der Arcanist verwendet überschüssiges Mana automatisch als Schutz: bis zu 35 Prozent des nach Rüstung verbleibenden Schadens werden absorbiert. Jeder absorbierte Lebenspunkt kostet zwei Mana. Genug Mana für einen Einsatz von Veil Nova bleibt reserviert. Ist die Reserve erreicht, treffen Angriffe wieder mit vollem Schaden. Die Barriere erzeugt kein Mana und verändert weder Rüstung noch Schaden der anderen Klassen.

Ein kurzer violetter Schild, eine WARD-Zahl und ein eigener synthetisierter Klang zeigen eine tatsächliche Absorption. Das Kampf-HUD zeigt das über der Fähigkeitsreserve verfügbare Mana. Spirit stärkt den Manavorrat und die Erholung bei Treffern; Nova gibt weiterhin 25 Prozent ihrer Kosten zurück. Die Hilfe erklärt das Zusammenspiel.

Bereits gespeicherte Expeditionen behalten ihre ursprünglichen Kampfwerte und Regeln. Erst die nächste Arcanist-Expedition erhält die Barriere. Dadurch verändert ein Update keinen begonnenen Kampf rückwirkend. Neue Speicherstände erhalten den zusätzlichen Wert einschließlich Validierung; Zuschauen, Überspringen und AFK verwenden dieselbe Simulation.

## Prüfungen

295 erfolgreiche lokale Prüfungen: Dungeon 50, Speicherung 69, Gebiete 36, Ausrüstung/Prognose 35, Einstieg 19, Optionen/Ton 59 und Mana-Barriere 27. Die neue Suite prüft unter anderem Teilabsorption, ungerade und leere Manavorräte, Fähigkeitsreserve, Rüstung, Klassenzuordnung, alte Checkpoints, identische Fortsetzung und sichtbare Rückmeldung.

```bash
XDG_DATA_HOME=/tmp/emberfall-ward-check godot --headless --path . --fixed-fps 60 --script tests/mana_ward_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-frontier-check godot --headless --path . --script tests/balance_frontier.gd
XDG_DATA_HOME=/tmp/emberfall-survey-check godot --headless --path . --script tests/balance_survey.gd
```

`tests/android_ward.tscn` ist ein separater Android-Teststart mit eigener Paketkennung. Er spielt einen neuen Arcanisten mit unveränderter Startausrüstung automatisch durch Etage 1, protokolliert echte Absorptionen und speichert beim ersten Schild eine Aufnahme. Er gehört nicht in normale Exporte.

Im Android-Emulator mit API 36 und 1280 × 720 lief dieser Test erfolgreich: fünf Barrieren absorbierten zusammen 17 Schaden für 34 Mana. Sieben Novas wurden ausgeführt; der Boss fiel nach 57,9 Sekunden Simulationszeit bei 343 verbleibendem Leben und 238 Mana. Die Aufnahme zeigt den aktiven Schild und die Mana-Anzeige. Protokoll und Bild liegen lokal unter `build/reports/android-08-ward.log` und `build/previews/android-08-ward.png`. Das ist ein Emulatornachweis, kein Test auf einem physischen Telefon.

## Balance-Befund und Grenzen

Der reproduzierbare Vergleich verwendet festgehaltene Werte aus Version 0.7 (`tests/fixtures/balance_frontier_07.json`) und alle 64 Kampfmuster an der jeweiligen Fortschrittsgrenze. Beim Arcanisten auf Etage 52 steigt die Zahl der Siege von 8 auf 46; mittleres Restmana sinkt von rund 936 auf 109. Vowkeeper und Ranger bleiben unverändert. Das zeigt einen defensiven Nutzen und tatsächlichen Manaverbrauch, keine garantierte Siegesrate.

Eine zweite Untersuchung spielt 480 Läufe je Klasse mit Ausrüsten, Verkauf, Attributverteilung und Verstärkung bis +3. Alle fünf Läufe wählt der Bot anhand von 16 Kampfmustern eine vermeintlich sichere Etage. Seine einfache Gegenstandsbewertung optimiert die Mana-Barriere nicht gezielt. Mit Barriere erreicht der Arcanist weiterhin erst Etage 52, während die anderen Klassen Etage 88 erreichen. Der Langzeitabstand ist also **nicht behoben**. Die Ergebnisse sind automatisierte Szenarien, kein menschlicher Spieltest und kein Nachweis fairer Endgame-Balance. Klassenbeute, längere Spielerfahrungen und wirtschaftliche Anreize bleiben weitere Arbeit.
