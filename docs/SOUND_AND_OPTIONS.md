# Ton und Optionen — 0.7

## Umsetzung

Die Hintergrundklänge und 12 Effektarten entstehen als originale PCM-Samples in Godot: Lager/Dungeon, Menütipp, Schwertschwung, Projektil, Treffer, erlittener Treffer, drei Klassenfähigkeiten, Warnung, Ausweichen, Sieg und Niederlage. Die Musik ist eine kurze atmosphärische Schleife. Es werden keine fremden Aufnahmen verwendet. Es handelt sich noch nicht um einen auskomponierten Soundtrack.

- Je ein Regler für Gesamtlautstärke, Musik und Effekte. Null stoppt Effekte und pausiert Musik vollständig. Hintergrundwechsel pausiert den Ton; bei der Rückkehr werden keine verpassten Treffer nachgespielt.
- Höchstens sechs Effektstimmen, begrenzte Pegel und eine kurze Sperre für gleichzeitig eintreffende Mehrfachtreffer. Die Kampfsimulation selbst erzeugt keinen Ton; Prognosen und AFK-Berechnungen bleiben stumm.
- Balanced: Ziel 60 FPS, normale 3D-Auflösung, Schatten und 2× MSAA. Battery: Ziel 30 FPS, halbe Breite/Höhe der 3D-Fläche, keine Schatten und kein MSAA. Oberfläche und Kampfsimulation behalten ihre Auflösung bzw. festen Zeitschritte. Erreichbare FPS und reale Akkulaufzeit hängen vom Gerät ab.
- Schadenszahlen lassen sich ausblenden. Gefahrenzonen und Lebensleisten bleiben sichtbar.
- **Reduced Motion** nimmt den Boss-Zoom und die kurzen Impulse bei schweren Treffern heraus. Die Kamera folgt der automatischen Route weiter, damit Ziel und Charakter im Bild bleiben.
- Optionen öffnen im Dungeon eine Pause. Schließen setzt nur einen zuvor aktiven Lauf fort. Ein manuell pausierter Lauf bleibt pausiert. Android Back und Escape öffnen/schließen dieses Menü; aus Ausrüstung, Karte und Beute geht Back zum Lager.
- Einstellungen liegen in denselben geprüften Speichergenerationen wie die Spielfigur. Ungültige Werte werden normalisiert. Save & Exit speichert zuerst und erhält den Zustand vor der vorübergehenden Menüpause; ein fehlgeschlagener Speichervorgang verhindert das Beenden.
- How to Play erklärt Klassenwerte, Ausrüstungsvergleich, Farm-Einschätzung, Offline-Bericht und lokale Speicherung.

## Nachweise

Die lokale Suite umfasst bisher 266 bestandene Prüfungen; davon 57 zu Audio, Einstellungen und Navigation. Sie prüft alle generierten Sample-Daten, ruhige Sample-Ränder, Grenzen und Caching, getrennte Lautstärken, persistente Optionen, unveränderte Kampfzustände und Darstellungseinstellungen.

Die aktuelle Options-Suite besteht aus **73 Checks mit 0 Fehlern**. Vier neue Prüfungen decken Reduced Motion, die Übergabe an die 3D-Szene und die persistente Option ab.

Zusätzlicher nativer Mixertest unter PulseAudio: Effektvorschau mit Spitzenwert 0,15133; Gesamtlautstärke null liefert exakt 0,0. Dies ist eine technische Pegelprüfung, keine subjektive Klangbewertung. Android API 36, 1280 × 720, separates Testpaket: Optionsmenü mit Back geöffnet/geschlossen, Master per Touch auf null gesetzt, Battery-Modus gewählt und anschließend einen Dungeon über Back pausiert. Der Android-Mixer meldet bei Master null exakt 0,0; der Kampfzustand bleibt über zwei Sekunden unverändert (`ANDROID_OPTIONS_PAUSE_PASS`). Save & Exit beendete den Android-Prozess; der nächste Start erhielt Master null, Battery-Modus und den zuvor aktiven Lauf. Erneutes Back pausierte den wiederaufgenommenen Kampf ebenfalls unverändert. Eine doppelte Zustellung derselben Android-Zurück-Taste innerhalb eines Frames wurde im Emulator nachgewiesen und wird vom Spiel einmalig verarbeitet.

## Reproduzieren

```bash
XDG_DATA_HOME=/tmp/emberfall-options-data godot --headless --path . --fixed-fps 60 --script tests/options_smoke.gd
```

`tests/android_options.tscn` nur mit eigener Paketkennung und eigenem Spielstand exportieren. Der Einstieg protokolliert echte Touch-/Zurück-Eingaben, Pausenkonsistenz und die Ausgabe von AudioEffectCapture. Normale Exporte schließen alle Tests aus.

Technische Grundlagen: [Godot AudioStreamWAV](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html) für PCM-Daten und Sample-Schleifen; [SubViewportContainer](https://docs.godotengine.org/en/stable/classes/class_subviewportcontainer.html) für die reduzierte Renderauflösung; [Window.go_back_requested](https://docs.godotengine.org/en/stable/classes/class_window.html#class-window-signal-go-back-requested) für die Android-Zurück-Taste.
