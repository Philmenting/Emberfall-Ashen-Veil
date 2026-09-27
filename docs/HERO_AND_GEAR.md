# Einstieg, Ausrüstung und Farm-Einschätzung — 0.6

## Umsetzung

- Neue Spielstände wählen zwischen drei Klassen. Der Einstieg kann direkt in den ersten Dungeon oder zunächst zur Ausrüstung führen. Angefangene Klassenwahl und abgeschlossener Einstieg werden gespeichert; bestehende Spielstände werden nicht zurückgesetzt.
- Tasche, angelegte Ausrüstung und Klassenwerte haben getrennte Reiter. Beim Klassenwechsel werden verteilte Punkte erstattet; die kostenlose Neuverteilung funktioniert auch ohne Klassenwechsel.
- Gegenstände zeigen sechs tatsächlich berechnete Änderungen für die aktuelle Klasse. Ein höherer Fähigkeitsrang zeigt zusätzlich die veränderten Mana-Kosten. Der Gegenstandswert ist getrennt als ITEM angegeben.
- Das Lager bewertet alle 64 Kampfmuster für die gewählte Etage mit der aktuellen Ausrüstung. Pro Frame werden höchstens zwei Varianten simuliert; identische Anfragen teilen ihre Arbeit, Ergebnisse werden zwischengespeichert. Navigation verwirft laufende Anzeigen. Diese Berechnung verändert weder Laufzähler noch Beute.
- Die Vorhersage gilt für den aktuellen Build. AFK-Dauer verwendet dieselbe Mindestdauer von 30 Sekunden wie die Abrechnung; sichtbare Kampfdauer wird separat angezeigt. Sie berücksichtigt keine zukünftigen Ausrüstungswechsel.

## Lokale Prüfungen

209 Prüfungen bestanden: Kampfsimulation 50, Persistenz 69, Gebiete 36, Ausrüstungsvergleiche/Farm-Prognosen 35, Einstieg/Neuverteilen 19. Jede Suite verwendet einen eigenen temporären Spielstand. Die Prognose wird gegen die tatsächlichen 64 Simulationen abgeglichen, einschließlich einer zu schweren Etage.

## Android-Touchtest

API-36-Emulator, 1280 × 720, separate Paketkennung `com.philmenting.emberfallashenveil.uxtest`. Der Einstieg `tests/android_ux.tscn` protokolliert Zustand und Screenshots; Klassenwahl und Navigation wurden über echte Android-Touchereignisse ausgelöst.

1. Neuer Spielstand zeigt alle drei Klassen und beide Einstiegsaktionen.
2. Arcanist per Touch gewählt; erster Dungeon zeigt den passenden Stabkämpfer und Veil Nova.
3. Erster Lauf regulär abgeschlossen; 190 Gold und 428 XP, Ausrüstung in der Tasche.
4. Auto-Farm im Lager gestartet und nach vier Sekunden pausiert. Modell-Snapshot über zwei Sekunden unverändert: `ANDROID_UX_PAUSE_PASS`.
5. Aus dem pausierten Lauf zur Beute gesprungen: 190 Gold und 428 XP, Gesamtgold 980 nach zwei erfolgreichen Läufen. Wiederholung beendet, neue Beute mit Wertedifferenzen sichtbar.

Nachweise liegen lokal in `build/previews/android-06-*.png` und `build/reports/android-06-touch.log`. Keine GDScript-Laufzeitfehler beobachtet; der Emulator meldete einmal eine Neuberechnung eines Shader-Caches. Dies ist kein Test auf einem physischen Android-Gerät.
