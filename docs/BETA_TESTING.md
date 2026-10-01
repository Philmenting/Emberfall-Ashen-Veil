# Emberfall 0.38 – Closed-Beta-Test

## Testbuild

| Angabe | Wert |
|---|---|
| Version | `0.38.0-beta.1` (Code 42) |
| Datei | `build/emberfall-038-closed-beta.apk` |
| Architektur | ARM64 (`arm64-v8a`) |
| Android | API 24–36 |
| Ausrichtung | Querformat |
| Netzwerk | Dieses Closed-Beta-Profil ist offline und fordert keine Internetberechtigung an. |
| SHA-256 | `22856159add93a84c3a2745737591474b7c38f9fed53e2c38ae35b244b511e26` |
| Testpaket | `build/emberfall-0.38.0-beta.1-test-package.zip` |

Das APK lässt sich neben den separat benannten Android-Testbuilds installieren. Android kann beim ersten Öffnen nach der Erlaubnis fragen, APK-Dateien aus der verwendeten Datei- oder Browser-App zu installieren. Der Testbuild ist nicht über Google Play verteilt.

## Download aus GitHub Actions

Öffne im [GitHub-Projekt](https://github.com/Philmenting/Emberfall-Ashen-Veil) **Actions → Android Debug APK**, wähle den neuesten erfolgreichen Lauf auf `main` und lade `emberfall-ashen-veil-android-ci-validation-only` herunter. Nach dem Entpacken installiere `build/emberfall-closed-beta-ci.apk`. Der CI-Build hat dieselbe Paketkennung und Version wie der Closed-Beta-Kandidat, wird aber pro Lauf mit einem neuen temporären Schlüssel signiert. Deinstalliere deshalb eine frühere CI- oder lokal signierte Closed-Beta-Version zuerst; Spielstände dieser Testinstallation können dabei verloren gehen.

## Spielstand

Der Closed-Beta-Spielstand liegt lokal auf dem Gerät. Vor dem Löschen der App oder ihrer Daten kann unter **Options → Save Backup** ein Backup-Code erstellt werden. Wer diesen Code weitergibt, gibt damit auch den darin enthaltenen Spielstand weiter. Der Online-Testbuild ist ein eigener, getrennter Test und gehört nicht zu diesem Offline-APK.

## Empfohlene Prüfrunde

1. Zum ersten Mal starten, jede der drei Klassen kurz ansehen und eine wählen.
2. Im Lager Ausrüstung und Attribute öffnen. Einen Gegenstand vergleichen, anlegen und – wenn vorhanden – einen anderen verkaufen.
3. Über die Weltkarte eine Expedition beginnen und einige Kämpfe beobachten. Prüfen, ob Nyra automatisch läuft, Gegner angreift und Fähigkeiten einsetzt.
4. Auf die vier Korridorformen achten: mehrspurige Kurve, Seitengang, breiter Seitenschwung und Zickzack. Die Figur soll diese Wege sichtbar ablaufen, ohne den begehbaren Dungeon zu verlassen. Zusätzlich Positionswechsel, zeitversetzte Hinterhalte, wechselnde Ziele bei gleichwertigen Gegnern und automatische Fähigkeiten beobachten. Während einer Abklingzeit soll Nyra ihr aktuelles Ziel behalten; ein bereiter Angriff darf nicht warten, bis ein Positionswechsel abgeschlossen ist.
5. Eine laufende Expedition pausieren, das Spiel schließen und erneut öffnen. Prüfen, ob der Kampf an seinem Speicherpunkt weitergeht. Zusätzlich einen Lauf überspringen und den Offline-Bericht kontrollieren.
6. Beute nach Qualität, Stufe und Werten sortieren. Ausrüstung anlegen oder verkaufen und auf Gold, Inventar und angezeigte Werte achten.
7. Querformat, Textgröße, Reduced Motion und Energiesparoptionen auf dem eigenen Gerät prüfen.

Die ersten vier Punkte dauern nur wenige Minuten. Der Force-Stop- und Offline-Test ist besonders wichtig, weil ein erfolgreicher Desktop-Simulationstest die Android-Prozesswiederherstellung nicht ersetzt.

## Fehlerbericht

Bitte bei einem Fehler möglichst diese Angaben festhalten:

- Gerätemodell und Android-Version
- Klasse, Dungeon-Etage und zuletzt gewählte Aktion
- genaue Schritte, die zum Problem geführt haben
- was erwartet wurde und was stattdessen geschah
- ob der Fehler nach einem Neustart erneut auftrat
- Screenshot oder Bildschirmaufnahme, wenn der Fehler sichtbar ist

Vor dem Teilen eines Spielstands den enthaltenen Backup-Code entfernen oder das Backup nicht mitsenden.

## Abdeckung und offene Punkte

Der Kandidat enthält vier seedgebundene Erkundungsrouten, Kampfbewegung, sichtbare Hinterhalte und reproduzierbare Zielwechsel zwischen ähnlich wichtigen Gegnern. Regression, APK-Signatur und Manifestprüfung stehen im [0.38-Prüfprotokoll](audit/2026-09-29/seeded-target-choice-0.38.md). Eine Installation auf echten Android-Geräten, der manuelle Touchtest, ein Google-Play-AAB und ein gemeinsamer Online-Dungeon sind noch nicht belegt. Dieses Dokument ist eine Testanleitung, keine Freigabe zur Veröffentlichung.
