# Physische Android-Prüfung – Stand 055

In der Arbeitsumgebung am 6. Oktober 2026 ist **kein physisches Android-Gerät verfügbar**. `adb` und Java fehlen auf dem PATH; `/dev/bus/usb` und die geprüften üblichen SDK-Verzeichnisse sind nicht vorhanden. Es gibt auch kein verfügbares Werkzeug für eine verbundene Gerätefarm. Der tatsächliche [Verfügbarkeitstest](design/reference-055/device-observer/physical-availability.json) endet mit **Status `unavailable`, Exit 3 und `physical_device_measured: false`**. Desktop- und Emulator-Ergebnisse werden dadurch nicht zu Handy-Messungen.

Die neue [Gerätebeobachtung](../scripts/android_device_probe.py) und die erweiterte [native QA-Szene](../tests/android_device_probe.gd) bereiten einen reproduzierbaren Hardwarelauf vor. Die Python-Verträge prüfen Geräteauswahl, Emulator-Ausschluss, isolierte APK-Identität, echte Mindestlaufzeit, Absturz/Neustart/Timeout, Messdaten und unveränderte Grenzen der Abnahme. Diese simulierten Tests sind keine Hardwaremessung.

Die native Parse-Prüfung und ein ausdrücklich markierter Desktop-Kurzlauf über alle sechs Fälle endeten mit Prozesscode 0. Je 20 reale Sekunden lieferten 51–316 Messbilder und echte Angriffe; 808 Quellinputs blieben während dieses Laufs unverändert. Der erste 12-Sekunden-Versuch verfehlte bei zwei langsamen Software-Renderer-Fällen die unveränderte Mindestzahl von 30 Bildern und endete korrekt mit Code 1. Nur die Kurzkonfiguration wurde verlängert. Die [begrenzten Belege](design/reference-055/device-observer/README.md) kennzeichnen Linux/Xvfb/llvmpipe und Dummy-Audio; Telefonleistung, vollständiger Wächterlauf, Temperatur, Akku und Touch bleiben dadurch ungeprüft.

## Automatischer Hardwarelauf

Der Standardlauf dauert etwa **20 Minuten**: drei Klassen, jeweils Balanced und Battery, 200 Sekunden pro Fall. Er verwendet das normale Start-Equipment, echte Angriffe und die reale Simulation. Beendete Expeditionen starten mit demselben Build erneut auf Etage 1; Belohnungen verbessern die Messausrüstung nicht. Es gibt keine Lebens-/Schadensbuffs, keine übersprungenen Reiseabschnitte und keine beschleunigte Simulationsuhr. Für einen vollständigen 200-Sekunden-Fall müssen auch mindestens 30 gemessene Wächterbilder und ein echter Wächterangriff enthalten sein.

Erfasst werden:

- Tatsächliche Zeitabstände nach dem Rendern: Mittelwert, Median, p95, p99, Maximum und Bilder über dem jeweiligen 60-/30-FPS-Ziel. Drei Sekunden nach Start und jedem Neustart werden ausgelassen. Strecke und Wächterkampf erhalten getrennte Auswertungen; jede tatsächlich verwendete Rendergröße und eine automatische Balanced-Auflösungsreduzierung erhalten eigene Bildzahlen.
- Godot-Prozess-/Physikzeit sowie CPU- und GPU-Zeit des 3D-Viewports. Liefert der Renderer keine positiven GPU-Zeitstempel, steht dort ausdrücklich `null` / `unavailable_for_renderer`. Diese Angaben sind keine GPU-Auslastung und messen keine Touch-Latenz.
- Prozess-PSS über `dumpsys meminfo`, verfügbare Prozess-CPU-Zähler und daraus die Auslastung relativ zu einem CPU-Kern, Android-Thermalstatus und verfügbare Temperatursensoren, Akku-Zustand und Ladungszähler alle zehn Sekunden. Fehlende Betriebssystemdaten bleiben als nicht verfügbar markiert. Die Temperatur des Akkus wird nicht als CPU-Temperatur ausgegeben.
- APK-SHA256, angegebener Export-Quellcommit, Beobachter-SHA256, Geräte-/Android-/ABI-Identität und Zeitstempel. Die Seriennummer wird nur gehasht gespeichert; die Quelle wird über den Exportbeleg zugeordnet, nicht durch Geräte-Attestierung bewiesen.

Der Beobachter verweigert bekannte Emulatorziele. Vor der Installation prüft `aapt2`/`aapt`, dass das Paket **`com.philmenting.emberfallashenveil.betaqa`**, debuggable, offline und mit ARM64-Bibliothek ist. Er löscht oder deinstalliert das reguläre Spiel nicht und verändert weder Akkudienst noch Geräteeinstellungen. Die isolierte QA-App wird installiert, gestartet und nach Abschluss gestoppt. Bei Prozessverlust, unbestelltem Neustart, Laufzeitfehler oder unvollständigem Bericht steht `failed` / Exit 1; bloß fehlende Werkzeuge oder Hardware ergeben Exit 3.

Ein laufender USB-Ladevorgang verhindert eine belastbare Akkuverbrauchsmessung. Der Bericht nennt die externe Stromversorgung und gibt dann keinen Akkuverbrauch aus. Für einen Verbrauchslauf darf eine bereits autorisierte drahtlose adb-Verbindung verwendet werden. Temperatur, Displayhelligkeit, Auflösung/Faltzustand, Ladezustand und übrige Apps müssen für einen Vergleich gleich sein. Die Instrumentierung selbst verursacht etwas zusätzlichen Aufwand.

Mit einem bereits autorisierten, verbundenen Handy und installierten Android-Build-Tools:

```bash
python3 scripts/android_device_probe.py --discover-only --output build/device-055/discovery

GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 \
  python3 scripts/export_android_qa.py \
  --architecture arm64-v8a --scene res://tests/android_device_probe.tscn \
  --output build/emberfall-pixel-probe.apk

python3 scripts/android_device_probe.py \
  --apk build/emberfall-pixel-probe.apk --source-commit <exakter-export-commit> \
  --aapt /path/to/android-sdk/build-tools/<version>/aapt2 \
  --serial <bereits-autorisiertes-gerät> --output build/device-055/profile
```

`device-profile.json` enthält den Gesamtbericht und die Systemstichproben; `device-performance.json` die native Messung. Begrenzte Rohbelege, QA-Log und Exit-Info liegen daneben. Status **`measured_touch_pending` / Exit 0** bestätigt lediglich den abgeschlossenen Messlauf. Ziel-Framerate, Hitzeentwicklung und sichtbare Qualität müssen anhand der einzelnen Fälle beurteilt werden. Das ist keine Beta- oder Veröffentlichungsfreigabe. `--case-seconds` kann für eine gezielte Fehlersuche 30–600 Sekunden wählen; ein kurzer Lauf ersetzt nicht den Standardlauf.

## Touch und echter Spielablauf

Die Profilierung automatisiert keine menschliche Bedienungsprüfung. Für diese Prüfung wird ein separates, gleiches Quellcommit nutzendes ARM64-Offline-QA-Paket mit `res://Main.tscn` exportiert. Dessen eigener APK-SHA256 gehört in den Bedienungsbericht. Anschließend werden auf dem echten Display folgende Schritte mit Finger und Systemnavigation beobachtet:

| Schritt | Festzuhaltendes Ergebnis |
|---|---|
| Klasse wählen, Expedition starten und ersten Wächter besiegen | Erreichbare Touchflächen; Figur, Warnungen, Leben/Mana lesbar; Beute und Folgeaktion bedienen |
| Gear, Skills und Options öffnen; scrollen | Keine blockierten Schaltflächen, ungewollten Aktionen oder vom Finger verdeckten entscheidenden Informationen |
| Pause/Fortsetzen und Android Back | Passende Rücknavigation; geschlossene Menüs; unveränderter Pausenstatus |
| Large Text; Displayaussparung; falls vorhanden geschlossen/offen | Lesbarer Text ohne abgeschnittene Aktionen; sichere Abstände; korrekte Ansicht nach Größenwechsel |
| Hintergrund, Bildschirm sperren, zurückkehren | Passender Fortschritt; keine verlorene oder doppelte Beute; kein großer Kamera-/Animationssprung |
| Länger spielen in beiden Grafikmodi | Sichtbare Bildruckler, Wärme, Akkustand und eventuelle Abstürze mit Uhrzeit protokollieren |

Der Bericht nennt Tester, Gerät, Datum, Android-Version, APK-SHA256, Grafikmodus, Displayzustand und für jeden Schritt `pass` / `fail` / `not_tested` samt Beobachtung. `adb input tap` kann eine technische Aktion auslösen, beweist aber weder Finger-Erreichbarkeit noch Touch-Latenz oder gute Bedienbarkeit. Der bestehende [Geräte-Abnahmeplan](play/DEVICE_TESTS.md) bleibt die Grundlage für die spätere Release-Entscheidung.

**Offen bleibt die tatsächliche Durchführung auf physischer Hardware.** Der ausgeführte Verfügbarkeitstest begründet diesen offenen Status; eine erfolgreiche Einrichtung oder ein Emulatorlauf füllt ihn nicht aus.
