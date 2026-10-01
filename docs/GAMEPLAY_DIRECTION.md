# Gameplay-Richtung nach erneuter Referenzsichtung

Stand: 29. September 2026, Umsetzungsschritte 0.11 bis 0.13, Seed-Variation 0.16, Klassenbalance 0.17, sichtbare Ausrüstungsbeute 0.18, prozedurale Kampfrouten 0.20, variierende Bossangriffe 0.21, seedgebundene Kampfbewegung 0.34, ortsvariable Hinterhalte 0.35, variable Erkundungswege 0.36, erweiterte Wegformen 0.37 und taktisch variierte Zielwahl 0.38 (17 Godot-Suites / 1.199 Checks und Closed-Beta-APK geprüft; Play-AAB und Gerätetest offen).

## Taktisch variierte Zielwahl (0.38)

Wenn mehrere Gegner ähnlich wichtig sind, wählt Nyra bei einem bereiten Angriff seedgebunden zwischen ihnen. Klassenprioritäten bleiben wirksam: Der Ranger bevorzugt weiterhin gegnerische Zauberer. Während einer Abklingzeit oder auf dem Weg in Reichweite hält die Figur ihr gewähltes Ziel. Derselbe Seed ergibt dieselbe Zielreihenfolge bei Live, Skip, Wiederaufnahme und AFK; pausierte Expeditionen ohne die neue Regel behalten ihr gespeichertes Verhalten.

Die Dungeon-Suite prüft Seedvariation für alle drei Klassen, identische Wiederholung derselben Zielwahl und Fokusbindung während der Abklingzeit. Die vollständige Regression sowie das signierte ARM64-Closed-Beta-APK werden im [0.38-Prüfprotokoll](audit/2026-09-29/seeded-target-choice-0.38.md) dokumentiert.

## Erweiterte Wegformen (0.37)

Neue Expeditionen nutzen Route-Version 4 und wählen jeden Verbindungsgang aus vier seedgebundenen Formen: mehrspurige Kurve, Seitengang mit Rückkehr, breiter Seitenschwung oder mehrfache Zickzackkurven. Derselbe Seed steuert Laufbewegung, Bodengeometrie und Minikarte; Gegnergruppen, Formation, Hinterhalte und automatische Fähigkeiten behalten ihre vorhandene Zufallslogik. Anzahl der Gegner und Belohnungen bleiben gleich. Routenversionen 1–3 laufen für bereits gespeicherte Expeditionen weiter mit ihrer vorherigen Form. Die Reise-, Speicher- und Dungeon-Suiten bestehen mit **552 Checks**; die vollständige 17-Suite-Regression besteht mit **1.194 Checks**, jeweils ohne Fehler. Das Closed-Beta-APK 0.37 ist release-signiert und geprüft; Android-Installation und Play-AAB sind noch offen.

## Variable Erkundungswege (0.36)

Neue Expeditionen wählen für jeden Korridor einen von zwei seedgebundenen Verläufen: eine Kurve mit wechselnden Seitenlagen oder einen kurzen Seitengang, den Nyra vor der nächsten Kammer wieder verlässt. Die Wegpunkte sind Teil der Simulation. Bodenflächen, Minikarte, Beobachtung, Skip, Checkpoint-Fortsetzung und AFK-Fortschritt lesen dieselbe Route. Damit läuft die Figur pro Expedition anders, ohne zufällig aus der Dungeonkarte herauszulaufen oder bei einer Berechnung andere Ergebnisse zu erhalten.

Gegnergruppen, Spawnformationen, Flankenbewegungen, Hinterhalte und automatische Fähigkeitsentscheidungen bleiben ebenfalls seedgebunden. Die neue Routenfassung gilt nur für neue Expeditionen; gespeicherte Läufe behalten ihre bisherige Generation und Wegform. Die 256er-Musterbank bleibt für identische Beobachtungs- und AFK-Läufe cachebar.

## Ortsvariable Hinterhalte (0.35)

Zwei Gegner pro Expedition treten zeitversetzt aus seedgebunden ausgewählten Randpunkten ihrer Kammer in den Kampf ein. Die Positionen liegen im begehbaren Raum und halten Abstand zur aktiven Gruppe; der Feuerring macht den Auftritt sichtbar. Anzahl der Gegner, Beute und Schwierigkeitsetats bleiben gleich. Derselbe Seed reproduziert Eintrittsort und Zeitpunkt in Live-Kampf, Skip, gespeicherten Checkpoints und AFK-Abrechnung.

Die Reise- und Speicherprüfungen bestehen für diese Änderung **435 Checks** ohne Fehler. Die Reise-Suite belegt mindestens 250 unterschiedliche Eintrittspunkte, begehbare Platzierung und Abstand zur Gruppe. Das vollständige 0.35-Regressionsset besteht 17 Suiten mit **1.127 Checks**, ohne Fehler. Das signierte ARM64-Offline-APK 0.35 / Code 39 wurde auf Signatur, Versionsdaten, API 24–36, Querformat und fehlende Internetberechtigung geprüft. Emulator-/Geräteinstallation und Play-AAB bleiben offen.

## Seedgebundene Kampfbewegung (0.34)

Während ihrer automatischen Abklingzeiten bewegt Nyra sich nun in kurzen, wechselnden Schritten um das aktuelle Ziel. Die Vowkeeperin bleibt im Nahbereich und sucht seitliche Angriffspositionen; Arcanist und Ranger variieren ihre Stellung auf Distanz. Der Seed bestimmt Seite, Bogen und Schrittweite. Vorwarnungen und Kammergrenzen sperren gefährliche Ziele. Ein bereiter Angriff hat Vorrang und unterbricht den Positionswechsel; Bewegung setzt in der nächsten Angriffspause fort. So wirkt der Kampf weniger wie ein stationärer Schlagabtausch, ohne das taktische Zielsystem durch zielloses Herumlaufen zu ersetzen.

Diese Entscheidung gehört zum gespeicherten Expeditionszustand. Derselbe Seed erzeugt weiterhin denselben beobachteten, übersprungenen, gespeicherten und offline berechneten Kampf. Die Bewegung gilt ab Dungeon-Generation 5; ältere pausierte Läufe bleiben bei Generation 4 oder ihrer älteren gespeicherten Version. 343 Journey-Checks und die separate 8-Check-Bewegungssuite bestehen, darunter gleiche Seeds, sichere Laufziele, Klassenreichweiten, sofortige Angriffe, wiederaufgenommene Checkpoints sowie Generation-4-Kompatibilität. Die Arcanist-Taktik besteht 29, Speicherung 88 und Dungeon 50 Checks. Insgesamt bestehen alle 17 Godot-Suites mit 1.123 Checks; Node-Syntax und Serverlaufzeitprüfung bestehen ebenfalls. Das ARM64-Offline-Closed-Beta-APK für Version 0.34 wurde neu gebaut; Signatur, Versionsdaten, API-Bereich, Querformat und fehlende Internetberechtigung sind geprüft. Eine Installation auf Emulator oder Gerät war wegen gesperrter ADB-Sockets nicht möglich. Der Play-AAB-Export kam in Gradle wegen einer nicht ermittelbaren Wildcard-IP nicht bis zur Paketerstellung. Die aktualisierte Klassenprobe über sechs Seeds liegt im [Prüfprotokoll](audit/2026-09-29/combat-movement-0.34.md).

## Betrachtete Ausschnitte

Die Videos wurden im Browser an den folgenden Stellen tatsächlich betrachtet, nicht vollständig am Stück angesehen:

- [Vom Nutzer genannte Vorlage, Teil 1](https://www.youtube.com/watch?v=aRDi0lavO7I): etwa 50:27 (Dialog im räumlichen Umfeld), 1:10:38 (Gegnergruppe, Raumziel, Gold und Ausrüstung im Kampf), 1:11:07 (Skelettkönig, Bodenangriffe und Heilkugeln).
- [Direkte Fortsetzung desselben Walkthroughs, Teil 2](https://www.youtube.com/watch?v=ItLA5IQROE4): etwa 34:51 (Werkstatt und Figuren im Hub), 1:00:59 (Lager/Questkontakt), 1:18:25 (Herausforderungsportal mit Stufe und Belohnungen), 1:19:07 (Gruppenkampf im Portal, Fortschrittsziel und Abklingzeiten).
- [Vom Nutzer genannter Kurzclip](https://www.youtube.com/watch?v=ofXta93JX7o): als 25-Sekunden-Mobile-Gameplay zu **Nonstop Knight 2** geführt. Flaregames beschreibt die Schleife mit automatisch laufendem Ritter, Gegnerwellen, Fähigkeiten, Ausrüstung und Bossen auf der [Google-Play-Seite](https://play.google.com/store/apps/details?id=com.flaregames.nonstop.action.rpg). Diese Verbindung aus zügigem Auto-Lauf, deutlichen Kampfgruppen und klaren Bossmomenten ergänzt die räumlichen Diablo-Immortal-Beobachtungen.
- [Blizzards Gameplay-Überblick](https://news.blizzard.com/en-us/article/23557147/diablo-immortal-gameplay-overview-everything-you-need-to-know) beschreibt Gebiete, Dungeons, wiederholbare Portale, Ausrüstung und Solo-/Gruppenspiel. Der Artikel stammt aus der Alpha; seine damaligen Laufzeiten sind keine aktuelle Balance-Vorgabe.

Die folgende Übertragung ist unsere Designentscheidung. Eigene Orte, Modelle, Namen und Systeme bleiben Bestandteil von Emberfall.

## Konsequenzen für Emberfall

| Beobachtung | Übertragung auf Auto/AFK | Stand |
|---|---|---|
| Zusammenhängende Räume und Erkundung zwischen Kämpfen | Figur folgt sichtbaren Verbindungen und Kurven; aktuelle Position und Ziel auf der Karte | Vier handgebaute Grundrisse bilden die Basis. Seit 0.20 ziehen 256 wiederholbare Seedmuster Raumverbindungen aus vier Pfadstilen und verschieben Wegpunkte innerhalb sicherer Grenzen. |
| Gruppen mit Nahkämpfern, Fernkämpfern und Eliten | Gegnerrollen beeinflussen automatische Zielwahl, Bewegung und Flächenfähigkeiten | Fünf Aufstellungen je Raum, Formation und Spawnposition variieren pro Lauf. Räuber flankieren, Hexer halten einen seedgebundenen Wirkungsabstand, Eliten kündigen Flächenangriffe an. Der Auto-Kampf wählt zwischen zugleich passenden Techniken. |
| Abwechslung zwischen Kämpfen und kleinen Aufgaben | Brunnen nutzen, bewachtes Siegel brechen, Bosszugang öffnen, Reliquiar bergen | 0.11: automatisch in derselben Live-/Skip-/AFK-Simulation |
| Sichtbare Heilung und Beute im Geschehen | Einmalige Brunnenheilung; geöffnete finale Truhe zeigt echte, qualitätsgefärbte 3D-Ausrüstungsdrops mit Namen | 0.11 / 0.18: die sichtbaren Gegenstände sind dieselben Datensätze wie die Abschlussbeute; keine Doppelbelohnung |
| Mehrere Fähigkeiten mit unterschiedlichen Rollen | Konfigurierbare automatische Rotation aus Angriff, Flächenschaden, Bewegung und Schutz | 0.12: Klassenfähigkeit plus zwei wählbare Techniken, eigene Mana-Kosten, Bedingungen und Abklingzeiten |
| Hub, Aufgaben, Gebiete und Portale erfüllen verschiedene Zwecke | Gebietsexpeditionen, gezieltes Farmen und eine separate Herausforderung mit ersten Abschlussbelohnungen | 0.13: Kampagne, gezielte Beutejagden und 30 zeitbegrenzte Aschenprüfungen mit Erstbelohnungen |
| Andere Spieler bewegen und kämpfen gemeinsam | Online-Spiel braucht echte gemeinsame Zustände, Gruppen und Server | Offen; aktuelle Version bleibt ehrlich als lokal/solo beschrieben |

Der Nonstop-Knight-Ansatz lässt die Figur laufen, während Fähigkeiten in der Vorlage noch aktiv ausgelöst werden. Emberfall automatisiert auch deren Einsatz, damit die vom Nutzer gewünschte AFK-Schleife ohne Kampfsteuerung funktioniert. Die räumliche Lesbarkeit, Gegnerwellen, Beute und Bossmomente bleiben dabei erhalten.

## Regeln der aktuellen Umsetzung

- Sechs Kammern pro Gebiet, unterschiedliche seitliche Verbindungen. Der Grundriss wird von Simulation, Bodenaufbau und Karte gemeinsam gelesen.
- Gruppen: 5 / 4 / 5 / 4 / 5 / 3 Gegner. Normale Gegner besitzen 72% ihrer bisherigen Einzel-Lebenspunkte. Elite und Boss behalten ihre Lebenspunkte; Angriffsschaden und Klassensystem bleiben bestehen.
- Nach Kammer 2: Brunnen heilt einmal bis zu 18% des maximalen Lebens, ohne Überheilung. Nach Kammer 4: bewachtes Siegel öffnet das Tor zum Heiligtum. Nach dem Boss: Figur läuft zum Reliquiar und öffnet es.
- Keine zusätzliche Gratisbeute: Das Reliquiar zeigt bis zu zwei der tatsächlich vergebenen Abschlussgegenstände als schwebende 3D-Modelle mit Qualität, Slot und Name. Es führt zur bestehenden, genau einmal vergebenen Beuteauswertung. Brunnen, Siegel und Truhe kosten tatsächliche Laufzeit, auch beim Skip und offline.
- Laufwege, Kampf, Interaktionen und Zielzustände werden gespeichert. Angefangene Expeditionen aus 0.10 und früher behalten ihre alte Route, Gegneranzahl und Ergebnisse. Neue Expeditionen erhalten `dungeon_journey=1`.
- Ein Lauf-Seed steuert Route, Gegnerzusammenstellung, Spawnpositionen, individuelle Gegnerbewegung, Angriffswarnungen und Auswahl zwischen gleichzeitig passenden Angriffstechniken. Neue Läufe nutzen 256 Muster; alte gespeicherte Läufe behalten ihre bisherige Zuordnung. Derselbe Seed stellt denselben Lauf wieder her; Live, Skip und AFK stimmen dadurch überein. Die Figur wandert nicht ziellos, sondern folgt den generierten Wegen und reagiert auf Gegner und Gefahren.
- Wenn mehrere Gegner taktisch ähnlich wichtig sind, variiert die Figur ihre Zielwahl pro bereitem Angriff seedgebunden. Während der Abklingzeit hält sie ihr Ziel, damit sie nicht hektisch umschaltet. Diese Zufallsentscheidung bleibt beim Zuschauen, Skippen, Wiederaufnehmen und Offline-Farmen identisch.
- Neue Expeditionen haben ein Sicherheitslimit von vier Minuten. Das alte Drei-Minuten-Limit benachteiligte den Nahkämpfer durch die zusätzlichen Wege; alte laufende Expeditionen behalten auch ihr altes Limit.
- Neue Geometrie und Gegenstände bestehen aus eigenen Godot-Meshes. Statische Bauteile werden gebündelt. Die kleine Karte ist eine Godot-Zeichnung.

## Nachweise und Grenzen

544 lokale Prüfungen: die bisherigen 438 plus 106 für Wege, Zwischenziele, alte Checkpoints und Darstellung. Enthalten sind alle 64 Startvarianten je Klasse, Vergleiche von Live/Skip, Wiederaufnahme während Wegstrecken und Interaktionen sowie zwölf mit unverändertem 0.10-Code erzeugte Vergleichsstände.

Android-Testlauf mit unveränderter Arcanist-Startausrüstung auf Etage 1: sichtbare Gruppen, Abbiegung, Brunnen, Siegel, Boss, Truhe und normale Beuteauswertung. Bilder und Protokoll liegen lokal in `build/previews/android-011-*.png` und `build/reports/android-011-journey.log`.

Diese Version hat noch keine freie offene Welt, zufällige Raumgenerierung, Mehrspielerfunktion. Die Referenzsichtung und dieser Ausbau ersetzen keine physischen Gerätetests und keinen menschlichen Langzeittest. Die bisherigen Balance-Messungen aus 0.10 gelten nicht unverändert für die längeren Wege und zusätzlichen Gegner.

### Fortschrittsprobe

Die ältere Probe mit Version 0.13 ermittelte 480 Simulationen je Klasse und meldete 91 / 97 / 97 als höchste gewählte Etagen. Die 0.16-Probe absolvierte ebenfalls 480 Farmkämpfe je Klasse, mit Beutefolge 0, automatischer Ausrüstung, Attributverteilung und Verstärkung. Sie endete bei Farmetage 58 für Vowkeeper (476 Siege), 86 für Arcanist (479 Siege) und 86 für Ranger (480 Siege), in 17,21 / 13,30 / 12,04 simulierten Stunden. Die damalige Farmwahl schätzte mit 16 Mustern eine Erfolgsquote von mindestens 95%; tatsächliche Seeds konnten trotzdem zu Niederlagen führen. Der große Klassenabstand führte zur Zähigkeitsanpassung 0.17 unten. Eine Beutefolge und ein einfacher Ausrüstungsbot ersetzen keine breitere Balanceprüfung.

Lokales Rohprotokoll: `build/reports/balance-011-0-final.log`. Der 105-Sekunden-Android-Mitschnitt liegt unter `build/previews/emberfall-011-gameplay.mp4` (1280×720, ohne Audiospur). Er zeigt den vollständigen ersten Arcanist-Lauf mit 26 besiegten Gegnern, 76,8 Sekunden Simulationszeit und der tatsächlich vergebenen seltenen Klassenbeute. Die abschließende Änderung am Zeitlimit betrifft höhere/längere Läufe; der aufgezeichnete Erstlauf bleibt unverändert.

## Ausbau 0.12: Fähigkeiten konfigurieren

[SKILL_ROTATION.md](SKILL_ROTATION.md) beschreibt neun eigene Techniken, die Auswahl zweier Plätze je Klasse, automatische Prioritäten und die Nachweise. 0.13 ergänzt unterschiedliche Expeditionstypen und gezielte Belohnungen; Regeln und Nachweise stehen in [HUNTS_AND_TRIALS.md](HUNTS_AND_TRIALS.md).

## Seed-Variation 0.16

Vier handgebaute Gebietspläne dienen als lesbare Basis. Jeder Lauf verschiebt mehrere Wegpunkte innerhalb geprüfter Grenzen, wählt Gegnergruppen aus passenden Rollen und mischt deren Spawnpositionen. Im Kampf priorisiert die Figur weiter gefährliche Gegner und weicht angekündigten Angriffen aus; sind mehrere ausgerüstete Angriffstechniken zugleich passend und bereit, entscheidet der gleiche Seed zwischen ihnen. Der Zufall verändert dadurch den Ablauf, ohne das Laufen ziellos zu machen.

Die Simulation hält die Entscheidung reproduzierbar: derselbe Seed liefert beim Zuschauen, Überspringen, Wiederaufnehmen und Offline-Rechnen denselben Weg und dieselbe Beutegrundlage. 64 Anfangsvarianten je Klasse wurden auf Sieg und Live/Skip-Gleichheit geprüft. Diese Stichprobe deckt nicht jede Ausrüstung und höhere Etagen ab.

Die vier geänderten Godot-Suiten (Reise, Fähigkeitsrotation, Darstellung und Speicherung) bestanden 421 Prüfungen. Die Debug-APK 0.16.0-seeded-runs wurde exportiert, signiert verifiziert und auf einem Android-Emulator mit 1280 × 720 gestartet. Der Lauf zeigt Nyra, die generierte Route und die laufende Gegnergruppe; Bild und 12-Sekunden-Mitschnitt liegen in `build/previews/emberfall-016-run.png` und `build/previews/emberfall-016-gameplay.mp4`.

## Klassenbalance 0.17

Der Vowkeeper erhält auf seine abgeleiteten Werte 20% mehr Leben und Rüstung. Die Änderung stärkt die Frontlinie, ohne Angriffs- oder Fähigkeitenschaden zu erhöhen. Derselbe 480-Läufe-Fortschrittsbot wie in 0.16 wählte nun Farmetage 84 und gewann 479 Läufe; Arcanist blieb bei Etage 86 und 479 Siegen, Ranger bei Etage 86 und 480 Siegen. Die simulierten Gesamtzeiten betrugen 19,05 / 13,30 / 12,04 Stunden. Die Bot-Wahl prüft alle fünf Läufe 16 Muster zur Farmetagen-Schätzung; eine Beutefolge, ein automatischer Build und diese Stichprobe ersetzen keine Balanceprüfung mit weiteren Seeds, Ausrüstungen oder menschlichen Spieltests.

Die Klassen-, Gegenstands- und Farmprognose-Prüfung bestand 38 Tests, die Dungeonreise 172, Verträge 68, Bossmuster 85, Fähigkeitsrotation 135 und Speicherung/AFK 69: zusammen 567 Prüfungen. Die Debug-APK 0.17 wurde mit VersionCode 21 exportiert, ihre Signatur verifiziert und parallel zur vorhandenen App auf dem 1280 × 720 Android-Emulator gestartet. Nach echtem Prozessabbruch setzte die Hauptszene den laufenden Dungeon im Bossraum fort.

## Sichtbare Ausrüstungsbeute 0.18

Beim live beobachteten Sieg erscheinen am geöffneten Reliquiar bis zu zwei echte Belohnungsgegenstände als leuchtende, schwebende 3D-Modelle. Farbe, Name und Slot stammen aus genau denselben Gegenstandsdaten wie die anschließende Beuteansicht; die Präsentation fügt keine Gegenstände hinzu. Skip geht weiterhin direkt zur Beuteansicht. Die Figuren bleiben seedgebunden auf dem sichtbaren Dungeonweg; pro Seed variieren Route, Gegneraufstellung, Spawnformation und situationsgerechte Angriffstechnik. Das ist gezielte, reproduzierbare Zufälligkeit, kein ungerichtetes Herumlaufen. Live, Skip, Wiederaufnahme und Offline-Rechnung behalten denselben Seed-Ablauf.

Die aktuelle Fassung bestand 614 Prüfungen über Klassen-/Prognose-, Reise-, Vertrag-, Boss-, Fähigkeits-, Darstellungs- und Speicher-Suiten. Die 0.18-Debug-APK (VersionCode 22) wurde signiert, neben der bisherigen Installation auf dem 1280 × 720 Android-Emulator installiert und gestartet. Die Aufnahme `build/previews/emberfall-018-run.png` zeigt den automatischen ersten Kampf, die aktive Klassenfähigkeit und fünf lebende Gegner; `build/previews/emberfall-018-start.png` zeigt die Klassenwahl. Der finale 3D-Beutemoment wurde im Headless-Szenentest auf echte Gegenstandsidentität und Beschriftung geprüft. Ein 90-Sekunden-Android-Mitschnitt dokumentiert zusätzlich einen live beobachteten Lauf bis zur echten Beuteansicht; die Touchprüfung von Verkauf und Ausrüstung sowie ein Prozessabbruch mit AFK-Fortsetzung sind separat dokumentiert.

## Mehr Dungeonvarianz 0.20

Jeder neue Seed wählt aus 256 reproduzierbaren Mustern. Vier Pfadstile verändern die Raumverbindungen und Wegpunkte, fünf Aufstellungen je Raum mischen die Rollen bei gleichbleibenden 26 Gegnern. Die Spawnpunkte rotieren ebenfalls. Im Kampf verfolgen Räuber unterschiedliche Flankenbahnen, Hexer wählen individuellen Abstand und Zaubervorwarnung, Eliten starten angekündigte Angriffe mit Flächenwirkung. Die Figur folgt dem generierten Pfad, priorisiert Gegner nach Klasse und aktiviert passende Fähigkeiten automatisch. Es gibt keinen ziellosen Zufallslauf: Skip, Zuschauen und AFK verwenden denselben Seed. Gespeicherte Expeditionen ohne Generatorversionsfeld laden weiter mit den bisherigen Regeln.

Die 14 Godot-Suiten bestehen 873 Checks, davon 658 Checks in den acht direkt betroffenen Reise-, Kampf-, Prognose- und Speichersuiten. Die neue Android-Debug-APK wurde installiert und auf dem 1280 × 720-Emulator gestartet. `build/previews/22-0-20-combat-first-route.png` zeigt den sichtbaren Lauf. Der signierte AAB VersionCode 24 wurde mit Bundletool validiert. Gerätevielfalt und breite Build-Balance bleiben offene Prüfungen.

## Bossangriffe mit Varianten 0.21

Jeder Gebiets-Boss hat zwei Formen seines Flächenangriffs. Der Seed wählt die erste Form; danach wechselt der Boss bei jedem Spezialangriff zur anderen. Die Gefahren bleiben dem Gebietsstil zugeordnet: Glockenring oder Gefahrenkreis, gerichtete Flutbahn oder Querströmung, seitliche oder längs versetzte Grabkreise, gerades oder zur Figur gedrehtes Feuerkreuz. Die Warnung zeigt die Form vor dem Treffer; Nyra sucht weiterhin automatisch einen sicheren Punkt. Ältere gespeicherte Warnungen ohne Variantenfeld laufen unverändert aus.

Die 480-Läufe-Farmprobe je Klasse erreichte Farmetage 88 (Vowkeeper, 480 Siege), 94 (Arcanist, 479 Siege) und 89 (Ranger, 479 Siege). Die Ergebnisse liegen eng beieinander, daher wurden Klassenwerte nicht auf Basis dieses Bot-Laufs angepasst. Die Farmwahl prüft alle fünf Läufe 16 Seeds und schätzt mindestens 95% Erfolg; die einzelne Niederlage bei Arcanist und Ranger zeigt die Grenzen der Schätzung. Das ersetzt keine Balanceprüfung über weitere Seeds, Builds und echte Spieltests. Das Rohprotokoll liegt unter `build/reports/balance-v021-0.log`.

Die aktualisierte Boss-Suite bestand 110 Checks, darunter automatische Ausweichbewegung für beide Formen, Variantenauswahl nach Seed, Wechsel der zweiten Warnung, Speichern und Wiederaufnahme während eines sichtbaren Telegraphen sowie die unveränderten Legacy-Fixtures. Die Dungeonreise bestand 177 Checks. Die 480 Läufe je Klasse wurden mit genau diesen endgültigen Angriffszonen erneut simuliert.

## Persönliche Zufallsfolge 0.24

Neue Spielstände erhalten beim ersten Start einen eigenen gespeicherten Zufalls-Startwert. Daraus entstehen für jede Expedition getrennte Run-Seeds: Der Seed steuert weiterhin die reproduzierbaren Routen-, Gegner-, Bewegungs-, Fähigkeits- und Beuteentscheidungen. So beginnen neue Spielstände nicht alle mit derselben Run-/Loot-Sequenz, ohne dass ein aktiver Kampf bei Pause, Neustart, Skip oder AFK seinen Zustand verliert.

Die bestehende Musterbank umfasst 256 Layout-/Kampfmuster und bleibt für Offline-Farmen cachebar. Ältere Spielstände ohne Profilwert bekommen beim nächsten Laden einen; laufende Checkpoints tragen weiterhin ihren ursprünglichen Seed. Backup-Codes aus älteren Fassungen bleiben importierbar, auch wenn der neue Wert darin fehlt.

Die drei betroffenen Simulation-/Reise-/Vertragssuiten bestehen **331 Prüfungen**: 179 Reiseprüfungen inklusive Sieg und Live/Skip-Gleichheit über alle 256 Startmuster je Klasse, 84 Speicherprüfungen und 68 Vertrags-/AFK-Prüfungen. Ein persönlicher Spielstand wurde als x86_64-Testbuild auf dem API-36-Emulator gestartet, nach Force-Stop kalt geöffnet und offline bis zum nächsten Lagerstand abgerechnet. Die ARM64-Debug-APK wurde signiert geprüft; Play-AAB VersionCode 28 besteht Bundletool- und jarsigner-Prüfungen. Das ist kein physischer Gerätetest und keine Veröffentlichung.

## Natürlichere Spawnformationen 0.25

Der Seed dreht die Grundformation pro Raum über 360 Grad und verschiebt jeden Spawnpunkt leicht innerhalb der Kammer. So sind Gegnerabstände und Anmarschwinkel in jedem Muster anders, statt nur die Reihenfolge einer kleinen festen Punktliste zu wechseln. Gegnerzahl, Gegnerrollen-Pool und Statistiken bleiben gleich; alte Checkpoints behalten ihre gespeicherten Gegnerpositionen. Die Reise-Suite prüft mindestens 250 verschiedene Formationen aus der 256er-Musterbank und weiterhin identische Ergebnisse bei Zuschauen und Skip. Alle drei Klassen gewinnen alle 256 Startmuster mit Startausrüstung.

Die Reise-Suite besteht jetzt **182 Checks**; die Prüfungen bestätigen mindestens 250 verschiedene Spawnformationen, Aufstellung innerhalb des Raumes und Mindestabstand zwischen Gegnern. Der ARM64-Debug-Export, ein separater x86_64-Emulatorbuild und Play-AAB verwenden VersionCode 29. Der API-36-Emulator bei 1280×720 prüft die sichtbare Formation und automatische Fähigkeitsrotation in [22](audit/2026-09-28/22-random-spawn-run.png) und [23](audit/2026-09-28/23-auto-skill-rotation.png); ein physischer Gerätetest bleibt offen.

## Variierende Korridorwege 0.26

Der vollständige Run-Seed setzt die Abbiegung jedes Verbindungsgangs an eine andere Stelle. Die Route bleibt ein zusammenhängender, vollständig begehbarer Gang; nur der Platz der Abbiegung ändert sich, sodass jeder Pfad innerhalb derselben Grundform die gleiche Laufdistanz hat. Damit erhält jede Expedition einen eigenen Laufweg, ohne Kampfprognose, AFK-Zeit oder die cachebare 256er-Musterbank zu verändern. Laufende Checkpoints der Generation 2 behalten ihre vorherige Mittellinienroute; neue Expeditionen verwenden Generation 3.

Die Reise-Suite besteht **249 Checks**: 64 unterschiedliche, reproduzierbare Wegabbiegungen, gleicher Laufweg bei anderer Abbiegungsposition, Gang-Begehbarkeit, alle 256 Kampfmuster je Klasse mit Live-/Skip-Gleichheit sowie Wiederaufnahme und alte Checkpoints. Die Speicher-Suite besteht **84 Checks**. Der x86_64-Android-Build (VersionCode 30) wurde auf API 36 in 1280×720 gestartet; [24](audit/2026-09-28/24-randomized-path-gameplay.png) zeigt den Auto-Kampf und die veränderte Routenkarte. Das ist ein Emulatorcheck, kein physischer Gerätetest.

## Zeitversetzte Hinterhalte 0.27

Zwei Gegner aus den fünf normalen Gruppen erscheinen pro Lauf in zwei unterschiedlichen Räumen erst während des Kampfes. Die Musterwahl setzt fest, welche Gegner später eintreffen, wann sie erscheinen und an welchem wechselnden Rand der Kammer sie in den Kampf treten. Ist die übrige Gruppe schon besiegt, tritt der Hinterhalt sofort hervor, statt den Kampf künstlich anzuhalten. So bleibt kein Gegner liegen und auch die Belohnung bleibt an dieselben 26 Gegner gebunden. Die Ankunft wird im 3D-Kampf durch einen kurzen Feuerring und eine „AMBUSH“-Anzeige markiert.

Der Generator wurde auf Version 4 erhöht. Laufende Checkpoints aus Generation 1–3 behalten ihre bisherige Gegnerdarstellung und laden ohne nachträgliche Hinterhalte. Neue Saves speichern Auftauchzustand und Restzeit; die Reise-Suite bestätigt Wiederaufnahme während eines Auftauchens und identische Ergebnisse nach dem Wiederaufnehmen. Sie besteht jetzt **265 Checks**; drei Klassen bestehen weiterhin alle 256 Muster der Startetage mit Live/Skip-Gleichheit. Der Android-Build folgt nach dem lokalen Export.
