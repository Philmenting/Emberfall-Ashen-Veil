# Early-Access-Entwicklung

Ziel: ein veröffentlichbares Android-AFK-Action-RPG im Querformat mit dem räumlichen Spielablauf der Gameplay-Referenz. Grafik soll atmosphärisch und gut lesbar sein; AAA-Detailgrad ist keine Anforderung.

## Stand und Nachweise

Der aktuelle Quellstand 0.38 ergänzt reproduzierbare Zielwechsel zwischen taktisch ähnlichen Gegnern. Die vollständige Regression besteht **17 Godot-Suites mit 1.199 Checks und 0 Fehlern**; Reise, Speicherung und Dungeon/AFK umfassen 557 gezielte Checks. Das release-signierte ARM64-Offline-Closed-Beta-APK 0.38 / Code 42 wurde exportiert und auf Signatur v2/v3, Paket-/Versionsdaten, API 24–36, Querformat und fehlende Internetberechtigung geprüft. Testpaket, Prüfsummen und Details stehen im [0.38-Prüfprotokoll](audit/2026-09-29/seeded-target-choice-0.38.md). Eine Installation auf einem Android-Gerät blieb wegen gesperrter ADB-Sockets offen; ein Play-AAB ist noch nicht erstellt. Ein Offline-Gradle-Aufruf mit `--no-daemon` scheitert beim TCP-Listener des erforderlichen Einmal-Daemons (`Operation not permitted`); frühere Exporte stoppten zusätzlich bei der Wildcard-IP-Ermittlung. Der Online-Test aus 0.33 enthält ein Nakama-Servermodul für ein getrenntes Testprofil mit serverseitiger AFK-Abrechnung, Gold/XP/Beute, Klassenwahl, Attributpunkten, Ausrüstung, Verkauf und Verstärkung. Jeder abgerechnete Lauf verwendet einen frischen kryptografischen Server-Seed; direkte Client-Schreibversuche werden durch `permissionWrite=0` blockiert. Das Profil ist bewusst nicht mit Nyras lokalem Charakter verbunden; der lokale Save bleibt unverändert und sein Fortschritt ist weiterhin clientseitig. Der echte Nakama-/Chat-E2E-Lauf ist hier wegen gesperrter lokaler Sockets nicht ausführbar. Öffentlicher Server, Chatmoderation und gemeinsame Dungeon-Kämpfe fehlen. Nichts wurde veröffentlicht.

| Bereich | Aktueller Stand | Noch zu belegen / entwickeln |
|---|---|---|
| Automatische Expedition | Sechs Gruppen, 26 Gegner, drei Klassen; persönlicher Seed pro Spielstand; Routen, Gegnergruppen, Formation, Kampfschritte, Ziel- und Fähigkeitswahl, Bosswarnungen und Hinterhalte variieren reproduzierbar. 0.37 ergänzt vier Korridorformen; 0.38 ergänzt taktisch begrenzte Zielwechsel. 557 gezielte Reise-/Speicher-/Dungeon-Checks sowie 1.199 Checks in der Vollregression bestehen. | Längere Sessions, Klassen-Builds und höhere Etagen prüfen; Kampfbewegungen auf physischen Geräten ansehen |
| Progression und Beute | Fünf Qualitäten, sechs Slots, Attribute, Verstärkung, Etagenwahl, echte Gegenstandsvergleiche und kostenlose Neuverteilung | Die reproduzierbare 0.29-Mehrseedprobe ist abgeschlossen; alternative Skill-Builds und menschliche Langzeiterfahrung bleiben offen |
| AFK | Gemeinsame Kampflogik, gewählte Etage, Zeitlimit, Overflow-Verkauf; seit 0.30 teilen Weg/Kampf eine exakte 256er-Cache-Bank; Dungeon- und Speichertests bestehen | 24h-Rechnung brauchte auf dem Entwicklungsrechner 5,95 s; physische Android-Startzeit und längere Abwesenheiten prüfen; Balancing der Erträge |
| Spielstände | Generationen 1–6, Migration, pausierte Dungeon-Checkpoints sowie Backup-Code-Export/Import mit Undo; 89 Speicherchecks bestehen. Versionierte Routen halten ältere Checkpoints auf ihrem bisherigen Weg und speichern die neue Reiseposition. 0.28 ergänzt manuelles, besitzergeschütztes Nakama-Backup mit bestätigter Wiederherstellung. 0.29 ergänzt einen widerrufbaren, einmaligen Gastkonto-Transfer; ein echter Nakama-Transfer-E2E-Test ist im Android-CI-Workflow ergänzt, aber noch nicht remote gelaufen | Kontotransfer auf echten Android-Installationen und eine Wiederherstellung nach Neuinstallation nachweisen |
| Bedienung | Klassenwahl beim Einstieg, getrennte Ausrüstungsreiter, echte Wertevergleiche, Farm-Prognosen, Offline-Bericht oben | Optionen, Hilfe und Rücknavigation ergänzt; weitere Bildschirmgrößen und physische Geräte prüfen |
| Darstellung und Ton | Vier eigene Umgebungen, seedgebundene S-Kurven, Boss-Silhouetten und interaktive Zwischenziele; geformte Figuren, gotische Architektur, Nebel und Feuer; 0.30 ergänzt Zielvorlauf, sanfte Boss-Rahmung und Reduced Motion | Synthetisierte Musik/Effekte und Leistungsmodus ergänzt; subjektive Klangprüfung und längere Gerätemessungen offen |
| Online-Umfang | 0.33: Loopback-Gastkonto, Backup/Transfer, Nakama-Gruppen/Chat und separates serverautorisiertes Testprofil mit serverzeitbasierter AFK-Abrechnung, Ausrüstung und Ökonomie. Node-Laufzeittest besteht; echter Nakama-E2E-Lauf in CI ergänzt, hier nicht ausgeführt. Nyras laufende Spielökonomie bleibt lokal. | Serverprofil mit sichtbarem Dungeonkampf/Save zusammenführen, öffentliche Server/Endpunkt, Plattformkontoverknüpfung, Chatmoderation, gemeinsame Dungeon-Kämpfe sowie Datenschutz- und Betriebskonzept. Siehe [Online-Test](ONLINE_TEST.md) |
| Veröffentlichung | ARM64-Closed-Beta-APK 0.38 / Code 42 ist lokal release-signiert; das lokale Testpaket enthält APK, Prüfsumme und [Testanleitung](BETA_TESTING.md). GitHub Actions stellt zusätzlich ein CI-Artefakt mit temporärer Signatur für 14 Tage bereit. Geräteinstallation ist mangels ADB-Socketzugriff offen. Ein Play-AAB wurde noch nicht erstellt; es ist nichts veröffentlicht. | Auf Android installieren und Touchfluss samt Kampfbewegung ansehen; Play-AAB erzeugen und validieren; Gerätewechsel und Gruppenchat auf zwei Installationen prüfen; danach Store-Material, Datenschutz-/Altersangaben, Testergruppe und Play-Freigabe prüfen |

## Freigabeprinzip

Jeder Bereich braucht konkrete Belege am tatsächlichen Release-Kandidaten. Ein APK-Export oder grüne Unit-Tests allein ersetzen weder Spieltests noch die Prüfung der Veröffentlichungsvoraussetzungen. Offene Punkte bleiben offen; eine Early-Access-Freigabe ist damit noch nicht erteilt.

Das Play-Profil zielt auf Android 16 / API 36. Das erfüllt die seit 31. August 2026 geltende API-Vorgabe für neue Apps und Updates im Google Play Store ([aktuelle Play-Richtlinie](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)).

`scripts/verify_android_aab.py` validiert Bundle-Struktur, JAR-Signatur, Paketkennung, Versionscode/-name, SDK-Bereich und das Fehlen der Internetberechtigung. `scripts/export_google_play_beta.py` liest die Version aus dem Play-Exportprofil und schreibt den Dateinamen `emberfall-0.38.0-beta.1-play-beta.aab`. Im CI wird der Release-Export mit einem wegwerfbaren Schlüssel geprüft; dieses CI-Artefakt ist ausdrücklich nicht bei Google Play hochladbar. Der lokale Release-Export verwendet den geschützten Upload-Schlüssel und ist der erforderliche Weg zu einem echten Play-Kandidaten. Für 0.38 liegt noch kein AAB vor; der letzte lokale Exportversuch mit 0.35 stoppte vor der AAB-Erstellung, weil die Laufzeit keine nutzbare Wildcard-IP bestimmen konnte.

## Balance-Probe nach Kampf-Feinschliff 0.34

Der Quellstand 0.34 wurde mit `tests/balance_survey.gd`, sechs festgelegten Profil-Seeds und je 480 Läufen pro Klasse und Seed untersucht (2.880 Läufe pro Klasse). Der Bot kontrolliert alle fünf Läufe, ob die Farmetage in 16 Vorhersagesimulationen mindestens 95 % Siege erzielt. Die mittleren Farmetagen lagen bei Vowkeeper 92,3 (86–96), Arcanist 94,8 (91–96) und Ranger 91,0 (85–96); die nach diesen Läufen freigeschalteten Etagen lagen im Mittel bei 93,3 / 95,8 / 92,0. Die Siege betrugen 2.879/2.880, 2.876/2.880 und 2.876/2.880. Das ist eine einzelne automatische Ausrüstungsheuristik mit Standard-Skillpaaren. Sie belegt keine allgemeine Klassenparität oder Balance für menschliche Builds. Rohdaten: [balance-movement-0.34.csv](audit/2026-09-29/balance-movement-0.34.csv); Methode und Grenzen: [Prüfprotokoll 0.34](audit/2026-09-29/combat-movement-0.34.md).

## Fähigkeiten-Build-Probe 0.31

Der Fortschrittsbot wurde auf dem aktuellen Quellstand mit Profil-Seed 1979 und je 480 Läufen pro Klasse ausgeführt. Standardpaare erreichten Farmetage Vowkeeper 91, Arcanist 90 und Ranger 76; die alternativen Paare lagen bei 81, 91 und 73. Die Siege lagen zwischen 478/480 und 480/480. Das ist eine einzelne reproduzierbare Seedfolge. Sie zeigt den Wert des Vowkeeper-Flächenangriffs, bestätigt aber weder allgemeine Klassenparität noch die Balance auf menschlichen Builds. Die [vollständige Gegenüberstellung](audit/2026-09-29/balance-builds-0.31.md) dokumentiert Methode und Grenzen.

## Balance-Probe 0.29

Die erste Mehrseed-Vorprobe setzte zwar unterschiedliche Seed-Offsets, ließ aber den Profil-Seed uninitialisiert. Deshalb erzeugte ein erneuter Lauf mit Offset 0 eine andere Beutefolge; diese Ergebnisse gelten nicht als reproduzierbarer Beta-Nachweis. Die korrigierte Probe setzt den Profil-Seed explizit auf `1979 + Offset`, protokolliert ihn und wiederholt Offset 0. Alle zwölf Vergleichspunkte des Wiederholungslaufs stimmen exakt mit dem ersten Lauf überein.

Sechs Profil-Seeds (1979, 2043, 2107, 2171, 2235, 2299) wurden jeweils 480 Läufe pro Klasse lang mit demselben automatischen Ausrüstungs-/Attribut-Bot simuliert. Das sind 2.880 Läufe pro Klasse. Die Bot-Farmetagen lagen im Mittel bei Vowkeeper 93,3 (88–96), Arcanist 91,5 (85–95) und Ranger 88,5 (76–96). Die danach freigeschaltete Kampagnenetage lag im Mittel bei 94,3 / 92,5 / 89,5. Die gepaarten Ranger-Ergebnisse lagen im Mittel 4,8 Etagen unter dem Vowkeeper und 3 Etagen unter dem Arcanist, schwankten je nach Seed aber deutlich und waren bei einzelnen Seeds gleichauf oder höher. Siege: Vowkeeper 2.877/2.880, Arcanist 2.878/2.880, Ranger 2.874/2.880. Das ist ein Hinweis, Ranger-Builds weiter zu prüfen, aber keine ausreichende Grundlage für einen pauschalen Klassenwert-Buff: Der Bot nutzt pro Klasse einen festen Skill-Build und eine einfache Ausrüstungsheuristik. Es fehlen alternative Builds und menschliche Langzeiterfahrung. Die kompakten Endwerte stehen in [`balance-v029-results.csv`](audit/2026-09-28/balance-v029-results.csv); vollständige Läufe liegen lokal unter `build/reports/balance-v029-deterministic-{0,64,128,192,256,320}.log`.

## Balance-Probe 0.25

Der automatische Fortschrittsbot absolvierte 480 Läufe je Klasse mit automatischer Ausrüstung, Attributverteilung und Verstärkung. Er gewann 480/480 Vowkeeper-Läufe und wählte Farmetage 91 (20,82 simulierte Stunden), 480/480 Arcanist-Läufe und Farmetage 96 (13,14 Stunden) sowie 480/480 Ranger-Läufe und Farmetage 96 (12,01 Stunden). Die gewählten Builds und Endwerte stehen im Rohprotokoll [`balance-v025-0.log`](../build/reports/balance-v025-0.log).

Das Ergebnis zeigt in diesem Seed-Durchlauf keine auffällige Niederlagenquote und einen Endabstand von fünf Etagen. Es ist eine Bot-Stichprobe mit einem Seed-Offset und festem Skill-Build pro Klasse, kein Beleg für Build-Parität, weitere Seeds oder menschliche Langzeiterfahrung. Deshalb wurden Klassenwerte nicht allein aufgrund dieser Probe verändert.

## Aktuelle Gameplay-Priorität

Der Nutzer hat eine engere Orientierung am weiteren Diablo-Immortal-Spielablauf gewünscht. Konkrete Video-Beobachtungen, der Ausbau in 0.11–0.13 inklusive unterschiedlicher Expeditionstypen und gezielter Belohnungen stehen in [GAMEPLAY_DIRECTION.md](GAMEPLAY_DIRECTION.md). Backup-Codes, manuelle Cloud-Sicherung und ein einmaliger Gastkonto-Transfer sind inzwischen vorhanden. Das ersetzt keine Anmeldung über Plattformkonten, serverseitige Spielökonomie oder gemeinsame Spielwelt.

## Stand nach 0.13

[Beutejagden und Aschenprüfungen](HUNTS_AND_TRIALS.md) erweitern die Dungeon-Auswahl. Backup-/Wiederherstellungsbedienung ist ergänzt; ein unabhängiger physischer Gerätetransfer, längere Spieltests, Online-Umfang und Veröffentlichungsvoraussetzungen bleiben offen.

## Grafischer Ausbau 0.14

Die [Grafiküberarbeitung](VISUAL_UPGRADE.md) verbessert Figuren, Materialien, Architektur, Beleuchtung und Kampfeffekte. Die bisherigen Kampf- und Belohnungsregeln bleiben erhalten.

## Lokaler Online-Test 0.29

Das optionale Gastkonto, der Geräte-Transfer-Schlüssel und das manuelle Cloud-Backup sind im [Entwicklerleitfaden](ONLINE_TEST.md) beschrieben. Der Transfer-Import ist noch nicht praktisch geprüft; die vorherige Cloud-Backup-Strecke bleibt in [audit.md](audit/2026-09-28/audit.md) dokumentiert.

## Bewegungsüberarbeitung 0.15

Die Figuren folgen jetzt dem tatsächlichen Lauftempo. Angriffe haben sichtbares Ausholen und Nachschwingen, Treffer lösen Flinches aus und besiegte Gegner stürzen mit kleinen Variationen. Die Darstellungsanimationen bleiben von Kampfsimulation, Beute und AFK-Berechnung getrennt.

## Seedgebundene Dungeonvariation 0.16

Ein Lauf-Seed verändert Wegpunkte, Gegnerzusammenstellungen, Spawnformationen und die Auswahl zwischen gleichzeitig sinnvollen Angriffstechniken. Die Figur bleibt auf verbundenen Wegen und sucht Gegner taktisch; sie läuft nicht ziellos ohne Ziel herum. Derselbe Seed reproduziert denselben Kampf in Live, Skip und Offline-Berechnung. Live/Skip, 64 Startvarianten je Klasse, reproduzierbare Aufstellungen und Technik-Auswahl wurden gezielt geprüft. Eine breitere Balance-Prüfung über mehr Ausrüstung und höhere Etagen bleibt offen.

Die 0.16-Debug-APK (VersionCode 20) startete auf dem Android-Emulator mit 1280 × 720. Der Testbuild nutzte eine eigene Paketkennung, damit er neben einer vorhandenen Installation und deren Spielstand bestehen konnte. Screenshot und 12-Sekunden-Mitschnitt liegen unter `build/previews/emberfall-016-start.png`, `emberfall-016-run.png` und `build/previews/emberfall-016-gameplay.mp4`.

## Klassenbalance 0.17

Der Vowkeeper erhält auf seine abgeleiteten Werte 20% mehr Leben und Rüstung. Die Änderung stärkt die Frontlinie, ohne Angriffs- oder Fähigkeits-Schaden zu erhöhen. Derselbe 480-Läufe-Fortschrittsbot wie in 0.16 wählte nun Farmetage 84 und gewann 479 Läufe; Arcanist blieb bei Etage 86 und 479 Siegen, Ranger bei Etage 86 und 480 Siegen. Die simulierten Gesamtzeiten betrugen 19,05 / 13,30 / 12,04 Stunden. Die Bot-Wahl schätzt alle fünf Läufe mit 16 Mustern die Farmetage; eine Beutefolge, ein automatischer Build und diese Stichprobe ersetzen keine Balanceprüfung mit weiteren Seeds, Ausrüstungen oder menschlichen Spieltests.

Die Klassen-, Gegenstands- und Farmprognose-Prüfung bestand 38 Tests, die Dungeonreise mit sichtbarer Ausrüstungsbeute 174, Verträge 68, Bossmuster 85, Fähigkeitsrotation 135, Darstellung 45 und Speicherung/AFK 69: zusammen 614 Prüfungen. Die 0.18-Debug-APK wurde mit VersionCode 22 signiert verifiziert und parallel zur vorhandenen App auf dem 1280 × 720 Android-Emulator installiert und gestartet. Die manuelle Touchprüfung führte durch drei Dungeonabschlüsse, Verkauf und Ausrüstung realer Gegenstände; eine kurze 854 × 480-Querformatmessung blieb scroll- und bedienbar, zeigte aber sichtbar kleinere Schrift. Aufnahmen: Klassenwahl und Kampf `build/previews/emberfall-018-start.png` / `emberfall-018-run.png`, Belohnungsansicht und Verkauf/Ausrüstung `build/previews/emberfall-018-loot.png`, `emberfall-018-sold.png`, `build/previews/emberfall-018-floor3-result.png` und `build/previews/emberfall-018-equipped.png`. Ein live beobachteter Android-Lauf erreichte den Boss und die Beuteansicht. Eine weitere Expedition wurde nach echtem Prozessabbruch bis zum Reliquiar offline fortgesetzt und nach erneutem Kaltstart nicht doppelt ausgezahlt. Screenshots und Aufnahme stehen in `build/previews/emberfall-018-*.png` und `emberfall-018-live-floor4.mp4`. Der ältere 0.17-Hauptbuild setzte zuvor ebenfalls denselben Dungeon nach Prozessabbruch fort.

## Prozedurale Kampfrouten 0.20

Neue Expeditionen wählen eine von 256 wiederholbaren Layoutvarianten. Pro Raum stehen fünf Gegnergruppen zur Auswahl; die Gesamtzahl bleibt bei 26 Gegnern. Spawnpunkte und Routenstil werden neu gemischt. Räuber verfolgen eigene Flankenbahnen, Hexer halten einen individuell gesetzten Wirkungsabstand und variieren Vorwarnradius sowie Zauberzeit. Eliten kündigen einen ausweichbaren Flächenangriff an und wiederholen ihn mit seedgebundenem Abstand. Die automatische Zielfindung und Fähigkeitsrotation bleiben aktiv.

Die acht direkt betroffenen Suites (Dungeon/AFK, Reise, Prognose, Fähigkeitsrotation, Speicherung, Gebiete, Bossmuster und Verträge) bestehen zusammen 658 Checks; alle 14 Godot-Suiten bestehen 873 Checks. Die neue Debug-APK startete im Emulator; `build/previews/22-0-20-combat-first-route.png` zeigt den sichtbaren Auto-Kampf. Der signierte Release-AAB VersionCode 24 besteht die Bundletool-Validierung. Das ist keine Prüfung auf mehreren physischen Geräten oder eine breite neue Build-Balanceprobe.
