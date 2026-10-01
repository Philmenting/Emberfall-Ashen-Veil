# Einstieg, Ausrüstung und Farm-Einschätzung — 0.6

## Umsetzung

- Neue Spielstände wählen zwischen drei Klassen. Der Einstieg kann direkt in den ersten Dungeon oder zunächst zur Ausrüstung führen. Angefangene Klassenwahl und abgeschlossener Einstieg werden gespeichert; bestehende Spielstände werden nicht zurückgesetzt.
- Tasche, angelegte Ausrüstung und Klassenwerte haben getrennte Reiter. Beim Klassenwechsel werden verteilte Punkte erstattet; die kostenlose Neuverteilung funktioniert auch ohne Klassenwechsel.
- Gegenstände zeigen sechs tatsächlich berechnete Änderungen für die aktuelle Klasse. Ein höherer Fähigkeitsrang zeigt zusätzlich die veränderten Mana-Kosten. Der Gegenstandswert ist getrennt als ITEM angegeben.
- Das Lager bewertet alle 256 Kampfmuster für die gewählte Etage mit der aktuellen Ausrüstung. Pro Frame werden höchstens zwei Varianten simuliert; identische Anfragen teilen ihre Arbeit, Ergebnisse werden zwischengespeichert. Navigation verwirft laufende Anzeigen. Diese Berechnung verändert weder Laufzähler noch Beute.
- Die Vorhersage gilt für den aktuellen Build. AFK-Dauer verwendet dieselbe Mindestdauer von 30 Sekunden wie die Abrechnung; sichtbare Kampfdauer wird separat angezeigt. Sie berücksichtigt keine zukünftigen Ausrüstungswechsel.

## Lokale Prüfungen

209 Prüfungen bestanden: Kampfsimulation 50, Persistenz 69, Gebiete 36, Ausrüstungsvergleiche/Farm-Prognosen 35, Einstieg/Neuverteilen 19. Jede Suite verwendet einen eigenen temporären Spielstand. Die damalige Prognose wird gegen die tatsächlichen 64 Simulationen abgeglichen, einschließlich einer zu schweren Etage.

## Android-Touchtest

API-36-Emulator, 1280 × 720, separate Paketkennung `com.philmenting.emberfallashenveil.uxtest`. Der Einstieg `tests/android_ux.tscn` protokolliert Zustand und Screenshots; Klassenwahl und Navigation wurden über echte Android-Touchereignisse ausgelöst.

1. Neuer Spielstand zeigt alle drei Klassen und beide Einstiegsaktionen.
2. Arcanist per Touch gewählt; erster Dungeon zeigt den passenden Stabkämpfer und Veil Nova.
3. Erster Lauf regulär abgeschlossen; 190 Gold und 428 XP, Ausrüstung in der Tasche.
4. Auto-Farm im Lager gestartet und nach vier Sekunden pausiert. Modell-Snapshot über zwei Sekunden unverändert: `ANDROID_UX_PAUSE_PASS`.
5. Aus dem pausierten Lauf zur Beute gesprungen: 190 Gold und 428 XP, Gesamtgold 980 nach zwei erfolgreichen Läufen. Wiederholung beendet, neue Beute mit Wertedifferenzen sichtbar.

Nachweise liegen lokal in `build/previews/android-06-*.png` und `build/reports/android-06-touch.log`. Keine GDScript-Laufzeitfehler beobachtet; der Emulator meldete einmal eine Neuberechnung eines Shader-Caches. Dies ist kein Test auf einem physischen Android-Gerät.

## Android-Prüfung 0.18

Die signierte ARM64-APK `com.philmenting.emberfallashenveil.test018` wurde parallel installiert und auf dem API-36-Emulator bei 1280 × 720 per Android-Toucheingaben bedient. Drei aufeinanderfolgende Dungeonabschlüsse wurden über „Skip to Loot“ ausgewertet. Die Beuteansicht zeigte echte Gegenstände samt Vergleichswerten und den Aktionsknöpfen **Equip** und **Sell**. Ein Paar Stiefel wurde für 98 Gold verkauft; bei einem späteren Lauf wurde eine Truhe ausgerüstet. Gold, Attributwerte, Leben, Rüstung und Kampfkraft aktualisierten sich sofort. Screenshots: `build/previews/emberfall-018-run.png`, `emberfall-018-loot.png`, `emberfall-018-sold.png`, `emberfall-018-floor3-result.png` und `emberfall-018-equipped.png`.

Die Ansicht blieb bei einer temporären 854 × 480-Querformatmessung innerhalb des Bildes und ließ sich scrollen; die kleinere Auflösung macht die Schrift deutlich kleiner. Die Emulatorauflösung wurde anschließend auf 1280 × 720 zurückgesetzt. Ein Test auf echten Geräten mit unterschiedlichen Pixeldichten bleibt offen.

Ein live beobachteter 0.18-Lauf erreichte auf dem Emulator den Boss und kehrte mit zwei Relikten zurück; die 90-Sekunden-Aufnahme und die Beuteansicht stehen unter `build/previews/emberfall-018-live-floor4.mp4` und `build/previews/emberfall-018-floor4-current.png`. Der 0.18-Kaltstarttest unterbrach eine weitere laufende Expedition nach Kammer 2. Nach Prozessabbruch rechnete sie bis zum Reliquiar weiter, gab eine legendäre Waffe und Gold/XP aus und ging beim nächsten Prozessstart ins Lager, ohne doppelt auszuzahlen. Nachweise: `build/previews/emberfall-018-lifecycle-before.png`, `lifecycle-after.png`, `lifecycle-complete.png` und `no-duplicate.png`.
