# Beutejagden und Aschenprüfungen – 0.13

## Drei unterschiedliche Ziele

Nach einem regulär gewonnenen ersten Kampagnenlauf öffnen sich unter **World** zwei weitere Reiter. Zuschauen, Überspringen und die Fortsetzung nach dem Schließen verwenden jeweils dieselbe Kampfsimulation.

| Modus | Zweck | Gegner und Zeit | Belohnung / Fortschritt |
|---|---|---|---|
| Campaign | Neue Etagen und Gebiete öffnen | Bisherige Regeln; neue Routen maximal 240 s | Bisherige Beute; Sieg schaltet die nächste Kampagnenetage frei |
| Hunts | Gezielt einen Ausrüstungsslot verbessern | Auf einer freigeschalteten Farm-Etage: +15% Gegnerleben, +8% Schaden | Jeder Drop gehört zum gewählten Slot; mindestens Rare beim Sieg. Kein zusätzlicher Kampagnenfortschritt |
| Ash Trials | Einen Build unter Zeitdruck prüfen | 30 Stufen; Gegneretage `1 + 2 × (Stufe − 1)`, +25% Leben, +15% Schaden, 150 s einschließlich Wege und Truhe | Pro Stufe einmal ein Epic-oder-besserer Gegenstand, Gold und XP. Eigener Fortschritt; keine automatische Wiederholung |

Die Modelle, Orte und Fähigkeiten bleiben eigene Godot-Inhalte. Ein violettes, aus Godot-Geometrie gebautes Eingangstor und der sichtbare Countdown kennzeichnen die Prüfung.

### Gezielte Jagden

**World → Hunts** bietet Weapon, Helmet, Chest, Gloves, Boots und Amulet. Die Wahl gilt für sichtbare Wiederholung und Offline-Farmen. **All Gear** kehrt zu den normalen Kampagnenregeln für das Farmen zurück. Die Farm-Etage bleibt separat wählbar; ein Hinweis zeigt Gebiet und Beutestufe. Auch im Lager führt **Farm Goal** zur Auswahl.

Die Erfolgsaussicht wird mit der tatsächlichen erhöhten Schwierigkeit berechnet. Beim Wechsel von Ziel oder Etage wird zuvor vergangene Zeit mit der bisherigen Auswahl abgerechnet; der unvollständige Zeitrest wird verworfen und nicht in den neuen Modus übertragen. Während eines laufenden Dungeons ist die Auswahl gesperrt.

### Aschenprüfungen

Es ist jeweils die nächste noch nicht bestandene Stufe zugänglich. Eine Niederlage oder ein abgelaufenes Zeitlimit gibt keine Beute, kein Gold und keine XP. Skip kann das Zeitlimit nicht umgehen. Nach dem Sieg steigen nur die Prüfungsstufe und die regulären Charakterwerte durch die Belohnung; die Kampagnenetage bleibt gleich.

Die erste Stufe gibt 730 Gold, 978 XP und genau einen Epic-oder-besseren T1-Gegenstand. Spätere Belohnungen folgen der angezeigten Gegneretage: Basisgold `186 + Etage × 4`, Bonus `500 + Stufe × 40`; Basis-XP `420 + Etage × 8`, Bonus `500 + Stufe × 50`. Beutestufen folgen derselben Etagenstaffel wie die Kampagne. Bei voller Tasche wird der Fund nach der bestehenden Overflow-Regel verkauft; die Ergebnisanzeige enthält dieses zusätzliche Gold.

Eine Prüfung wiederholt sich nicht automatisch. Bei aktiviertem AFK-Farmen wird ein bereits laufender Prüfungsversuch nach Rückkehr exakt fortgesetzt. Nach seinem Ende läuft die zuvor gewählte Farm-Auswahl weiter. Ein pausierter Versuch bleibt pausiert. Auch eine alleinige Offline-Prüfungsniederlage erscheint im abholbaren Bericht, obwohl sie kein Gold bringt.

## Speicherung und Kompatibilität

Das konkrete Ziel liegt als versionierter Vertrag im Kampf-Checkpoint: Modus, Slot beziehungsweise Prüfungsstufe. Dadurch kann eine spätere Menüauswahl die bereits begonnene Expedition nicht verändern. Auswahl und höchste bestandene Prüfungsstufe werden zusätzlich im Spielstand gesichert. Die Prüfung akzeptiert ihre Abschlussbelohnung nur für die unmittelbar nächste Stufe; wiederholte Resume-Ereignisse und doppelte Aufrufe vergeben sie nicht erneut.

Alte Expeditionen ohne Vertrag behalten ihre Regeln. Zwölf mit unverändertem 0.12-Code erzeugte Checkpoints vergleichen den vollständigen finalen Zustand; außerdem bleiben 192 Kampagnen-Beutewürfe exakt gleich.

## Tests und Balance

749 erfolgreiche Prüfungen in 13 Suiten, darunter 68 für Verträge, gezielte Drops, echte Gegnerwerte, Zeitablauf, Checkpoints, AFK-Gleichheit, Erstbelohnungen, volle Taschen, gespeicherte Auswahl und die Menü-/HUD-Verbindungen. Die 64 Startvarianten aller drei Klassen vergleichen Live und Skip getrennt für Jagd und Prüfung. Alle sechs Slots werden über drei Klassen, 64 Startwerte und mehrere Beutestufen geprüft.

Das zunächst geplante 120-Sekunden-Limit mit Dreier-Etagensprüngen war für den Nahkämpfer zu hart: Mit regulär nach 480 Kampagnenläufen erspielten Werten scheiterte er in Stufe 20 und 30 in allen 64 Varianten am Timer. Daher gelten jetzt 150 Sekunden und Zweier-Etagensprünge.

Mit denselben dokumentierten Werten bestanden alle Klassen die Prüfungsstufen 10 und 20 in 64/64 Varianten. Stufe 30: Vowkeeper 62/64 (durchschnittlich 139,8 s), Arcanist 64/64 (90,7 s), Ranger 64/64 (86,0 s). Das ist eine feste Ausrüstung je Klasse aus einem Fortschrittsbot, keine vollständige Balance- oder Langzeitaussage. Die separate Messung ist mit `tests/trial_balance_survey.gd` und `tests/fixtures/trial_balance_013.json` reproduzierbar. Rohdaten liegen lokal unter `build/reports/trial-frontier-013-final.log`.

Der Android-Test verwendet einen isolierten Spielstand. Der erste Kampagnensieg wird mit dem normalen Skip erarbeitet, danach werden Menüs per echter Touch-Eingabe bedient. Ausrüstung und Kampfwerte werden nicht erhöht. Screenshots und Protokolle liegen unter `build/previews/android-013-*.png` und `build/reports/android-013-contracts.log`.

## Grenzen

Die Spielarten verwenden die vier vorhandenen regionalen Grundrisse und Gegnerrollen. Zufällige Karten, Gruppeninstanzen, ein Online-Hub und ein Mehrspieler-Server sind noch nicht enthalten. Physische Android-Geräte und menschliche Langzeittests bleiben vor einer Veröffentlichung zu prüfen.

### Android-Ergebnis

Der sichtbare Arcanist-Jagdlauf gewann nach 71,7 s und vergab seltene Starless Slippers im gewählten Slot Boots. Eine echte automatische Wiederholung behielt das Jagdziel bei und lieferte weitere Stiefel. Die finale Aschenprüfung mit 150-Sekunden-Limit wurde per Touch gestartet und nach 72,9 s gewonnen: einmalige 730 Gold, 978 XP und epische Veilwalker Treads; Kampagne blieb auf Etage 2, Prüfungsfortschritt stieg auf 1. Der vollständige Mitschnitt liegt unter `build/previews/emberfall-013-trial.mp4` (1280×720, ohne Audio).
