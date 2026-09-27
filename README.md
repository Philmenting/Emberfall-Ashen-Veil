# Emberfall: Ashen Veil

**Emberfall: Ashen Veil** ist ein eigenständiger, im Querformat gestalteter Godot-Prototyp für ein düsteres Idle-Action-RPG. Gegner haben eigene Lebensleisten; Nyra kämpft in automatischen Schlägen bis ein Gegner fällt. Alle zehn Etagen wechselt die Kampagne Gebiet, Dungeon-Namen und Boss: vom Hollow Spire bis zur Last Ember Citadel. Ein Boss-Sieg garantiert mindestens ein seltenes Ausrüstungsteil und schaltet sofort die nächste Etage frei. Vowkeeper, Arcanist und Ranger haben unterschiedliche Kampfvorteile; Attribute stärken ihre Werte und Klassenfähigkeiten. Die vier Gebiete besitzen eigene Materialien, Architekturdetails, Umgebungen und Bossmerkmale; die begehbare Route bleibt gemeinsam. Sechs Ausrüstungsslots, fünf Qualitäten und Stufen T1–T10 bilden die Beute-Progression. Angelegte Ausrüstung kann beim Schmied bis +5 verstärkt werden.

## Einstieg, Ausrüstung und Farm-Prognosen (0.6)

Neue Spielstände beginnen mit einer Klassenwahl und einer kurzen Erklärung des automatischen Spielablaufs. Bestehende Spielstände werden direkt fortgesetzt. Die Armory besitzt eigene Reiter für Tasche, angelegte Ausrüstung sowie Klasse und Attribute. Beim Klassenwechsel werden verteilte Attributpunkte vollständig zurückgegeben; eine kostenlose Rückgabe ist auch manuell möglich.

Gegenstände zeigen die tatsächlichen Änderungen für die aktuelle Klasse: Angriff, Fähigkeitenschaden, Leben, Rüstung, Mana und kritische Trefferchance. Erhöht ein Gegenstand den Fähigkeitsrang, wird auch der zusätzliche Mana-Verbrauch pro Einsatz angezeigt. Die Krit-Chance ist auf die tatsächlich wirksamen 100 Prozent begrenzt.

Im Lager werden Dungeon und gewählte Farm-Etage mit allen 64 Kampfmustern der aktuellen Ausrüstung bewertet. Die Prüfung läuft in kleinen Portionen, lässt die Oberfläche bedienbar und verbraucht keine Spielzeit, Laufnummern oder Beute. Die Anzeige zeigt Erfolgsrate und Dauer; für AFK wird die Mindestdauer von 30 Sekunden pro abgerechnetem Lauf berücksichtigt. Werte gelten bei unveränderter Klasse/Ausrüstung und ersetzen die frühere pauschale Kampfpunkt-Empfehlung. Offline-Ergebnisse stehen bei der Rückkehr oben im Lager.

## Vier Gebiete (0.5)

- **Hollow Spire:** kalter Stein, verfallene Bögen, Banner und eine geborstene Glocke über dem Heiligtum.
- **Sunken Archive:** überflutete Umgebung, feuchter Stein, verfallene Bücherregale und türkisfarbene Geisterlichter. Der Silt Abbot trägt eine hohe Mitra und eine lange Robe.
- **Crow Ossuary:** offene Knochenbögen, schwarze Kristalle, Knochenfelder und violettes Licht. Die Mourning Queen trägt eine gezackte Krone und knöcherne Schulterfortsätze.
- **Last Ember Citadel:** dunkle Lava, Öfen, Gitter und Ketten. Der Cinder Sovereign trägt eine glühende Brustplatte und Ofenschlote.

Gegnernamen und Farben folgen dem Gebiet. Der automatische Kampf bleibt dieselbe verifizierte Simulation. Wiederholte statische Quader, Kugeln, Zylinder und Ringe werden pro Raum und Material gebündelt, damit die zusätzlichen Details weniger Zeichenaufrufe benötigen. Starre Teile der Figuren werden innerhalb ihrer beweglichen Gelenke zu gemeinsamen Meshes zusammengeführt. Wasser und Lava sind eigene animierte Godot-Shader. Alle Modelle und Materialien sind im Projekt erstellt.

## Verlässliche Wiederaufnahme (0.4.1)

- Ein laufender Dungeon wird einschließlich Positionen, Gegner-Leben, Mana, Fähigkeiten, Ausweichbewegung und Zufallszustand gespeichert. Auch Pause und Wiederholung bleiben nach einem Neustart erhalten.
- Bei aktivem Offline-Farmen wird zuerst der bereits laufende Kampf um die verstrichene Zeit fortgesetzt. Erst anschließend werden weitere Farm-Läufe berechnet. Ein pausierter Lauf bleibt pausiert.
- Zwei Speicherdateien wechseln sich ab. Jede Generation wird vor der Übernahme geprüft und atomar ersetzt. Bei einer beschädigten Datei wird der vorherige gültige Checkpoint geladen und ein Hinweis angezeigt. Sind beide Dateien unlesbar oder gehört ein Stand zu einer neueren Version, bleiben die Dateien erhalten und Schreibzugriffe werden gesperrt.
- Alte Spielstände werden übernommen; die ursprüngliche Datei bleibt als zusätzliche Sicherung erhalten. Ohne Server sind Gerätewechsel, Neuinstallation und Manipulationsschutz nicht abgesichert.
- Beim abrupten Prozessabbruch kann höchstens der letzte Checkpoint (normalerweise bis zu fünf Sekunden) fehlen. Mit aktiviertem AFK-Farmen wird diese Zeit nachgerechnet. Reguläres Wechseln in den Hintergrund speichert sofort.

## Automatische Gruppenkämpfe und Farmen (0.4)

- **Sechs Gegnergruppen / 18 Gegner:** schnelle Nahkämpfer, Schildträger, Hexer, ein Elitehauptmann und ein Boss mit Begleitern. Hexer wirken unterbrechbare Bodenzauber, Schildträger reduzieren physischen Schaden, der Boss kündigt Flächenangriffe an.
- **Vowkeeper:** bindet Gegner im Nahkampf, trifft mehrere Ziele mit Ember Oath, heilt sich und erhält kurzzeitig Guard.
- **Arcanist:** wählt Gegneransammlungen für Veil Nova, verursacht Flächenschaden, verlangsamt und unterbricht Hexer.
- **Ranger:** priorisiert Hexer, weicht bei zu geringer Distanz zurück und nutzt Cinder Volley gegen mehrere Ziele. Alle Klassen versuchen angekündigten Bodenangriffen auszuweichen; dafür gilt eine Abklingzeit.
- Mana und Abklingzeiten begrenzen Fähigkeiten. Das HUD zeigt das aktuelle Ziel, verbleibende Gegner und die Abklingzeit der Klassenfähigkeit.

### Farmgebiet und Wiederholung

Im Lager die **Farm Floor** mit **− / +** auswählen und **Start Auto Farm** starten. Höhere Farm-Etagen müssen zuerst freigeschaltet werden. **Repeat: On/Off** im Dungeon schaltet die Wiederholung der aktuellen Etage um. Bei Erfolg wird Beute eingesammelt und derselbe Dungeon erneut gestartet; bei einer Niederlage endet die sichtbare Wiederholung. **Skip to Loot** beendet die Wiederholung und öffnet die Beuteansicht.

Offline wird die gewählte Farm-Etage wiederholt. Die Berechnung verwendet die ausgerüsteten Werte, tatsächliche Kampfdauer und dieselben Angriffs-/Ausweichregeln wie beim Zuschauen. Überfordernde Etagen werden nicht mehr über eine pauschale Zufalls-Erfolgschance freigeschaltet. Beide Modi garantieren bei einem Boss-Sieg mindestens seltene Beute. Volle Taschen verkaufen weitere Funde; Gold und XP aus AFK-Läufen werden im Bericht abgeholt.

Die Kampfsimulation ist bei gleichen Werten, Etage und Startwert reproduzierbar. 64 wiederkehrende Würfelmuster erlauben das Zwischenspeichern identischer Kämpfe innerhalb einer AFK-Berechnung, ohne das Ergebnis zu schätzen. Beute nutzt weiterhin den individuellen Startwert jedes Laufs. Etagenwahl, Laufzähler, Zeitrest und ausstehende Belohnungen werden gespeichert; höchstens 24 Stunden werden berechnet.

## 3D-Dungeon (0.3)

Im Lager **Descend to Floor** oder auf der Weltkarte **Enter Dungeon** wählen. Die Figur läuft sichtbar durch einen zusammenhängenden 3D-Dungeon. Die schräge Kamera folgt ihr durch sechs Begegnungen, über eine Brücke bis zum Boss. Ausrüstung, Klassenwerte, Schadensberechnung und Beute bleiben Teil des bestehenden Spielmodells.

- Vollbild-Spielwelt mit darüberliegender Lebens-/Manaleiste, Fortschritt, Pause und Überspringen.
- Automatische Zustände: Laufen → Angriff in Waffenreichweite → Gegner fällt → nächster Abschnitt. Die feste Kampfsimulation löst Angriffe und ihre Animationskontakte aus.
- Selbst gebaute Godot-Modelle mit artikulierten Armen/Beinen, Mantelbewegung, Schwert/Schild, Stab oder Bogen; sichtbare Trefferzahlen und Klasseneffekte.
- Originale prozedurale Steinmaterialien, Säulen, Sarkophage, Banner, Fackelbeleuchtung, Schatten und Distanznebel. Keine Assets aus Diablo oder dem Referenzvideo.
- Kurzes Wechseln in den Hintergrund erhält die Szene und setzt denselben Kampf fort; sobald dieser während der Abwesenheit endet, zeigt das Lager den Offline-Bericht. Doppelte Resume-Ereignisse vergeben keine zusätzlichen Belohnungen.

**Aktueller Umfang:** ein lokaler 3D-Prototyp mit einer gemeinsamen Dungeon-Route. Modelle und Animationen sind vorläufig, die Gegner verwenden einen gemeinsamen Grundkörper mit unterschiedlichen Proportionen, Waffen und Rollen. Es gibt noch keinen Mehrspieler-Server. Die Gestaltung bleibt bewusst eigenständig und stilisiert. Die Offline-Berechnung nutzt dieselbe Kampfsimulation wie die sichtbaren Läufe.

## Starten

Das Projekt mit Godot 4.7.2 öffnen und `Main.tscn` starten. Die Spielfläche ist fest auf Querformat ausgelegt. Der erste Spielstand beginnt mit Nyra auf Stufe 1 und einer Auswahl zwischen allen drei Klassen.

### Android-Test- und Beta-Build

Das Exportprofil `Android Debug` erstellt eine installierbare Test-APK für ARM64 unter `build/emberfall-debug.apk`. Das Profil `Google Play Beta` baut ein AAB mit Android API 36, ARM64 und Version `0.6.0-beta.1` unter `build/emberfall-beta-debug.aab`. Es verwendet Godots Gradle-Build-Vorlage mit Android Gradle Plugin 8.10.1; für den Export werden OpenJDK 17, Android SDK Platform 36 und Build-Tools 36.1.0 benötigt. Die tatsächliche Annahme und Veröffentlichung muss anschließend in der Play Console geprüft werden.

GitHub Actions baut beide Testpakete bei Änderungen am Projekt und stellt sie als Workflow-Artefakt bereit. Die CI-Artefakte dienen zur technischen Prüfung und sind keine freigegebene Play-Veröffentlichung. Vor dem Upload in die Play Console muss `Google Play Beta` mit einem privaten Upload-Schlüssel als Release exportiert werden. Der Schlüssel gehört weder ins Repository noch in den Debug-Build.

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
XDG_DATA_HOME=/tmp/emberfall-persistence-data godot --headless --path . --fixed-fps 60 --script tests/persistence_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-regions-data godot --headless --path . --fixed-fps 60 --script tests/regions_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-gear-data godot --headless --path . --fixed-fps 60 --script tests/gear_forecast_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-onboarding-data godot --headless --path . --fixed-fps 60 --script tests/onboarding_smoke.gd
```

Die Prüfung deckt alle drei Klassen, Bewegung, Reichweite, Pause, Bossabschluss, Beute, Überspringen, Niederlage und Hintergrundwechsel ab. `tests/android_preview.tscn` ist ein separater Test-Einstieg: startet automatisch einen frischen Lauf und speichert nach 2/12/25/40/58/75 Sekunden sowie beim ersten angekündigten Bossangriff Screenshots unter `user://`. Nur mit einer separaten Android-Paketkennung und einem eigenen Spielstand verwenden; `Main.tscn` bleibt der normale Einstieg.

`tests/persistence_smoke.gd` prüft exakte Kampffortsetzung, Speicher-Generationen, Korruption, Migration, Pausen und einmalige AFK-Auszahlung. `tests/android_lifecycle.tscn` ist ein weiterer separater Test-Einstieg für echte Android-Prozessabbrüche. Ablauf und Nachweise stehen in [docs/PERSISTENCE.md](docs/PERSISTENCE.md).

### Technischer Aufbau

- `scripts/expedition_simulation.gd`: feste 100-ms-Schritte für Bewegung, Zielwahl, Fähigkeiten, Gegner und Ergebnisse; dieselbe Logik für sichtbar/Skip/AFK.
- `scripts/dungeon_world.gd`: zusammenhängende Welt, Kamera, Darstellung der Simulation und Effekte.
- `scripts/dungeon_actor.gd`: ursprüngliche Godot-Geometrie und Gelenkanimationen für Figuren.
- `scripts/battle_art.gd`: 3D-Viewport und Verbindung zum Spielmodell.
- `scripts/main.gd`: Klassen, Werte, HUD, Ausrüstung, Belohnungen und Speicherung.

- `scripts/save_store.gd`: versionierte, geprüfte Speichergenerationen und Legacy-Migration.

- `scripts/dungeon_theme.gd`: Gebietspaletten und Gegnernamen.
- `tests/android_regions.tscn`: separater Android-Einstieg für acht Gebiets-/Bossaufnahmen und eine kurze Bildratenmessung; kein Progressionstest.

Die kurzen Android-Vergleichsmessungen und ihre Grenzen stehen in [docs/REGIONS.md](docs/REGIONS.md).

- `scripts/farm_forecast.gd`: schrittweise, rein lesende Bewertung aller Kampfmuster für eine Etage.
- `tests/android_ux.tscn`: separater Android-Einstieg für Touch-Tests, Zustandsprotokolle und Screenshots.

Prüfablauf für den Einstieg, Ausrüstungswerte und echte Android-Toucheingaben: [docs/HERO_AND_GEAR.md](docs/HERO_AND_GEAR.md).
