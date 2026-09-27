# Gebiets-Bosse — 0.9

## Vier Angriffsmuster

| Boss | Angriff | Sichere Bereiche |
|---|---|---|
| Bell Warden | Bell Requiem: ringförmige Schockwelle um den Boss | Innerhalb des Rings oder außerhalb seiner Reichweite |
| Silt Abbot | Drowning Tide: lange Flutbahn in der beim Wirken festgelegten Richtung | Seitlich der Bahn |
| Mourning Queen | Grave Bloom: drei gleichzeitig explodierende Grabkreise | Außerhalb der drei Kreise |
| Cinder Sovereign | Furnace Cross: zwei sich kreuzende Feuerbahnen | Die diagonalen Bereiche neben dem Kreuz |

Unter 50 Prozent Leben erwacht jeder Boss einmal. Nachfolgende Spezialangriffe werden breiter, kündigen sich 1,25 statt 1,65 Sekunden an und haben eine kürzere Abklingzeit. Eine bereits begonnene Attacke verändert dabei ihre Geometrie nicht. Überschneidende Gefahrenflächen verursachen pro Auflösung nur einen Treffer.

Nyra sucht automatisch einen nahe gelegenen, begehbaren Punkt außerhalb aller aktuell angekündigten Angriffe. Die Ausweich-Abklingzeit bleibt relevant. Steht sie bereits sicher, muss sie nicht ausweichen; nach dem Ausweichen läuft sie beim Annähern nicht sofort zurück in dieselbe Bossfläche. Es gibt keine erforderliche aktive Steuerung und keine garantierte Unverwundbarkeit.

## Sichtbarkeit und Speicherung

Das Kampf-HUD nennt den Angriff und seine verbleibende Vorwarnzeit bzw. die verstärkte Bossphase. Die Weltkarte beschreibt das Muster des nächsten Gebiets, die Hilfe erklärt die sicheren Bereiche. Warnungen bleiben auch bei abgeschalteten Schadenszahlen sichtbar.

`scripts/boss_patterns.gd` definiert die Geometrie für Treffer, Ausweichen und sichtbare Flächen. Ringflächen lassen ihre sichere Mitte frei. Die Umrisse der Bosswarnungen werden nicht während des Wirkens skaliert. Ein wiederaufgenommener Spielstand stellt das konkrete Muster samt Richtung, Restzeit und Bossphase wieder her. Alte Expeditionen ohne den neuen Regelwert behalten die bisherigen Kreisangriffe; neue Läufe verwenden die Gebietsmuster.

Die begehbare Route und die sechs Gegnergruppen bleiben gemeinsam. Dies ergänzt unterschiedliche Bossmechaniken, noch keine vier unterschiedlichen Dungeon-Grundrisse.

## Automatisierte Nachweise

Die acht lokalen Suiten enthalten 380 Prüfungen. 85 davon betreffen Bosse:

- Geometrie und sichere Bereiche aller vier Angriffe, Schaden bei fehlendem Ausweichen, keine doppelten Treffer an Überschneidungen.
- Automatisches Ausweichen, einmaliger Phasenwechsel, kürzere Vorwarnzeit und stärkere Folgeangriffe.
- Exaktes Speichern während eines Angriffs, identische Fortsetzung, Zurückweisung ungültiger Geometrie.
- Alle 64 Kampfmuster mit drei Klassen in vier Gebieten: 768 vollständige Vergleiche zwischen unterschiedlich getaktetem Zuschauen und Überspringen. Dies ist eine Prüfung gleicher Regeln, kein Nachweis ausgeglichener Schwierigkeit.
- Zwölf gespeicherte Ergebnishashes aus dem unveränderten 0.8-Simulator prüfen die Kompatibilität alter Bosskämpfe unabhängig von der neuen Implementierung.
- Wiederhergestellte 3D-Flächen, Angriffsbezeichnung im HUD und eingefrorene Pausenzustände.

```bash
XDG_DATA_HOME=/tmp/emberfall-boss-tests godot --headless --path . --fixed-fps 60 --script tests/boss_patterns_smoke.gd
```

Die ältere Dungeon-Prüfung kontrolliert Ausweichen jetzt bei einer ausdrücklich gesetzten Bedrohung. Eine bloße Zahl von Ausweichbewegungen in einem gewonnenen Lauf wäre für den sicheren Innenbereich eines Rings keine sinnvolle Anforderung. Der Waffenvergleich verlangt einen schnelleren Sieg mit mehr Restleben; ein Sieg der schwächeren Variante ist kein Fehler.

`tests/android_bosses.tscn` zeigt mit eigener Paketkennung alle vier normalen und vier erwachten Muster. Für diese reine Darstellungsprüfung springt die Figur zum Boss und erhält viel Leben; sie belegt keinen erspielten Etagenfortschritt. Normale Spielpakete schließen sämtliche Tests aus.

Auf Android API 36 bei 1280 × 720 wurden alle acht Warnungen und acht darauf folgenden automatischen Ausweichbewegungen erfasst. Die normalen Warnungen zeigen 1,6 Sekunden im HUD, die erwachten 1,2 Sekunden. Das Protokoll enthält `ANDROID_BOSSES_DONE` und keine Skriptfehler. Bilder und Protokoll liegen lokal unter `build/previews/android-09-boss-*.png` und `build/reports/android-09-bosses.log`.

Die erneute Untersuchung mit 480 Läufen je Klasse erreicht Etage 93 beim Vowkeeper, 54 beim Arcanisten und 91 beim Ranger. Der Arcanist verzeichnet sechs Niederlagen, die anderen keine. Die Untersuchung verwendet dieselbe einfache Bot-Strategie wie 0.8, einschließlich nur 16 Mustern für die Etagenwahl. Neue Muster sind somit funktional geprüft; der bestehende langfristige Klassenabstand bleibt offen.
