# Speicherung und App-Lebenszyklus – 0.4.1

## Dateiformat

`user://emberfall.save.0` und `.1` enthalten abwechselnd die neueste und vorherige Generation. Die Hülle enthält Formatversion, Revisionsnummer, ConfigFile-Nutzlast und SHA-256 über Revision plus Nutzlast. Neue Daten werden in die temporäre Datei des älteren Slots geschrieben, geschlossen, erneut gelesen und geprüft; erst danach ersetzt ein Rename den Slot. Die zweite gültige Generation bleibt unangetastet.

Die Prüfsumme erkennt Beschädigungen und unvollständige Inhalte. Sie ist kein Schutz gegen absichtliche Manipulation. Ohne gültige Generation werden bestehende Dateien nicht überschrieben. Ein Format aus einer neueren App-Version sperrt ebenfalls das Schreiben. Speicherfehler und Wiederherstellung werden in der Oberfläche angezeigt.

Eine vorhandene einzelne `emberfall.save` aus 0.1–0.4 wird einmalig gelesen, in das neue Format gespeichert und unverändert behalten. Die neuen Slots haben anschließend Vorrang.

## Externer Backup-Code 0.22

Unter **Options → Save Backup** wird der aktuelle Spielstand zuerst gespeichert und dann als `EMBERFALL-SAVE-1`-Code exportiert. Er enthält Heldenwerte, Ausrüstung, Inventar, Einstellungen, AFK-Zeitreste und – falls vorhanden – den pausierten Dungeon-Checkpoint. Ein kopierbarer Textcode lässt sich zwischen Geräten übertragen.

Beim Import prüft das Spiel Prüfsumme, Klassen-, Gegenstands- und AFK-Daten sowie den wiederherstellbaren Expeditions-Checkpoint, bevor es den aktiven Spielstand ersetzt. Der bisherige lokale Stand bleibt als `.pre_restore` erhalten. **Undo Last Restore** kann ihn auch aus einem pausierten Dungeon wiederherstellen. Nach dem Rückwechsel wird der ersetzte Stand wiederum als Recovery-Kopie gehalten.

Der Code ist Base64-kodiert, aber nicht verschlüsselt. SHA-256 erkennt versehentliche Beschädigung; es verhindert keine absichtliche Änderung. Den Code deshalb privat aufbewahren und in einer eigenen Datei oder einem vertrauenswürdigen Speicher sichern. Das ist kein Cloud-Sync und kein Schutz gegen absichtliche Manipulation.

## Lokales Cloud-Backup und Gerätewechsel 0.29

Die beiden Android-Testprofile enthalten einen zusätzlichen **Online Test**-Reiter. Das Spiel erzeugt für Nakama eine zufällige 128-Bit-Gast-ID und speichert sie in `user://emberfall_online.cfg`; es liest keine Hardware-ID und speichert kein Sitzungstoken dauerhaft. **Create Account Transfer Key** verknüpft eine weitere zufällige Geräte-ID mit demselben Nakama-Konto und speichert sie lokal zur erneuten Anzeige oder zum Widerruf. Auf einer frischen Installation kann dieser Schlüssel importiert werden. Der Client meldet sich damit am bestehenden Konto an, verknüpft zuerst eine neue lokale Geräte-ID, speichert diese atomar und entwertet anschließend den einmaligen Importschlüssel. Schlägt das Entwerten fehl, bleibt der verwendete Schlüssel lokal sichtbar, damit er manuell widerrufen werden kann. Die ursprüngliche Geräte-ID des alten Geräts bleibt verknüpft; das ist eine Anmeldung auf einer weiteren Installation, kein erzwungener Ein-Geräte-Umzug. Der Import steht nur zur Verfügung, solange auf der neuen Installation noch keine Gast-ID erzeugt wurde. Nach einer Neuinstallation ohne zuvor kopierten Transfer-Schlüssel geht der Gastzugang weiterhin verloren.

**Check Cloud** meldet eine vorhandene ID bei Bedarf erneut an und lädt den privaten Backup-Datensatz. **Create/Update Cloud Backup** sichert den aktuellen lokalen Backup-Code nach ausdrücklichem Tastendruck; ein vorhandener Datensatz muss vor dem Überschreiben bestätigt werden. Nakamas Versionsprüfung weist gleichzeitige Schreibkonflikte ab. Der Kontotransfer synchronisiert den Spielstand nicht automatisch; Cloud-Restore bleibt ein separater, bestätigungspflichtiger Vorgang.

**Restore Cloud Backup** ist auf das Lager beschränkt und benötigt eine zusätzliche Bestätigung. Der geladene Code durchläuft dieselbe Integritäts- und Save-Schema-Prüfung wie ein manueller Code; vor dem Austausch wird der lokale Stand als Recovery-Kopie erhalten. Die Funktion ist im Play-Profil deaktiviert und in diesem Test nur für einen Loopback-Nakama-Server gedacht. Da der Client den Code schreibt, sind Heldenwerte, Gold, XP, Ausrüstung und Beute nicht serverautorisiert. Der Transfer-Schlüssel ist ein Bearer-Schlüssel und weder ein echtes MMO-Konto noch eine Plattformkontoverknüpfung. Der manuelle Backup-Code bleibt zusätzlich verfügbar.

## Persönlicher Zufalls-Startwert 0.24

Jeder Spielstand speichert `hero.world_seed`. Neue Expeditionen kombinieren diesen Wert mit der fortlaufenden Expeditionsnummer und verwenden daraus einen Run-Seed für Route, Gegnerverhalten, Fähigkeitswahl und Beute. Der Checkpoint speichert weiterhin den tatsächlichen Simulationszustand samt RNG-Zustand, sodass Pause und Prozessneustart den Kampf nicht neu würfeln. Alte lokale Speicherstände und ältere Backup-Codes ohne `world_seed` bleiben lesbar; beim Laden wird ein Startwert ergänzt und beim nächsten Speichern mitgesichert.

## Kampf-Checkpoint

Der Checkpoint speichert alle Zustandsfelder der festen Kampfsimulation und den Zustand des Zufallsgenerators. Godots binäre Variant-Kodierung mit Base64 erhält Fließkommazahlen unverändert innerhalb der ConfigFile-Nutzlast; ein gewöhnlicher Text-Export der Vektoren würde Rundung zulassen. Beim Lesen werden Schema, Klassen, Raum-/Gegnerstruktur, numerische Werte und Positionen geprüft. Das Dekodieren erlaubt keine Objekte.

Ein normaler Lauf speichert alle fünf Simulationssekunden, bei Pause, beim Umschalten der Wiederholung und beim Hintergrundwechsel. Das Ergebnis eines Laufs und seine Belohnungen werden gemeinsam gespeichert; ein abgeschlossener Lauf ist anschließend kein wiederherstellbarer Kampf mehr.

## AFK-Regeln

- Offline-Farmen aus: ein gespeicherter Kampf bleibt an seinem Checkpoint.
- Offline-Farmen an, Kampf manuell pausiert: keine Fortsetzung und keine zweite parallel farmende Figur.
- Offline-Farmen an, laufender Kampf: zuerst genau diesen Kampf fortsetzen; Restzeit erst danach für die ausgewählte Farm-Etage nutzen.
- Maximal 24 Stunden werden angerechnet. Zeitreste für weitere vollständige Farm-Läufe bleiben erhalten.
- Seit Version 0.30 teilen neue Weg- und Kampfmuster dieselbe 256er-Bank. Version 0.31 fügt einen seedgebundenen S-förmigen Weg mit höchstens 1,5 Metern zusätzlicher Strecke pro Gang hinzu. Das Muster bleibt in der AFK-Cache-Bank; Routenmodus 1 und ältere Checkpoints behalten ihre bisherigen Wegpunkte.
- Wiederholtes Resume ohne vorherigen Hintergrundwechsel ist wirkungslos. Ein zurückgestellter Zeitstempel senkt den bereits verrechneten Zeitstand nicht.
- Gold/XP aus AFK-Ergebnissen bleiben bis zur Abholung ausstehend. Ausrüstung wird in die Tasche gelegt, Überlauf automatisch verkauft.

## Nachweise

Am 29.09.2026 lokal mit Godot 4.7.2:

- `tests/dungeon_smoke.gd`: **50 Prüfungen, 0 Fehler** – drei Klassen, sichtbare Bewegung, Kampf-/Skip-/AFK-Parität, Niederlage, Wiederholung, kurze/lange Unterbrechung, Zeitrest, Inventarlimit und ein exakter Vergleich des AFK-Muster-Caches. Eine 24-Stunden-Berechnung dauerte auf dem aktuellen Entwicklungsrechner etwa 5,95 Sekunden; die Laufzeit auf Android ist noch nicht gemessen.
- `tests/persistence_smoke.gd`: **88 Prüfungen, 0 Fehler** – zusätzlich persönlicher Seed, neue/stabile Profile, Routenmodi 1/2, alte voll-seedgebundene Checkpoints, Seedmigration und Abwärtskompatibilität älterer Backup-Codes. Zwei absichtlich beschädigte Testdateien erzeugen erwartete ConfigFile-Parserdiagnosen.
- `tests/options_smoke.gd`: **73 Prüfungen, 0 Fehler** – Backup-Oberfläche, ungültiger Import, Speichern/Wiederherstellen der Optionen, Reduced Motion, Pausieren und Fortsetzen.
- Android-Emulator API 36, 1280×720, x86_64, VersionCode 32: Gastkonto angemeldet, Cloud-Backup gespeichert, lokalen Helden auf eine andere Klasse geändert und Cloud-Backup nach Bestätigung wiederhergestellt. Nach Force-Stop meldete sich dieselbe installierungsgebundene ID wieder an und fand den Datensatz. Nakama und PostgreSQL wurden zusätzlich mit `tools/run_local_nakama.sh` gestartet und kontrolliert beendet; der Cloud-Datensatz blieb über den Serverneustart erhalten. Screenshots: [`26`](audit/2026-09-28/26-local-guest-cloud-backup.png), [`27`](audit/2026-09-28/27-cloud-restore-confirmation.png), [`28`](audit/2026-09-28/28-cloud-restore-result.png).
- `tests/journey_smoke.gd`: **332 Prüfungen, 0 Fehler** – 256 Layoutmuster, variierte begehbare S-Kurven, Gruppenvielfalt, sichere Bewegung und gleiche Ergebnisse bei Live-/Skip-Fortsetzung. Alle 256 Startmuster wurden je Klasse mit Startausrüstung auf Sieg und Live/Skip-Gleichheit geprüft.
- `tests/contracts_smoke.gd`: **68 Prüfungen, 0 Fehler** – darunter gezielte AFK-Jagden, die gegen Einzelkämpfe mit demselben Spieler-Seed abgeglichen wurden.
- Android-Emulator API 36, 1280×720: x86_64-Emulatorpaket 0.24 installiert und gestartet. Ein sichtbarer Lauf wurde nach Force-Stop offline fortgesetzt und schloss Etage 1 ab; `hero.world_seed` war in der Android-Speicherung vorhanden. Screenshots liegen unter `docs/audit/2026-09-28/18-personal-seed-start.png`, `19-personal-seed-dungeon.png` und `20-personal-seed-resume.png`.
- Die ARM64- und x86_64-Test-APKs 0.28 bestehen `apksigner verify`. Der signierte Play-AAB VersionCode 32 aus dem vorherigen 0.28-Export besteht `bundletool validate` und bleibt ohne Internetberechtigung. Nach der letzten kleinen Quelltextänderung blockiert die aktuelle Sandbox den Gradle-Neuexport beim Öffnen einer lokalen Netzwerkschnittstelle; der AAB muss vor Play mit dem aktuellen Quellstand neu gebaut werden. Play-Upload und Veröffentlichung erfolgten nicht.
- Für Version 0.29 wurden die ARM64- und x86_64-Test-APKs aus dem aktuellen Quellstand exportiert; beide bestehen `apksigner verify`. Die Manifeste enthalten VersionCode 33, die jeweiligen Test-Paketkennungen und `android.permission.INTERNET`. Eine Installation war nicht möglich: der ADB-Server kann in der Sandbox keinen lokalen Socket binden (`Operation not permitted`). Auch ein direkter Gradle-Lauf mit `--offline --no-daemon` kann seinen Daemon-Socket nicht erstellen; Godots AAB-Export scheitert deshalb mit `Could not determine a usable wildcard IP for this machine`. Der vorherige VersionCode-32-AAB ist kein 0.29-Releasekandidat.
- Version 0.31: ARM64- und x86_64-Test-APKs, VersionCode 35, wurden exportiert und bestehen `apksigner verify`; Manifeste bestätigen Landscape, API 24–36, die Test-Paketkennungen und Internetberechtigung. Installation und Touchprüfung sind nicht möglich, weil ADB den lokalen Smartsocket nicht starten darf (`Operation not permitted`). Der Play-AAB-Export scheitert weiterhin beim lokalen Gradle-Schritt `Could not determine a usable wildcard IP for this machine`.
- `tests/cloud_identity_smoke.gd`: **14 Prüfungen, 0 Fehler** für ID-Formatierung, sichere Zufalls-ID, lokale Identitätsspeicherung, Recovery nach einem Abbruch zwischen den Datei-Renames, Rotation, das Entfernen des verbrauchten Transfer-Schlüssels und den Erhalt gültiger Daten bei ungültiger Eingabe. Dies prüft nicht die Nakama-Anmeldung oder den Wechsel zwischen zwei Installationen.

- Android-Emulator API 36, 1280×720, x86_64: echter Hintergrundwechsel und Prozessabbruch bei laufender Expedition. Neustart stellte exakt den erwarteten Kampfzustand bei 27,9 Sekunden wieder her. Nach Abschluss betrug das Gold 790; ein weiterer Prozessneustart vergab keine zweite Belohnung. Beide Laufzeitprüfungen meldeten PASS.
- 0.17-Hauptbuild auf demselben Emulator: erste Expedition gestartet, App über Home in den Hintergrund geschickt, Prozess mit `am force-stop` beendet und kalt neu gestartet. Der Dungeon war nach dem Neustart weiterhin im Bossraum aktiv. Der sichtbare Checkpoint zeigte 555 von 569 Leben und 1.335 von 2.400 Bossleben. Aufnahme: `build/previews/emberfall-017-resume.png`.
- 0.18-Testbuild `com.philmenting.emberfallashenveil.test018`, API 36, 1280×720: Etage 5 nach zwölf Sekunden in Kammer 2 gespeichert, dann Home, `am force-stop` und Kaltstart. Die nächste Aufnahme zeigte die Figur in Kammer 6 am geöffneten Reliquiar; fünf Sekunden später war die Etage mit einer legendären Waffe als Beute abgeschlossen. Ein zweiter Prozessabbruch/Kaltstart führte ins Lager mit Etage 6 freigeschaltet und demselben Goldstand von rund 1,7k; es gab keine zweite Auszahlung. Bilder: `build/previews/emberfall-018-lifecycle-before.png`, `lifecycle-after.png`, `lifecycle-complete.png` und `no-duplicate.png`.
- Derselbe 0.18-Emulatorbuild schloss Etage 4 in einem live beobachteten Lauf ab; eine 90-Sekunden-Aufnahme endet in der echten Beuteansicht: `build/previews/emberfall-018-live-floor4.mp4` und `build/previews/emberfall-018-floor4-current.png`.

Für jede erneute Prüfung ein separates, frisches `XDG_DATA_HOME` verwenden. Diese automatisierten Prüfungen ersetzen keine Tests auf echten schwächeren Android-Geräten und keine längeren Spielsessions.

## Android-Test-Einstieg

`tests/android_lifecycle.tscn` darf nur unter einer separaten Paketkennung gebaut werden (lokal: `com.philmenting.emberfallashenveil.lifecycle`). Er startet einen Lauf, speichert nach zwölf Sekunden und schreibt `ANDROID_LIFECYCLE_READY`. Anschließend:

1. Home-Taste auslösen, App-Prozess beenden, nach kurzer Wartezeit erneut starten.
2. Der Test vergleicht die wiederhergestellte Simulation mit gespeichertem Zustand plus tatsächlich verstrichener Zeit und meldet PASS/FAIL. Nach drei Sekunden beendet er den Lauf per Skip und schreibt `ANDROID_LIFECYCLE_SETTLED`.
3. Erneut Prozess beenden und starten. Der Test prüft, dass der abgeschlossene Lauf nicht erneut bezahlt wurde.

Screenshots: `user://lifecycle-checkpoint.png`, `lifecycle-restored.png`, `lifecycle-loot.png`, `lifecycle-settled.png`. Die Testdateien sind in den normalen Exportprofilen ausgeschlossen; der Einstieg des Spiels bleibt `Main.tscn`.
