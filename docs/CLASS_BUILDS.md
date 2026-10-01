# Klassen-Builds und Arcanist — 0.10

## Arcanist

Der Arcanist geht zwischen seinen Angriffen auf Abstand zu nahen Nahkämpfern. Dafür nutzt er die normale Laufgeschwindigkeit, bleibt im aktuellen Begegnungsbereich und sucht keine Schritte in bereits angekündigte Gefahrenflächen. Während eines begonnenen Zaubers bleibt er stehen. Dieses Verhalten setzt weder die Ausweich-Abklingzeit zurück noch verleiht es Unverwundbarkeit.

Veil Nova trifft einen Radius von 4,5 statt 3,2 um ihr Ziel. Der berechnete Fähigkeitenschaden neuer Arcanist-Läufe ist um 30 Prozent erhöht; Kosten, Abklingzeit, Verlangsamung und Unterbrechung bleiben erhalten. Eine violette Welle zeigt die Nova in der Spielwelt. Mana Ward behält ihre bisherigen Regeln: 35 Prozent Absorption für zwei Mana pro absorbiertem Schadenspunkt, mit Reserve für eine Nova.

Alte, begonnene Expeditionen behalten ihre gespeicherten Werte und das vorherige Verhalten. Neue Expeditionen erhalten den optionalen Regelwert `arcane_tactics=1`. Referenzergebnisse des unveränderten 0.9-Simulators prüfen diese Kompatibilität.

## Klassenbezogene Beute

Neue Gegenstände erhalten Namen und eine Abstimmung für die Klasse, die sie erbeutet: beispielsweise Stäbe und Roben für Arcanisten, Bögen und Tracker-Ausrüstung für Ranger sowie Klingen und Plattenrüstung für Vowkeeper. Jeder neue Fund trägt das Hauptattribut dieser Klasse; weitere Attribute bleiben zufällig und die Anzahl hängt von der Qualität ab. Alle sechs Slots, fünf Qualitäten und Stufen T1–T10 bleiben verfügbar. Bossbeute ist weiterhin mindestens selten.

Die Abstimmung ist eine Orientierung und keine Ausrüstungssperre. Ein Klassenwechsel lässt vorhandene Gegenstände nutzbar. Die Oberfläche zeigt die Abstimmung und weiterhin die tatsächlichen Werteänderungen für die aktive Klasse. Vorhandene Ausrüstung wird nicht neu gewürfelt. Zuschauen und Offline-Abrechnung erzeugen bei derselben verdienten Klasse und demselben Startwert identische Gegenstände, Gold und XP.

## Balance-Nachweise

Mit identischen Werten an der Arcanist-Grenze von 0.9 zeigte eine getrennte Untersuchung zu kurzes Abstandhalten als einen Schwachpunkt. Eine erste Variante des Zurückweichens verbesserte die Siege von 48 auf 58 aus 64 Kampfmustern. Allein reichte dies im anschließenden Langzeitversuch nicht: Der Arcanist kam nur von Etage 54 auf 59. Klassenbeute plus Abstandhalten ohne stärkere Nova führte mit derselben Bot-Strategie zu Etage 55. Erst die Kombination mit der breiteren und stärkeren Nova verringerte den Rückstand deutlich.

Die fertige Kombination wurde mit drei Beutesequenzen über jeweils 480 Läufe je Klasse untersucht, insgesamt 4.320 Expeditionen:

| Beutesequenz / Seed-Offset | Vowkeeper: Etage / Siege | Arcanist: Etage / Siege | Ranger: Etage / Siege |
|---|---|---|---|
| 0 | 95 / 480 | 83 / 478 | 95 / 480 |
| 64 | 95 / 480 | 81 / 480 | 93 / 480 |
| 128 | 85 / 480 | 85 / 479 | 95 / 480 |

„Etage“ bezeichnet die nächste freigeschaltete Etage nach dem letzten Lauf. Der Bot bewertet alle fünf Läufe anhand von 16 Kampfmustern, welche Etage er spielt, verteilt Attribute, vergleicht Gegenstände, verkauft Funde und verstärkt bis +3. Seine einfache Bewertung ist keine optimale Build-Suche. Die Dauer unterscheidet sich weiterhin: Vowkeeper benötigt etwa 15,6–16,4 simulierte Stunden, Arcanist 10,6–11,4 und Ranger 9,2–9,6. Die Ergebnisse zeigen geringere Fortschrittsunterschiede in diesen Szenarien; sie belegen keine allgemein abgeschlossene Klassen- oder Wirtschafts-Balance. Menschliche Spieltests und andere Builds bleiben nötig.

```bash
XDG_DATA_HOME=/tmp/emberfall-survey-0 godot --headless --path . --script tests/balance_survey.gd
XDG_DATA_HOME=/tmp/emberfall-survey-64 godot --headless --path . --script tests/balance_survey.gd -- 64
XDG_DATA_HOME=/tmp/emberfall-survey-128 godot --headless --path . --script tests/balance_survey.gd -- 128
```

### Aktuelle Fähigkeiten-Paare — Version 0.31

Eine erneute 480-Läufe-Probe mit Profil-Seed 1979 vergleicht je Klasse das Standardpaar mit einer alternativen Kombination. Der Vowkeeper erreichte mit Bastion + Sundering Arc Etage 91 und mit Judgment + Bastion Etage 81; beim Arcanist lagen Chain + Frost Mantle und Starfall + Frost Mantle mit Etage 90 beziehungsweise 91 eng beieinander. Der Ranger erreichte mit Smoke + Rain Etage 76 und mit Marked + Smoke Etage 73. In allen Fällen blieb die Siegquote mindestens 478/480. Das zeigt, dass die Flächenfähigkeit des Vowkeepers für diesen Seed besonders wichtig ist, aber keinen Grund für einen pauschalen Klassen-Buff. Eine einzelne Seedfolge ersetzt keine Mehrseed- oder Spielerprüfung. Details stehen in [der 0.31-Probe](audit/2026-09-29/balance-builds-0.31.md).

`tests/balance_survey.gd` nimmt nach dem Seed-Offset einen Loadout-Index von 0 bis 2 an: 0 = Standardpaar, 1 = Techniken zwei und drei, 2 = Techniken drei und eins. Dadurch lassen sich alle drei spielbaren Zweierkombinationen jeder Klasse mit demselben Bot vergleichen.

## Funktionsprüfungen

438 Prüfungen in zehn Suiten, darunter 29 für Klassenbeute und 29 für die Arcanist-Taktik. Die Beuteprüfung erzeugt für jede Klasse 5.000 normale und 5.000 Bossfunde. Die Taktikprüfung umfasst Bewegungsgrenzen, stationäres Zaubern, Gefahrenflächen, alte Regeln, Nova-Reichweite, Speicherung, Darstellung und 256 weitere Vergleiche aller Kampfmuster in vier Gebieten zwischen Zuschauen und Überspringen.

```bash
XDG_DATA_HOME=/tmp/emberfall-class-loot godot --headless --path . --fixed-fps 60 --script tests/class_loot_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-arcane-tactics godot --headless --path . --fixed-fps 60 --script tests/arcane_tactics_smoke.gd
```

`tests/android_tactics.tscn` verwendet eine eigene Paketkennung und einen frischen isolierten Spielstand. Der Arcanist läuft Etage 1 mit normaler Startausrüstung, zeigt Nova und Abstandhalten und öffnet anschließend die tatsächlich erspielte Beute und die Tasche. Es werden keine Testwerte für Leben oder Schaden gesetzt. Normale Exporte enthalten diese Testszene nicht.

Der Durchlauf wurde auf Android API 36 bei 1280 × 720 erfolgreich erfasst: 51,1 Sekunden Simulationszeit, 364 Leben und 231 Mana übrig, normale Belohnung von 190 Gold und 428 XP sowie seltene Veilwalker Treads mit Arcanist-Abstimmung. Die vier Aufnahmen zeigen Nova, Abstandhalten, Beute und Tasche. Das Protokoll enthält `ANDROID_TACTICS_DONE` ohne Skriptfehler. Nachweise liegen lokal unter `build/previews/android-010-*.png` und `build/reports/android-010-tactics.log`.
