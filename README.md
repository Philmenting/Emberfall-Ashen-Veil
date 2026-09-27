# Emberfall: Ashen Veil

**Emberfall: Ashen Veil** ist ein eigenständiger, im Querformat gestalteter Godot-Prototyp für ein düsteres Idle-Action-RPG. Gegner haben eigene Lebensleisten; Nyra kämpft in automatischen Schlägen bis ein Gegner fällt. Alle zehn Etagen wechselt die Kampagne Gebiet, Dungeon-Namen und Boss: vom Hollow Spire bis zur Last Ember Citadel. Ein Boss-Sieg garantiert mindestens ein seltenes Ausrüstungsteil und schaltet sofort die nächste Etage frei. Vowkeeper, Arcanist und Ranger haben unterschiedliche Kampfvorteile; Attribute stärken ihre Werte und Klassenfähigkeiten. Die Gebiete verwenden vorerst dieselbe 3D-Dungeon-Geometrie. Sechs Ausrüstungsslots, fünf Qualitäten und Stufen T1–T10 bilden die Beute-Progression. Angelegte Ausrüstung kann beim Schmied bis +5 verstärkt werden.

## 3D-Dungeon (0.3)

Im Lager **Descend to Floor** oder auf der Weltkarte **Enter Dungeon** wählen. Die Figur läuft sichtbar durch einen zusammenhängenden 3D-Dungeon. Die schräge Kamera folgt ihr durch sechs Begegnungen, über eine Brücke bis zum Boss. Ausrüstung, Klassenwerte, Schadensberechnung und Beute bleiben Teil des bestehenden Spielmodells.

- Vollbild-Spielwelt mit darüberliegender Lebens-/Manaleiste, Fortschritt, Pause und Überspringen.
- Automatische Zustände: Laufen → Angriff in Waffenreichweite → Gegner fällt → nächster Abschnitt. Schaden entsteht am Animationskontakt, nicht mehr über eine unabhängige Zeitschleife.
- Selbst gebaute Godot-Modelle mit artikulierten Armen/Beinen, Mantelbewegung, Schwert/Schild, Stab oder Bogen; sichtbare Trefferzahlen und Klasseneffekte.
- Originale prozedurale Steinmaterialien, Säulen, Sarkophage, Banner, Fackelbeleuchtung, Schatten und Distanznebel. Keine Assets aus Diablo oder dem Referenzvideo.
- Kurzes Wechseln in den Hintergrund erhält die Szene; nach mindestens einem vollständigen AFK-Zeitfenster ersetzt der Offline-Bericht den laufenden Dungeon. Doppelte Resume-Ereignisse vergeben keine zusätzlichen Belohnungen.

**Aktueller Umfang:** ein lokaler 3D-Prototyp mit einer gemeinsamen Dungeon-Route. Modelle und Animationen sind vorläufig, die Gegner verwenden einen gemeinsamen Grundkörper. Es gibt noch keinen Mehrspieler-Server und keine Grafikqualität auf dem Niveau von Diablo Immortal. Die Offline-Simulation verwendet weiterhin ein vereinfachtes Erfolgsmodell.

## Starten

Das Projekt mit Godot 4.7.2 öffnen und `Main.tscn` starten. Die Spielfläche ist fest auf Querformat ausgelegt. Der erste Spielstand beginnt mit Nyra, Stufe 1 und dem Vowkeeper; beim ersten Lauf kann die Klasse gewechselt werden.

### Android-Test- und Beta-Build

Das Exportprofil `Android Debug` erstellt eine installierbare Test-APK für ARM64 unter `build/emberfall-debug.apk`. Das Profil `Google Play Beta` baut ein AAB mit Android API 36, ARM64 und Version `0.3.0-beta.1` unter `build/emberfall-beta-debug.aab`. Es verwendet Godots Gradle-Build-Vorlage mit Android Gradle Plugin 8.10.1; für den Export werden OpenJDK 17, Android SDK Platform 36 und Build-Tools 36.1.0 benötigt. Die tatsächliche Annahme und Veröffentlichung muss anschließend in der Play Console geprüft werden.

GitHub Actions baut beide Testpakete bei Änderungen am Projekt und stellt sie als Workflow-Artefakt bereit. Das AAB aus diesem Testlauf ist unsigniert und dient nur zur technischen Prüfung. Vor dem Upload in die Play Console muss `Google Play Beta` mit einem privaten Upload-Schlüssel als Release exportiert werden. Der Schlüssel gehört weder ins Repository noch in den Debug-Build.

Für den signierten Release-Export `python3 scripts/export_google_play_beta.py` ausführen. Das Skript verwendet die private Schlüsseldatei und Zugangsdaten außerhalb des Projekt-Repos im lokalen Android-Werkzeugordner und erzeugt `build/emberfall-play-beta.aab`. Das öffentliche `upload-certificate.pem` wird beim Einrichten der App-Signatur in der Play Console benötigt. Keystore und Zugangsdaten nicht hochladen oder teilen.

## Steuerung im Prototyp

- **Lager**: Figur ansehen und den nächsten Dungeon beginnen.
- **Ausrüstung**: zwischen Vowkeeper, Arcanist und Ranger wechseln, Attributpunkte verteilen und Gegenstände anlegen oder verkaufen.
- **Weltkarte**: mit „Enter Dungeon“ die sichtbare Lauf- und Kampfszene starten, Nyra durch den Gang begleiten oder direkt bis zur Beute vorspulen.

Ein Lauf kann jederzeit abgeschlossen oder übersprungen werden. Im Hintergrund wird kein dauerhaft laufender Prozess benötigt: beim nächsten Start rechnet das Spiel bis zu 24 Stunden Fortschritt aus dem gespeicherten Zeitpunkt nach.

Der erste Prototyp spielt sich allein und lokal. Godot speichert den letzten Zeitpunkt und simuliert beim erneuten Öffnen abgeschlossene Läufe samt Etagenfortschritt, Gold, Erfahrung und Ausrüstung. Beute über dem Inventarlimit wird automatisch verkauft.

## Lokale Prüfungen

Mit separatem Datenverzeichnis ausführen, damit der eigene Spielstand unangetastet bleibt:

```bash
XDG_DATA_HOME=/tmp/emberfall-smoke-data godot --headless --path . --fixed-fps 60 --script tests/dungeon_smoke.gd
```

Die Prüfung deckt alle drei Klassen, Bewegung, Reichweite, Pause, Bossabschluss, Beute, Überspringen, Niederlage und Hintergrundwechsel ab. `tests/android_preview.tscn` ist ein separater Test-Einstieg: startet automatisch einen frischen Lauf und speichert nach 2/12/25/40 Sekunden Screenshots unter `user://`. Nur mit einer separaten Android-Paketkennung und einem eigenen Spielstand verwenden; `Main.tscn` bleibt der normale Einstieg.

### Technischer Aufbau

- `scripts/dungeon_world.gd`: zusammenhängende Welt, Kamera, automatischer Bewegungs-/Kampfablauf und Effekte.
- `scripts/dungeon_actor.gd`: ursprüngliche Godot-Geometrie und Gelenkanimationen für Figuren.
- `scripts/battle_art.gd`: 3D-Viewport und Verbindung zum Spielmodell.
- `scripts/main.gd`: Klassen, Werte, HUD, Ausrüstung, Belohnungen und Speicherung.
