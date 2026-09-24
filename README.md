# Emberfall: Ashen Veil

**Emberfall: Ashen Veil** ist ein eigenständiger, im Querformat gestalteter Godot-Prototyp für ein düsteres Idle-Action-RPG. Gegner haben eigene Lebensleisten; Nyra kämpft in automatischen Schlägen bis ein Gegner fällt. Alle zehn Etagen führt die Kampagne in ein neues Gebiet mit eigenem Dungeon, Umgebung und Boss: vom Hollow Spire bis zur Last Ember Citadel. Ein Boss-Sieg garantiert mindestens ein seltenes Ausrüstungsteil und schaltet sofort die nächste Etage frei. Vowkeeper, Arcanist und Ranger haben unterschiedliche Kampfvorteile; Attribute stärken ihre Werte und Klassenfähigkeiten. Sechs Ausrüstungsslots, fünf Qualitäten und Stufen T1–T10 bilden die Beute-Progression. Angelegte Ausrüstung kann beim Schmied bis +5 verstärkt werden.

## Starten

Das Projekt mit Godot 4.3 oder neuer öffnen und `Main.tscn` starten. Die Oberfläche ist für ein Querformat-Display entworfen. Der Android-Export kann später über Godots Android-Exportvorlage und ein installiertes Android SDK ergänzt werden.

## Steuerung im Prototyp

- **Lager**: Figur ansehen und den nächsten Dungeon beginnen.
- **Ausrüstung**: zwischen Vowkeeper, Arcanist und Ranger wechseln, Attributpunkte verteilen und Gegenstände anlegen oder verkaufen.
- **Weltkarte**: den Dungeonlauf beobachten oder direkt bis zur Beute vorspulen.

Die App muss für Offline-Fortschritt nicht dauerhaft im Hintergrund laufen. Godot speichert den letzten Zeitpunkt und simuliert beim erneuten Öffnen abgeschlossene Läufe samt Etagenfortschritt, Gold, Erfahrung und Ausrüstung. Die Simulation ist auf 24 Stunden pro Abwesenheit begrenzt; Beute über dem Inventarlimit wird automatisch verkauft. Das vermeidet einen dauerhaft laufenden Android-Prozess.
