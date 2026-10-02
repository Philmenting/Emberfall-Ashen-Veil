# Einstieg, Schwüre und Build-Ziele — 0.39.0-beta.2

Historischer 0.39-Bericht. Aktuelle Schwur-Kombinationen und Wächterphasen stehen in [OATHS_AND_PHASES_040.md](OATHS_AND_PHASES_040.md); der neue Grafikstand ist in der [Asset-Herkunft](design/ASSET_PROVENANCE.md) beschrieben.

Neue Spieler wählen einen Helden und starten auf Etage 1 direkt am ersten echten Kampf. Die erste Signatur wird dort früh eingesetzt. Alle sechs Räume, reguläre Gegnerwerte und der Wächter bleiben erhalten. Neue Läufe auf Etage 1, einschließlich Farm und Prognose, verwenden dieselben Regeln; bereits gespeicherte Expeditionen behalten ihre bisherigen Regeln.

Der erste Kampagnen-Sieg auf Etage 1 garantiert einmalig eine seltene oder bessere Klassenreliquie im Amulett-Slot. Die Ergebnisansicht erklärt den Effekt und bietet direktes Anlegen vor der nächsten Expedition an. Bei einer vollen Tasche wird für diese erste Reliquie der günstigste Taschenfund verkauft; der Spieler erhält dessen Gold. Bestehende Profile oberhalb Etage 1 erhalten keine nachträgliche Erstbelohnung. Alle Klassen können alle Gegenstände tragen; ein Effekt wirkt nur für seine zugehörige Klasse. Alte Gegenstände werden nicht neu gewürfelt.

| Klasse | Reliquie | Tatsächlicher Kampfeffekt |
| --- | --- | --- |
| Vowkeeper | Bellwarden's Memory | Guard speichert verhinderten Schaden bis zu 60 % des Signatur-Schadens. Die nächste Ember Oath entlädt ihn einmal auf ihr Hauptziel. |
| Arcanist | Veilglass Conductor | Veil Nova springt vom Rand ihrer getroffenen Gruppe zu bis zu zwei zusätzlichen Gegnern. Jeder Sprung reicht höchstens 4 m und verursacht 45 % des Signatur-Schadens. |
| Ranger | Crowflight Loop | Cinder Volley trifft ihr noch lebendes Hauptziel ein zweites Mal für 35 % des Signatur-Schadens. |

Epische und legendäre Amulette tragen ebenfalls den entsprechenden Klasseneffekt. Das normale Zufallsverfahren für Qualität, Basiswerte und Verkaufspreis bleibt erhalten. Effekte sind anhand der Ereignisse im Kampf sichtbar. Automatische sichere Upgrades verändern weder den aktiven Klasseneffekt noch das aktive regionale Set; ein manueller Wechsel zeigt den Effektverlust an.

## Freiwillige Schwüre

Nach dem ersten Sieg bietet das Lager zwei Schwüre auf der nächsten Kampagnen-Etage an. Der jeweilige Vertrag bleibt für den Lauf und dessen Wiederholungen eingefroren. Normale Abstiege und das separat gewählte AFK-Farmziel übernehmen ihn nicht. Ein begonnener Schwur-Lauf behält seine Regeln auch bei einer Offline-Fortsetzung.

| Schwur | Risiko | Zusätzliche Belohnung bei Sieg |
| --- | --- | --- |
| Oath of the Unmended | Ember Oath und Heilbrunnen stellen kein Leben wieder her. Guard und Mana Ward bleiben möglich. | 30 % mehr Gold und XP, ein weiterer seltener oder besserer Fund. |
| Oath of Cinders | Gegner verursachen 25 % mehr Rohschaden. | Ein garantiertes episches oder besseres Klassenamulett. |

Niederlagen geben nur die regulären 55 Gold und 100 XP. Schwur-Siege öffnen die nächste Kampagnen-Etage. Übervolle reguläre Beute wird wie zuvor verkauft. Hunts und Ash Trials behalten ihre eigenen Regeln und Belohnungen.

## Regionale Sets und Wächtersiegel

Neue Beute trägt ihre Herkunftsregion. Drei angelegte Teile derselben Region aktivieren einen Bonus:

- **Ashen Vigil:** eine zusätzliche Sekunde Guard durch die Signatur; beim Vowkeeper insgesamt 3,8 Sekunden, bei anderen Klassen eine Sekunde.
- **Drowned Script:** 20 % weniger Mana-Kosten für die Signatur, ganzzahlig abgerundet mit Minimum 1.
- **Mourning Thread:** acht zusätzliche Prozentpunkte kritische Chance für die Signatur.
- **Cinder Crown:** 15 % kürzere Signatur-Abklingzeit.

Es wirkt höchstens ein Set: die Region mit den meisten getragenen Teilen, bei Gleichstand die frühere Region. Erstbeute und Schwur-Amulette tragen ebenfalls ihre Region. Fokus-Hunts helfen, fehlende Slots zu finden. Das Lager zeigt die nächste Region, ein aktives Set und gesammelte Siegel der vier Wächter. Siegel gibt es bei einem Kampagnen- oder Schwur-Sieg in der jeweiligen Region; sie sind Sammlungsfortschritt ohne zusätzliche Kampfstärke.

## Klang, Haptik und lokale Spieltest-Notizen

Der originale synthetische Soundtrack erhält ein zusammenhängendes achtteiliges Moll-Motiv, mit unterschiedlicher Klangfarbe in Lager und Dungeon. Nahkampf-, Magie- und Pfeiltreffer haben eigene Kontaktklänge. Optionale Android-Haptik meldet Warnungen, erlittenen Schaden und kritische Treffer, maximal einen kurzen Impuls je 180 ms. Sie ist standardmäßig ausgeschaltet und unabhängig von der Effektlautstärke. Android benötigt dafür ausschließlich zusätzlich `android.permission.VIBRATE`, eine normale Berechtigung ohne Laufzeitdialog. Die Solo-Beta erhält weiterhin keinen Internetzugriff.

Unter **Options > Beta / Privacy** lassen sich lokale Spieltest-Notizen aktivieren. Sie erfassen die ersten beobachteten Meilensteine in Simulationssekunden und eine Rückkehr nach mindestens 24 Stunden. Simulationszeit misst keinen App-Start und keine reale Zeit im Menü. Übersprungene Kämpfe werden nicht als beobachteter Erst-Sieg protokolliert. Es gibt keinen Versand, keine Nutzerkennung und keine automatischen Analytics. Ausschalten löscht die Notizen; nur ein bewusst kopierter Feedback-Bericht enthält sie.

## Nachweise

Die zusätzliche Smoke-Suite prüft Schwur-Regeln, echte Reliquien-Effekte, Erstbeute, regionales Equipment, Speichergrenzen, alte optionale Felder und identische Kampfzustände für Zuschauen, Überspringen und Fortsetzen. Die bestehende AFK-Suite prüft synchrone und kooperative Abrechnung sowie unterbrochene Journale. Neue Regeln werden einmal gemeinsam für echte Läufe, Farm und Prognose erzeugt.

Die [Balance-Probe](audit/2026-10-02/success-balance.json) untersucht **360 Expeditionen**. Alle 72 Einstiege mit normaler Startausrüstung wurden gewonnen; spätestens nach 1,3 Sekunden erfolgte ein Treffer, und kein Lauf dauerte länger als 117,6 Simulationssekunden. Die übrigen 288 Läufe vergleichen normale Abstiege und beide Schwüre auf Etage 2 und 6 mit derselben Startausrüstung plus einem reproduzierbaren Klassenamulett. Das zeigt eine spielbare Einführung und unterschiedliche Risiken, keine abgeschlossene Langzeit- oder Wirtschafts-Balance.

Die [Ansichten](previews/success-loop/) zeigen 1200 × 535 für das Pixel-Außendisplay-Verhältnis sowie eine beinahe quadratische Ansicht. Zusätzlich wurden 854 × 480 und große Schrift geprüft. Der [12-sekündige Gameplay-Clip](previews/success-loop/emberfall-gameplay-beta2.mp4) enthält echte Kämpfe mit normaler Startausrüstung: erster Kampf, Schnitt zum Wächter desselben Laufs, tatsächlich verdiente Beute. Keine erhöhten Lebens- oder Schadenswerte. Wiedergabe mit 24 FPS und originalem Musikmotiv; ein deterministischer Frame-Export ist keine Messung der Handy-FPS.

Der Android-Runtime-Workflow prüft zusätzlich den neuen Einstieg über echte UI-Signale, das Anlegen der verdienten Reliquie, den Schwur-Start und einen kalten Neustart mit unverändertem Checkpoint. Ein separates ARM64-Paket `emberfall-pixel-probe.apk` misst sechs **laufende** Kampfszenarien auf echten Handys, drei Klassen in Balanced/Battery. Dieses Paket ist vom regulären Spielstand getrennt; es wird nicht als Emulator-Leistungsnachweis ausgeführt. Vorgehen und ehrliche offene Punkte stehen im [Spieltest-Plan](SUCCESS_PLAYTEST.md).

```bash
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 python3 scripts/run_beta_checks.py
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 python3 scripts/export_android_qa.py --architecture arm64-v8a --scene res://tests/android_device_probe.tscn --output build/emberfall-pixel-probe.apk
```
