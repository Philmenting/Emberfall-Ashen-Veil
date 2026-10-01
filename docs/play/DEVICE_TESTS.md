# Geräte-Abnahme für die geschlossene Beta

Noch kein physischer Gerätebericht vorhanden. Emulator-, Desktop- und ELF-
Prüfungen ersetzen diesen Bericht nicht. Getestete APK/AAB-SHA256, Gerät,
Android-Version, Datum, Tester und konkrete Ergebnisse im Bericht dokumentieren.

Mindestens ein älteres ARM64-Gerät mit OpenGL ES 3 und ein aktuelles Gerät mit
Displayaussparung prüfen; wenn verfügbar zusätzlich ein Gerät mit 16-KB-Seiten.
Androids kleinste unterstützte Version ist 7 / API 24. Beide Grafikmodi
**Balanced / Battery** nutzen; 60 bzw. 30 FPS sind Zielwerte, keine Messwerte.

| Test | Erwartetes Verhalten |
|---|---|
| Frische Installation im Flugmodus | Keine Anmeldung, kein Online-Tab; alle drei Klassen auswählbar; erste Expedition startet |
| Echter Wächterkampf | Leben, Mana, Bossleben, Gefahrenform und Countdown lesbar; automatische Ausweichmanöver sichtbar |
| Beute und Folgeaktionen | Tatsächliche Statistik; sichere Upgrades behalten alte Items; Kampagne folgt Freischaltung; Hunt behält Slot; nächster Trial nutzt dessen richtige Etage |
| Camp / Gear / World / Options | Text und Aktionen erreichbar; Scrollen, Android Back und Displayaussparungen funktionieren; Large Text bleibt gespeichert |
| Hintergrund / Sperren / Force-stop | Aktive Expedition wird passend fortgesetzt; Pause bleibt Pause; keine verlorenen oder doppelten Belohnungen |
| Längere AFK-Rückkehr | Fortschrittsanzeige reagiert; spätestens 24 Stunden werden berechnet; Abbruch und Neustart setzt ausstehenden Rest fort |
| Speicher / Wiederherstellung | Save Backup erzeugen, veränderten Stand wiederherstellen, Undo Last Restore; vor Neuinstallation gültigen Code sichern |
| 20 Minuten Kampagne / Hunts | Frame-Time, Spitzen, RAM, Temperatur, Akku und Abstürze protokollieren; beide Grafikmodi testen |
| Update mit gleichem Schlüssel | 0.38-Spielstand laden; Ausrüstung, Skills, Stance und pausierter Run bleiben erhalten |
| Play-Installation | Final upload-signiertes Bundle über Testtrack installieren; Pre-Launch-Bericht und dessen konkrete Fehler prüfen |

Freigabe nur bei abgeschlossenen Ergebnissen ohne ungelöste Abstürze,
Fortschrittsverlust, doppelte Auszahlung oder blockierte Kernaktionen. Eine
ungelöste Performance-Lücke erhält einen konkreten Fix und erneuten Test auf dem
betroffenen Gerät. Den Bericht erst danach als `device_test_report` eintragen.
