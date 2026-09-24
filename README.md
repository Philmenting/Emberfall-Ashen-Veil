# Emberfall: Ashen Veil

**Emberfall: Ashen Veil** ist ein eigenständiger, im Querformat gestalteter Godot-Prototyp für ein düsteres Idle-Action-RPG. Gegner haben eigene Lebensleisten; Nyra kämpft in automatischen Schlägen bis ein Gegner fällt. Alle zehn Etagen führt die Kampagne in ein neues Gebiet mit eigenem Dungeon, Umgebung und Boss: vom Hollow Spire bis zur Last Ember Citadel. Ein Boss-Sieg garantiert mindestens ein seltenes Ausrüstungsteil und schaltet sofort die nächste Etage frei. Vowkeeper, Arcanist und Ranger haben unterschiedliche Kampfvorteile; Attribute stärken ihre Werte und Klassenfähigkeiten. Sechs Ausrüstungsslots, fünf Qualitäten und Stufen T1–T10 bilden die Beute-Progression. Angelegte Ausrüstung kann beim Schmied bis +5 verstärkt werden.

## Starten

Das Projekt mit Godot 4.7.2 öffnen und `Main.tscn` starten. Die Spielfläche ist fest auf Querformat ausgelegt. Der erste Spielstand beginnt mit Nyra, Stufe 1 und dem Vowkeeper; beim ersten Lauf kann die Klasse gewechselt werden.

### Android-Debug-Build

Das Exportprofil `Android Debug` erstellt eine signierte Test-APK für ARM64 unter `build/emberfall-debug.apk`. Godot 4.7.2, die passende Android-Exportvorlage, OpenJDK 17 und Android SDK Platform 35 / Build-Tools 35.0.1 werden für einen lokalen Export benötigt. Im Repository baut GitHub Actions die APK automatisch bei Änderungen am Projekt und stellt sie als Workflow-Artefakt zum Herunterladen bereit.

Die APK ist ein lokaler Spielprototyp. Für den Google Play Store wäre später ein Release-Build mit eigener Signatur nötig.

## Steuerung im Prototyp

- **Lager**: Figur ansehen und den nächsten Dungeon beginnen.
- **Ausrüstung**: zwischen Vowkeeper, Arcanist und Ranger wechseln, Attributpunkte verteilen und Gegenstände anlegen oder verkaufen.
- **Weltkarte**: den Dungeonlauf beobachten oder direkt bis zur Beute vorspulen.

Ein Lauf kann jederzeit abgeschlossen oder übersprungen werden. Im Hintergrund wird kein dauerhaft laufender Prozess benötigt: beim nächsten Start rechnet das Spiel bis zu 24 Stunden Fortschritt aus dem gespeicherten Zeitpunkt nach.

Der erste Prototyp spielt sich allein und lokal. Godot speichert den letzten Zeitpunkt und simuliert beim erneuten Öffnen abgeschlossene Läufe samt Etagenfortschritt, Gold, Erfahrung und Ausrüstung. Beute über dem Inventarlimit wird automatisch verkauft.
