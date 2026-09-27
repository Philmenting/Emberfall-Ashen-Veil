# Early-Access-Entwicklung

Ziel: ein veröffentlichbares Android-AFK-Action-RPG im Querformat mit dem räumlichen Spielablauf der Gameplay-Referenz. Grafik soll atmosphärisch und gut lesbar sein; AAA-Detailgrad ist keine Anforderung.

## Stand und Nachweise

Der bisherige Entwicklungsschritt ist **Fortschritt**: Version 0.12 enthält automatische 3D-Gruppenkämpfe, vier eigene begehbare Grundrisse mit Zwischenzielen und Karte, Klassenverhalten mit Mana-Barriere, Abstandhalten und wählbarer automatischer Fähigkeitsrotation, gemeinsame Live-/Skip-/AFK-Simulation und persistente Expeditionen mit Speichersicherung. 681 lokale Prüfungen, Android-Aufnahmen und zwei erfolgreiche Prüfungen bei tatsächlichem Android-Prozessneustart liegen vor. Das allein belegt noch keine Early-Access-Reife.

| Bereich | Aktueller Stand | Noch zu belegen / entwickeln |
|---|---|---|
| Automatische Expedition | Sechs Gruppen, 26 Gegner, vier Bossmuster mit verstärkter Phase, drei Klassen und automatischem Ausweichen | Längere Spielsessions, Balance verschiedener Fähigkeitskombinationen und neuer Routen/Zwischenziele |
| Progression und Beute | Fünf Qualitäten, sechs Slots, Attribute, Verstärkung, Etagenwahl, echte Gegenstandsvergleiche und kostenlose Neuverteilung | Klassenbeute und drei Beutesequenzen mit je 480 Läufen/Klasse untersucht; Fortschrittsunterschied verringert. Andere Builds und menschliche Spieltests bleiben offen |
| AFK | Gemeinsame Kampflogik, gewählte Etage, Zeitlimit, Overflow-Verkauf; exakte Fortsetzung über Neustarts geprüft | Längere Abwesenheiten auf physischen Geräten; Balancing der Erträge |
| Spielstände | Zwei atomar ersetzte Generationen, Prüfsumme, Kampfzustand, Migration und sichtbare Fehler; 69 Prüfungen | Verständliche Sicherungs-/Wiederherstellungsbedienung, künftige Migrationen |
| Bedienung | Klassenwahl beim Einstieg, getrennte Ausrüstungsreiter, echte Wertevergleiche, Farm-Prognosen, Offline-Bericht oben | Optionen, Hilfe und Rücknavigation ergänzt; weitere Bildschirmgrößen und physische Geräte prüfen |
| Darstellung und Ton | Vier eigene Umgebungen, verschiedene Routen, Boss-Silhouetten und interaktive Zwischenziele; starre Figurenteile zusammengefasst | Synthetisierte Musik/Effekte und Leistungsmodus ergänzt; subjektive Klangprüfung und längere Gerätemessungen offen |
| Online-Umfang | Der aktuelle Stand ist lokal/solo | Rückmeldung zum Online-Umfang des Early Access steht aus; keine Mehrspieler-Funktionen behaupten |
| Veröffentlichung | Lokale Debug-APK und signiertes AAB 0.12 lokal exportiert und geprüft; CI baut APK und AAB | Release-Checkliste, Store-Material, Datenschutz-/Altersangaben anhand tatsächlicher Funktionen, Freigabe in der Play Console |

## Freigabeprinzip

Jeder Bereich braucht konkrete Belege am tatsächlichen Release-Kandidaten. Ein APK-Export oder grüne Unit-Tests allein ersetzen weder Spieltests noch die Prüfung der Veröffentlichungsvoraussetzungen. Offene Punkte bleiben offen; der Gesamtauftrag bleibt aktiv.

## Aktuelle Gameplay-Priorität

Der Nutzer hat eine engere Orientierung am weiteren Diablo-Immortal-Spielablauf gewünscht. Konkrete Video-Beobachtungen, der Ausbau in 0.11/0.12 und die nächste Priorität (unterschiedliche Expeditionstypen und gezielte Belohnungen) stehen in [GAMEPLAY_DIRECTION.md](GAMEPLAY_DIRECTION.md). Die zuvor geplante Bedienung für externe Spielstandsicherungen ist dafür zurückgestellt, bleibt aber vor einer Veröffentlichung offen.
