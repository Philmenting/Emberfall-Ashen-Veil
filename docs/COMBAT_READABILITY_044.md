# Kampflesbarkeit · 0.44.0-beta.1

Die vollständig animierten 3D-Figuren aus 0.43 bleiben die Grundlage. Dieser
Ausbau macht den automatischen Kampf nachvollziehbarer und die Vorbereitung
im laufenden Spiel komfortabler.

- Die Signatur und tatsächlich ausgerüsteten Techniken zeigen **CASTING**,
  Restabklingzeit, **LOW MANA** oder **READY**. Die Werte kommen aus der
  eingefrorenen Expedition, einschließlich Schwüren und Set-Boni. Alte
  Checkpoints ohne Techniken zeigen nur ihre Signatur. „Bereit“ bedeutet genug
  Mana und keine Abklingzeit; Ziel, Reichweite und Einsatzbedingungen gelten weiter.
- Antippen einer Fähigkeit zeigt ihre Regel in **Details**. Der Kampf pausiert
  sofort; Schließen und Android-Zurück stellen den vorherigen Zustand wieder
  her. **Resume** setzt ausdrücklich fort. Optionen, Größenwechsel und ein
  Neustart verlieren weder den Checkpoint noch die vorherige manuelle Pause.
  Im Hintergrund folgt AFK dem Laufzustand vor der Lesepause; Wiederaufnahme
  und vollständiger Neustart berechnen dadurch denselben Fortschritt.
- Lebenspunkte ändern sich sofort. Ein kurzer bronzener Nachlauf zeigt den
  gerade verlorenen Anteil. Heilung entfernt den alten Nachlauf; Reduced Motion
  schaltet dessen Bewegung aus. Guard zeigt seine echte Restdauer, Mana Ward
  den aktiven Schutz oder das Erreichen der Manareserve.
- Kammerfortschritt und aktuelles Ziel bleiben sichtbar. Noch nicht erschienene
  Verstärkungen zählen zu den verbleibenden Gegnern. Nach dem Wächter muss die
  Reliquie weiterhin eingesammelt werden.

Die Kamera reserviert die tatsächlich berechnete Höhe der Leiste. Noch nicht
angeordnete UI-Elemente dürfen keine extreme Verkleinerung der Szene auslösen.
Die Zielzeile behält ihre Höhe, sodass wechselnder Text keine Kamerafahrt
verursacht. Die bestehenden Prüfungen projizieren jetzt alle Wächterphasen,
Warnungsumrisse und ausgestreckten Figuren über diese strengere Unterkante.
Treffer und Zielwechsel erzeugen weiterhin keine Kameraerschütterung.

## Nachweise

Die [native Aufnahme](previews/combat-readability/emberfall-combat-044.mp4)
zeigt zwölf Sekunden mit normaler Arcanist-Startausrüstung. Sekunden 5–8 sind
die tatsächliche Lesepause. Der Film ist ein mit 30 Bildern pro Sekunde
gerenderter Godot-Export ohne nachträglich beschleunigte Kampfsimulation und
ohne Tonspur; er misst keine Geräte-Bildrate.

Die [27 Ansichten](previews/combat-readability/) decken 2424×1080, 1040×1080
und 854×480 mit Large Text ab: alle drei Klassen, Lesepause, Manareserve und
alle vier Wächter. Wächterbilder erhöhen ausschließlich Life, um die
Warnungsgeometrie sicher zu erreichen; sie belegen keine Klassenbalance.
Herkunft und Prüfsummen stehen in `provenance.json` im selben Ordner.
Der [abschließende Review](design/combat-readability-review-044.md) bewertet
die Erweiterung mit **ship**. Er umfasst die 27 Ansichten und sieben Zeitpunkte
des Videos; die Bilder innerhalb der Lesepause sind identisch.

`tests/combat_readability_smoke.gd` prüft die echten Zustände, unveränderte
Live-/Skip-Ergebnisse und Zufallsfolgen, Lesepause und verschachtelte Optionen,
manuelle Pause, Neustart, Touchgrößen, Schrift, Kamerafreiraum und Lebensfeedback.
Androids normaler Erstspielablauf prüft zusätzlich Antippen, Lesepause und
Zurück-Fortsetzung vor Beute, Ausrüsten und erneutem App-Start.

Aktuelle CI-Ergebnisse und die APK für genau den geprüften Commit stehen in
[PR 5](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5). Der Testbuild
verwendet einen temporären CI-Schlüssel. Google Play wurde nicht veröffentlicht.
Leistung, Wärme, Akkulaufzeit und Bedienung auf einem physischen Pixel Fold
bleiben außerhalb der Emulator- und Rendering-Nachweise.

```sh
GODOT_BIN=/path/to/godot-4.7.2 python3 scripts/run_beta_checks.py
godot --path . tests/combat_readability_preview.tscn -- --capture-dir=/tmp/readouts
godot --path . --fixed-fps 30 tests/combat_readability_preview.tscn -- --video --capture-dir=/tmp/readout-clip
```
