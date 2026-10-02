# Emberfall 0.41 · Fließende Animationen

Die freigegebene gemalte Bildwelt bleibt erhalten. Alle elf Figuren bewegen sich
jetzt durchgehend über Gelenke: drei Nyra-Klassen, vier Gegnertypen und vier
Wächter. Der frühere Wechsel zwischen wenigen Standbildern entfällt beim Laufen
und Angreifen.

- Schritte richten sich nach der tatsächlichen Bewegung. Das Standbein hält den
  Fuß am Boden, das andere hebt ihn an; Rückwärtsbewegung bleibt erkennbar.
- Schwert, Schild, Stab und Bogen haben eigene Abläufe für Ausholen, Kontakt und
  Rückführung. Die Bogensehne spannt sich mit der ziehenden Hand.
- Trefferreaktion, abgebrochene Angriffe und Rückzüge folgen echten Kampfereignissen.
  Wächter holen während ihres tatsächlichen Warn-Countdowns aus. Wiederhergestellte
  Warnungen und Zauber setzen an der passenden Stelle ein.
- Umhänge und Haare folgen verzögert. Besiegte Figuren knicken über 0,58 Sekunden
  ein und gehen in die vorhandene gemalte Fallpose über.
- Kamera und Projektilstart berücksichtigen die bewegten Körper und Waffen.
  Reduced Motion schaltet Umgebungsbewegung und Trefferverlagerung ab, erhält
  aber die für den Kampf notwendigen Schritte und Aktionen.

Die Kampf-Simulation wurde nicht geändert. Schaden, Cast-Zeiten, Zufallszustand,
Warnflächen, Beute und Spielstände behalten ihre bisherigen Regeln.

## Vorschauen

[Gameplay mit normaler Startausrüstung](previews/animations/emberfall-gameplay-041.mp4)
zeigt 16 Sekunden aus 480 nativ gerenderten Frames bei 30 FPS, mit der vorhandenen
Spielmusik. Schnitte lassen Reisen und Zwischenkämpfe aus; die gezeigten Kämpfe
behalten ihre tatsächliche Geschwindigkeit.

[Bewegungsprüfung aller elf Figuren](previews/animations/emberfall-motion-041.mp4)
zeigt 24 Sekunden aus 720 nativ gerenderten Frames. Dies ist eine beschriftete
Prüfbühne für Schritte, Angriffe, Rückzüge und Fallen, keine Spielszene oder Werbung.

Beide Videos sind deterministische Exporte des Godot-Renderers. Die 30 FPS sind
die Exportabtastung und kein gemessener Wert auf einem physischen Telefon.

## Prüfung und Technik

`tests/painted_animation_smoke.gd` prüft 98 Bewegungsbedingungen, einschließlich
Standfuß, kontinuierlicher Gelenkbewegung, unverzerrter Waffen, Bogen, Pause,
Reduced Motion, Unterbrechungen und 360 identischer Simulationsschritte mit und
ohne Renderer. `tests/world_framing_smoke.gd` prüft 900 Bedingungen über alle drei
Klassen, vier Wächter, drei Phasen, zwei Warnvarianten und drei Displaygrößen.
Diese Kamera-Fixtures erhöhen Lebenspunkte und Schaden, um späte Warnungen zu
erreichen und die Wächter für die geometrische Prüfung am Leben zu halten.

Die bewegte Layout-Vorschau erfasst 33 echte Szenenframes auf 2424 × 1080
(zugeklapptes Fold im Querformat), 1040 × 1080 und 854 × 480 mit großer Schrift.
Nur die späten Wächter-Fixtures verwenden zusätzliche Lebenspunkte. Das separate
Android-QA prüft vier Wächter in jeweils 20 echten Simulationsschritten,
Gelenkänderungen und vier unterschiedliche gerenderte Bilder je Region.
Der isolierte Android-Test bestätigt außerdem den systemeigenen Vollbildhinweis
vor dem Start und sichert bei Fehlern ein Diagnosebild. Damit kann ein verdeckter
Startbildschirm von einem Skript- oder Darstellungsfehler unterschieden werden.
Die bewegte Prüfung auf Android 16 hat für alle vier Wächter bestanden:
20 Gelenkänderungen und vier unterschiedliche Bilder pro Region. Der isolierte
Erststart mit Klassenrelikt, kombinierten Eiden und Neustart hat ebenfalls bestanden.
Der vollständige Offline-Test erreichte beim bisherigen Fünf-Minuten-Limit etwa
90 Prozent der Abrechnung. Deshalb erhält ausschließlich dieser CI-Aufruf auf
dem Software-Emulator 900 Sekunden; die exakte Stundenabrechnung und der
Neustart ohne doppelte Belohnungen bleiben unverändert Pflicht.
Die geprüften Android-Bilder und ihr genauer Quellstand sind im
[Android-Nachweis](audit/2026-10-02/animation-android-graphics.json) dokumentiert.

Pro lebender Figur gibt es einen gemeinsam genutzten GPU-Skin mit 23 Knochen,
zwölf gemalten Teilen und höchstens 6.000 Vertices sowie den Kontaktschatten.
Animation schreibt keine Bildpixel und baut nicht in jedem Frame neue Geometrie.
Die Herkunft der ergänzten Malereien steht in
[ASSET_PROVENANCE.md](design/ASSET_PROVENANCE.md).

## Android-Kandidat und Geräteprobe

Version: **0.41.0-beta.1, Code 47**. Die GitHub-Entwicklung liegt im bestehenden
[Entwurf PR #3](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/3).
Der passende erfolgreiche Lauf unter **Actions → Android Debug APK** enthält
`emberfall-ashen-veil-android-ci-validation-only`; darin liegt
`build/emberfall-closed-beta-ci.apk`. CI-Artefakte verwenden einen kurzlebigen
Prüfschlüssel. Für dauerhaft installierbare Updates ist der registrierte
Projektschlüssel nötig; dieser Stand wird nicht automatisch nach Google Play
veröffentlicht. Bestehende Spielstände vor einem Installationswechsel über
**Options → Save Backup** sichern.

Auf dem Pixel 9 Pro Fold im zugeklappten Querformat prüfen: drei Klassen in einem
Kampf, Wächterwarnung und Kontakt, Pause/Fortsetzung, Reduced Motion und Battery.
Insbesondere auf Standfüße, Bogensehne, Unterbrechungen, Waffen hinter dem HUD
und das Fallen achten. Reale Framerate, Wärme, Akku und Touchverhalten sind noch
nicht auf diesem Gerät gemessen.
