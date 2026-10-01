# Seedgebundene Zielwahl 0.38

## Änderung

Neue Expeditionen wählen bei einem bereiten Angriff seedgebunden zwischen Gegnern, deren taktische Priorität höchstens zehn Punkte auseinanderliegt. Klassengewichtungen bleiben aktiv; der Ranger priorisiert weiter Hexer, und der Arcanist bevorzugt Gruppen, die sich mit Flächenangriffen treffen lassen. Nyra behält ein gewähltes Ziel während der Abklingzeit und solange sie erst in Angriffsreichweite laufen muss. Die Wahl nutzt den bereits gespeicherten Expeditions-RNG-Zustand. Zuschauen, Skip, Wiederaufnahme und AFK erhalten deshalb dieselbe Entscheidung.

Der Schalter `auto_target_variance=1` wird nur für neu erstellte Expeditionen gesetzt. Bereits gespeicherte Checkpoints ohne dieses Feld behalten das frühere Zielverhalten. Die Änderung verändert weder Gegnerzahl noch Beute oder Kampfwerte.

## Regression

- `tests/dungeon_smoke.gd`: **55 Checks, 0 Fehler**. Die Suite prüft die Zufallsvariation für alle drei Klassen über 24 Seeds, wiederholt eine Entscheidung mit identischem RNG-Zustand und kontrolliert den Zielfokus während der Abklingzeit.
- Vollständige Regression: **17 Godot-Suites, 1.199 Checks, 0 Fehler**.
- Node-Syntax und `progression_runtime_test.js`: bestanden.
- Reise / Speicherung / Dungeon-AFK: **413 / 89 / 55 Checks**, zusammen 557.

Die automatischen Simulationen belegen reproduzierbare Entscheidungen und bestehende Live-/Skip-Parität. Sie ersetzen keine längeren menschlichen Spielsitzungen oder den Android-Gerätetest.

## Farm-Balance-Stichprobe

Je zwei deterministische 480-Läufe pro Klasse vergleichen die Standardausrüstung in 0.37 und 0.38 mit den Profil-Seeds 1979 und 2043. Die Farmtiefe blieb in beiden Seeds nah am bisherigen Stand:

| Klasse | Seed 1979: 0.37 → 0.38 | Seed 2043: 0.37 → 0.38 |
|---|---:|---:|
| Vowkeeper | 79 → 82 | 91 → 91 |
| Arcanist | 96 → 93 | 94 → 96 |
| Ranger | 79 → 74 | 96 → 93 |

Alle sechs 0.38-Läufe beendeten 478–480 von 480 Dungeons erfolgreich. Das ist eine begrenzte Bot-Stichprobe, kein Nachweis für die Balance aller Spielstile; sie zeigt aber keine wiederholte starke Verschiebung einer einzelnen Klasse durch die Zielwahl.

## Android-Testartefakt

| Angabe | Wert |
|---|---|
| Version | `0.38.0-beta.1` (Code 42) |
| APK | `build/emberfall-038-closed-beta.apk` |
| Architektur | ARM64 (`arm64-v8a`) |
| Android | API 24–36 |
| Ausrichtung | Querformat |
| Berechtigung | Keine Internetberechtigung |
| APK-SHA-256 | `22856159add93a84c3a2745737591474b7c38f9fed53e2c38ae35b244b511e26` |
| Testpaket | `build/emberfall-0.38.0-beta.1-test-package.zip` |
| Testpaket-SHA-256 | `992fb076656891373be08cbf6337abe604006306dd51bd42ffe6775052a105d0` |

Der lokale Export wurde mit APK Signature v2 und v3 verifiziert. Der Manifestprüfer bestätigt Paketname, Versionscode/-name, API-Untergrenze/-ziel, Querformat und fehlende Internetberechtigung. Der Android-Export konnte ADB in dieser Sandbox nicht erreichen; es wurde daher keine Geräteinstallation behauptet.

## Offen

- Installation und Touch-/Kampfprüfung auf einem Android-Gerät.
- Release-signiertes Google-Play-AAB und Store-Prüfung. Ein vorheriger Gradle-Exportversuch stoppte bereits vor dem Build, weil die isolierte Umgebung keine verwendbare Wildcard-IP ermitteln konnte.
- Das Offline-Closed-Beta-Profil bleibt lokal/solo. Ein öffentlicher Server, verknüpfter Online-Charakter und gemeinsame Dungeon-Kämpfe sind nicht Teil dieses Kandidaten.
- Es wurde nichts in Google Play veröffentlicht.

Am 29. September wurde zusätzlich `./gradlew --offline --no-daemon help` im exportierten Godot-Android-Projekt versucht. Gradle startete trotz `--no-daemon` einen Einmal-Daemon und konnte dessen TCP-Listener nicht öffnen (`TcpIncomingConnector.accept`: `java.net.SocketException: Operation not permitted`). Es entstand kein AAB. Das ist ein Sandbox-Socketlimit; APK-Export und Prüfsignatur funktionieren weiterhin.
