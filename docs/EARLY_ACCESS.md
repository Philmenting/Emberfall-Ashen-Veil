# Early-Access-Entwicklung

Ziel: ein veröffentlichbares Android-AFK-Action-RPG im Querformat mit dem räumlichen Spielablauf der Gameplay-Referenz. Grafik soll atmosphärisch und gut lesbar sein; AAA-Detailgrad ist keine Anforderung.

## Stand und Nachweise

Der bisherige Entwicklungsschritt ist **Fortschritt**: Version 0.10 enthält automatische 3D-Gruppenkämpfe, vier Gebietsgestaltungen, Klassenverhalten mit Mana-Barriere und Abstandhalten, gemeinsame Live-/Skip-/AFK-Simulation und persistente Expeditionen mit Speichersicherung. 438 lokale Prüfungen, Android-Aufnahmen und zwei erfolgreiche Prüfungen bei tatsächlichem Android-Prozessneustart liegen vor. Das allein belegt noch keine Early-Access-Reife.

| Bereich | Aktueller Stand | Noch zu belegen / entwickeln |
|---|---|---|
| Automatische Expedition | Sechs Gruppen, 18 Gegner, vier Bossmuster mit verstärkter Phase, drei Klassen und automatischem Ausweichen | Längere Spielsessions, weitere Routen und Balance der neuen Bossmechaniken |
| Progression und Beute | Fünf Qualitäten, sechs Slots, Attribute, Verstärkung, Etagenwahl, echte Gegenstandsvergleiche und kostenlose Neuverteilung | Klassenbeute und drei Beutesequenzen mit je 480 Läufen/Klasse untersucht; Fortschrittsunterschied verringert. Andere Builds und menschliche Spieltests bleiben offen |
| AFK | Gemeinsame Kampflogik, gewählte Etage, Zeitlimit, Overflow-Verkauf; exakte Fortsetzung über Neustarts geprüft | Längere Abwesenheiten auf physischen Geräten; Balancing der Erträge |
| Spielstände | Zwei atomar ersetzte Generationen, Prüfsumme, Kampfzustand, Migration und sichtbare Fehler; 69 Prüfungen | Verständliche Sicherungs-/Wiederherstellungsbedienung, künftige Migrationen |
| Bedienung | Klassenwahl beim Einstieg, getrennte Ausrüstungsreiter, echte Wertevergleiche, Farm-Prognosen, Offline-Bericht oben | Optionen, Hilfe und Rücknavigation ergänzt; weitere Bildschirmgrößen und physische Geräte prüfen |
| Darstellung und Ton | Vier eigene Umgebungen und Boss-Silhouetten auf gemeinsamer Route; starre Figurenteile zusammengefasst | Synthetisierte Musik/Effekte und Leistungsmodus ergänzt; subjektive Klangprüfung und längere Gerätemessungen offen |
| Online-Umfang | Der aktuelle Stand ist lokal/solo | Rückmeldung zum Online-Umfang des Early Access steht aus; keine Mehrspieler-Funktionen behaupten |
| Veröffentlichung | Lokale Debug-APK und signiertes AAB 0.10 geprüft; CI baut APK und AAB | Release-Checkliste, Store-Material, Datenschutz-/Altersangaben anhand tatsächlicher Funktionen, Freigabe in der Play Console |

## Freigabeprinzip

Jeder Bereich braucht konkrete Belege am tatsächlichen Release-Kandidaten. Ein APK-Export oder grüne Unit-Tests allein ersetzen weder Spieltests noch die Prüfung der Veröffentlichungsvoraussetzungen. Offene Punkte bleiben offen; der Gesamtauftrag bleibt aktiv.
