# Gameplay-Richtung nach erneuter Referenzsichtung

Stand: 27. September 2026, Umsetzungsschritt 0.11.

## Betrachtete Ausschnitte

Die Videos wurden im Browser an den folgenden Stellen tatsächlich betrachtet, nicht vollständig am Stück angesehen:

- [Vom Nutzer genannte Vorlage, Teil 1](https://www.youtube.com/watch?v=aRDi0lavO7I): etwa 50:27 (Dialog im räumlichen Umfeld), 1:10:38 (Gegnergruppe, Raumziel, Gold und Ausrüstung im Kampf), 1:11:07 (Skelettkönig, Bodenangriffe und Heilkugeln).
- [Direkte Fortsetzung desselben Walkthroughs, Teil 2](https://www.youtube.com/watch?v=ItLA5IQROE4): etwa 34:51 (Werkstatt und Figuren im Hub), 1:00:59 (Lager/Questkontakt), 1:18:25 (Herausforderungsportal mit Stufe und Belohnungen), 1:19:07 (Gruppenkampf im Portal, Fortschrittsziel und Abklingzeiten).
- [Blizzards Gameplay-Überblick](https://news.blizzard.com/en-us/article/23557147/diablo-immortal-gameplay-overview-everything-you-need-to-know) beschreibt Gebiete, Dungeons, wiederholbare Portale, Ausrüstung und Solo-/Gruppenspiel. Der Artikel stammt aus der Alpha; seine damaligen Laufzeiten sind keine aktuelle Balance-Vorgabe.

Die folgende Übertragung ist unsere Designentscheidung. Eigene Orte, Modelle, Namen und Systeme bleiben Bestandteil von Emberfall.

## Konsequenzen für Emberfall

| Beobachtung | Übertragung auf Auto/AFK | Stand |
|---|---|---|
| Zusammenhängende Räume und Erkundung zwischen Kämpfen | Figur folgt sichtbaren Verbindungen und Kurven; aktuelle Position und Ziel auf der Karte | 0.11: vier verschiedene, handgebaute Grundrisse |
| Gruppen mit Nahkämpfern, Fernkämpfern und Eliten | Gegnerrollen beeinflussen automatische Zielwahl und Flächenfähigkeiten | 0.11: 26 Gegner in unterschiedlich großen Gruppen statt immer drei Gegnern |
| Abwechslung zwischen Kämpfen und kleinen Aufgaben | Brunnen nutzen, bewachtes Siegel brechen, Bosszugang öffnen, Reliquiar bergen | 0.11: automatisch in derselben Live-/Skip-/AFK-Simulation |
| Sichtbare Heilung und Beute im Geschehen | Einmalige Brunnenheilung; sichtbare finale Truhe vor der Beuteauswertung | 0.11; einzelne physische Ausrüstungsdrops mit Namen bleiben offen |
| Mehrere Fähigkeiten mit unterschiedlichen Rollen | Konfigurierbare automatische Rotation aus Angriff, Flächenschaden, Bewegung und Schutz | Nächster Schwerpunkt; aktuell Grundangriff plus eine aktive Klassenfähigkeit und Passive |
| Hub, Aufgaben, Gebiete und Portale erfüllen verschiedene Zwecke | Gebietsexpeditionen, gezieltes Farmen und eine separate Herausforderung mit ersten Abschlussbelohnungen | Weitere Entwicklung; aktuell Etagenprogression und Farm-Auswahl |
| Andere Spieler bewegen und kämpfen gemeinsam | Online-Spiel braucht echte gemeinsame Zustände, Gruppen und Server | Offen; aktuelle Version bleibt ehrlich als lokal/solo beschrieben |

## Regeln der aktuellen Umsetzung

- Sechs Kammern pro Gebiet, unterschiedliche seitliche Verbindungen. Der Grundriss wird von Simulation, Bodenaufbau und Karte gemeinsam gelesen.
- Gruppen: 5 / 4 / 5 / 4 / 5 / 3 Gegner. Normale Gegner besitzen 72% ihrer bisherigen Einzel-Lebenspunkte. Elite und Boss behalten ihre Lebenspunkte; Angriffsschaden und Klassensystem bleiben bestehen.
- Nach Kammer 2: Brunnen heilt einmal bis zu 18% des maximalen Lebens, ohne Überheilung. Nach Kammer 4: bewachtes Siegel öffnet das Tor zum Heiligtum. Nach dem Boss: Figur läuft zum Reliquiar und öffnet es.
- Keine zusätzliche Gratisbeute: Das Reliquiar führt zur bestehenden, genau einmal vergebenen Abschlussbelohnung. Brunnen, Siegel und Truhe kosten tatsächliche Laufzeit, auch beim Skip und offline.
- Laufwege, Kampf, Interaktionen und Zielzustände werden gespeichert. Angefangene Expeditionen aus 0.10 und früher behalten ihre alte Route, Gegneranzahl und Ergebnisse. Neue Expeditionen erhalten `dungeon_journey=1`.
- Neue Expeditionen haben ein Sicherheitslimit von vier Minuten. Das alte Drei-Minuten-Limit benachteiligte den Nahkämpfer durch die zusätzlichen Wege; alte laufende Expeditionen behalten auch ihr altes Limit.
- Neue Geometrie und Gegenstände bestehen aus eigenen Godot-Meshes. Statische Bauteile werden gebündelt. Die kleine Karte ist eine Godot-Zeichnung.

## Nachweise und Grenzen

544 lokale Prüfungen: die bisherigen 438 plus 106 für Wege, Zwischenziele, alte Checkpoints und Darstellung. Enthalten sind alle 64 Startvarianten je Klasse, Vergleiche von Live/Skip, Wiederaufnahme während Wegstrecken und Interaktionen sowie zwölf mit unverändertem 0.10-Code erzeugte Vergleichsstände.

Android-Testlauf mit unveränderter Arcanist-Startausrüstung auf Etage 1: sichtbare Gruppen, Abbiegung, Brunnen, Siegel, Boss, Truhe und normale Beuteauswertung. Bilder und Protokoll liegen lokal in `build/previews/android-011-*.png` und `build/reports/android-011-journey.log`.

Diese Version hat noch keine freie offene Welt, zufällige Raumgenerierung, mehrere ausrüstbare aktive Fähigkeiten oder Mehrspielerfunktion. Die Referenzsichtung und dieser Ausbau ersetzen keine physischen Gerätetests und keinen menschlichen Langzeittest. Die bisherigen Balance-Messungen aus 0.10 gelten nicht unverändert für die längeren Wege und zusätzlichen Gegner.

### Fortschrittsprobe mit dem endgültigen Vier-Minuten-Limit

Der vorhandene Ausrüstungs-/Farm-Bot absolvierte 480 echte Simulationen je Klasse (Beutefolge 0), einschließlich Ausrüstungswahl, Attribute und Verstärkung. Vowkeeper erreichte nächste Etage 91 in 19,84 simulierten Stunden, Arcanist 97 in 13,59 Stunden, Ranger 97 in 12,12 Stunden. Alle drei gewannen 480/480 ausgewählte Farm-/Fortschrittsläufe. Die Auswahl prüft vor einem Aufstieg die Erfolgsaussicht; dies bedeutet daher keine Erfolgsgarantie auf beliebig hohen Etagen. Der Nahkämpfer ist weiter langsamer. Ein einzelner Bot und eine Beutefolge belegen keine vollständige Klassenbalance.

Lokales Rohprotokoll: `build/reports/balance-011-0-final.log`. Der 105-Sekunden-Android-Mitschnitt liegt unter `build/previews/emberfall-011-gameplay.mp4` (1280×720, ohne Audiospur). Er zeigt den vollständigen ersten Arcanist-Lauf mit 26 besiegten Gegnern, 76,8 Sekunden Simulationszeit und der tatsächlich vergebenen seltenen Klassenbeute. Die abschließende Änderung am Zeitlimit betrifft höhere/längere Läufe; der aufgezeichnete Erstlauf bleibt unverändert.
