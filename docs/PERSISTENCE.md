# Speicherung und App-Lebenszyklus – 0.4.1

## Dateiformat

`user://emberfall.save.0` und `.1` enthalten abwechselnd die neueste und vorherige Generation. Die Hülle enthält Formatversion, Revisionsnummer, ConfigFile-Nutzlast und SHA-256 über Revision plus Nutzlast. Neue Daten werden in die temporäre Datei des älteren Slots geschrieben, geschlossen, erneut gelesen und geprüft; erst danach ersetzt ein Rename den Slot. Die zweite gültige Generation bleibt unangetastet.

Die Prüfsumme erkennt Beschädigungen und unvollständige Inhalte. Sie ist kein Schutz gegen absichtliche Manipulation. Ohne gültige Generation werden bestehende Dateien nicht überschrieben. Ein Format aus einer neueren App-Version sperrt ebenfalls das Schreiben. Speicherfehler und Wiederherstellung werden in der Oberfläche angezeigt.

Eine vorhandene einzelne `emberfall.save` aus 0.1–0.4 wird einmalig gelesen, in das neue Format gespeichert und unverändert behalten. Die neuen Slots haben anschließend Vorrang.

## Kampf-Checkpoint

Der Checkpoint speichert alle Zustandsfelder der festen Kampfsimulation und den Zustand des Zufallsgenerators. Godots binäre Variant-Kodierung mit Base64 erhält Fließkommazahlen unverändert innerhalb der ConfigFile-Nutzlast; ein gewöhnlicher Text-Export der Vektoren würde Rundung zulassen. Beim Lesen werden Schema, Klassen, Raum-/Gegnerstruktur, numerische Werte und Positionen geprüft. Das Dekodieren erlaubt keine Objekte.

Ein normaler Lauf speichert alle fünf Simulationssekunden, bei Pause, beim Umschalten der Wiederholung und beim Hintergrundwechsel. Das Ergebnis eines Laufs und seine Belohnungen werden gemeinsam gespeichert; ein abgeschlossener Lauf ist anschließend kein wiederherstellbarer Kampf mehr.

## AFK-Regeln

- Offline-Farmen aus: ein gespeicherter Kampf bleibt an seinem Checkpoint.
- Offline-Farmen an, Kampf manuell pausiert: keine Fortsetzung und keine zweite parallel farmende Figur.
- Offline-Farmen an, laufender Kampf: zuerst genau diesen Kampf fortsetzen; Restzeit erst danach für die ausgewählte Farm-Etage nutzen.
- Maximal 24 Stunden werden angerechnet. Zeitreste für weitere vollständige Farm-Läufe bleiben erhalten.
- Wiederholtes Resume ohne vorherigen Hintergrundwechsel ist wirkungslos. Ein zurückgestellter Zeitstempel senkt den bereits verrechneten Zeitstand nicht.
- Gold/XP aus AFK-Ergebnissen bleiben bis zur Abholung ausstehend. Ausrüstung wird in die Tasche gelegt, Überlauf automatisch verkauft.

## Nachweise

Am 27.09.2026 lokal mit Godot 4.7.2:

- `tests/dungeon_smoke.gd`: **50 Prüfungen, 0 Fehler** – drei Klassen, sichtbare Bewegung, Kampf-/Skip-/AFK-Parität, Niederlage, Wiederholung, kurze/lange Unterbrechung, Zeitrest, Inventarlimit. Eine Berechnung von 24 Stunden dauerte auf dem Entwicklungsrechner etwa 0,33 Sekunden.
- `tests/persistence_smoke.gd`: **68 Prüfungen, 0 Fehler** – binär identische Checkpoints und Ergebnisse, ungültige Zustände, beschädigte Generationen, unterbrochene Schreibvorgänge, Migration, unbekannte Formate, Prozessneustart, Pause, AFK-Abholung und zurückgestellte Uhr. Zwei absichtlich beschädigte Testdateien erzeugen erwartete ConfigFile-Parserdiagnosen.

- Android-Emulator API 36, 1280×720, x86_64: echter Hintergrundwechsel und Prozessabbruch bei laufender Expedition. Neustart stellte exakt den erwarteten Kampfzustand bei 27,9 Sekunden wieder her. Nach Abschluss betrug das Gold 790; ein weiterer Prozessneustart vergab keine zweite Belohnung. Beide Laufzeitprüfungen meldeten PASS.

Für jede erneute Prüfung ein separates, frisches `XDG_DATA_HOME` verwenden. Diese automatisierten Prüfungen ersetzen keine Tests auf echten schwächeren Android-Geräten und keine längeren Spielsessions.

## Android-Test-Einstieg

`tests/android_lifecycle.tscn` darf nur unter einer separaten Paketkennung gebaut werden (lokal: `com.philmenting.emberfallashenveil.lifecycle`). Er startet einen Lauf, speichert nach zwölf Sekunden und schreibt `ANDROID_LIFECYCLE_READY`. Anschließend:

1. Home-Taste auslösen, App-Prozess beenden, nach kurzer Wartezeit erneut starten.
2. Der Test vergleicht die wiederhergestellte Simulation mit gespeichertem Zustand plus tatsächlich verstrichener Zeit und meldet PASS/FAIL. Nach drei Sekunden beendet er den Lauf per Skip und schreibt `ANDROID_LIFECYCLE_SETTLED`.
3. Erneut Prozess beenden und starten. Der Test prüft, dass der abgeschlossene Lauf nicht erneut bezahlt wurde.

Screenshots: `user://lifecycle-checkpoint.png`, `lifecycle-restored.png`, `lifecycle-loot.png`, `lifecycle-settled.png`. Die Testdateien sind in den normalen Exportprofilen ausgeschlossen; der Einstieg des Spiels bleibt `Main.tscn`.
