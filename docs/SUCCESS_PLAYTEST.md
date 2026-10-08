# Geschlossener Spieltest und Pixel-Probe

Dieser Plan ist für eine erste Gruppe von 12–20 Personen vorbereitet. Es wurden noch keine Teilnehmer angeschrieben oder Ergebnisse menschlicher Tests erhoben. Mindestens ein Drittel sollte wenig Erfahrung mit Idle-RPGs haben. Teilnahme und lokale Notizen sind freiwillig. Keine Veröffentlichung, Einladung oder automatischer Datenversand ist Teil der Implementierung.

## Sitzung 1: erste zehn Minuten

1. Den neuen Solo-Beta-Build auf einem separaten Testprofil öffnen. Einen bestehenden echten Spielstand weder löschen noch mit einem QA-Paket überschreiben.
2. Ohne Erklärung eine Klasse wählen und die erste Expedition spielen. Beobachten: Zeit vom App-Start bis zur Auswahl, Verständnis des automatischen Kampfes, Auffälligkeit der ersten Signatur. App-Start und reale Bedienzeiten mit einer Stoppuhr messen; lokale Notizen enthalten nur Simulationszeiten.
3. Erste Beute ansehen. Fragen: „Was verändert dieses Amulett?“ und „Was würdest du jetzt tun?“ Verständnis vor einer Erklärung notieren. Prüfen, ob die Person den Anlegen-Button selbst findet.
4. Zum räumlichen Lager zurückkehren. Ohne Wegbeschreibung Schmiede und Portal finden lassen. Am Tisch alle drei Schwüre ansehen. Vor Start einen einzelnen Schwur und anschließend eine Kombination aus zwei Schwüren erklären lassen: Welche beiden Risiken gelten, welcher Build profitiert, welche Belohnung wird erwartet? Erst nach der unbeeinflussten Antwort erklären.
5. Einen Wächterkampf beobachten lassen. Wahrnehmung von Phasenbruch, Klangsignal, Warnfläche und Ausweichen getrennt notieren; automatische Bewegung muss als solche verstanden werden. Eine dritte Auswahl am Schwurtisch darf keine heimliche dritte Regel hinzufügen.
6. Ein Farmziel wählen, App schließen und am nächsten Tag selbstständig zurückkehren lassen. Keine Erinnerung vor diesem Rückkehrversuch schicken. Rückkehrzeit nicht aus den Simulationssekunden der lokalen Notizen ableiten.

Nach jeder Sitzung höchstens fünf Fragen: Was war spannend? Was war unklar? Wo wolltest du aufhören? Welche Ausrüstung würdest du als Nächstes suchen? Würdest du morgen aus eigenem Antrieb weiterspielen, und warum?

Die [leere Ergebnistabelle](play/success-test-results.csv) enthält keine erfundenen Messwerte. Testkürzel statt Namen verwenden. Notizen nur mit Zustimmung sammeln; keine Wiederherstellungscodes, GitHub-Zugangsdaten oder persönlichen Angaben aufnehmen. Teilnehmer können unter Options > Beta / Privacy freiwillige lokale Notizen einschalten und einen Bericht selbst kopieren. Ausschalten löscht diese Notizen.

Vorläufige Kriterien für die nächste Entscheidung, als Hypothesen: Mindestens 80 % verstehen die erste Reliquie sowie die Risiken einer Schwur-Kombination ohne Hilfe. Der erste Sieg soll innerhalb von drei Minuten Kampfzeit möglich sein. Bei mehr als 20 % Abbrüchen an derselben Stelle wird diese Stelle vor neuen Inhalten überarbeitet. Rückkehr nach einem Tag getrennt nach freiwilligem Start und eingeladenem Test dokumentieren; eine kleine eingeladene Gruppe ist kein belastbarer Markt-Retention-Wert.

## Google Pixel 9 Pro Fold, überwiegend zugeklappt

Zuerst im Querformat auf dem Außendisplay testen. Balanced, Battery, Standardschrift und Large Text prüfen. Dann während Pause und laufendem Kampf auf-/zuklappen: HUD, Touchziele, sichere Ränder, Kamerabild und Spielstand dürfen nicht beschädigt werden. Zusätzlich Audio stumm, Haptik an/aus, Android Back, Hintergrundwechsel, Prozessneustart und Offline-Rückkehr testen.

Das isolierte ARM64-Messpaket findet sich nach erfolgreichem Android-Runtime-Build im GitHub-Artefakt **emberfall-isolated-android-qa-packages** als `emberfall-pixel-probe.apk`. Seine Paketkennung ist `com.philmenting.emberfallashenveil.betaqa`; die eigentliche Solo-App verwendet eine andere Kennung. QA-Pakete verschiedener CI-Läufe können unterschiedliche Signaturen haben. Falls nötig nur dieses QA-Paket deinstallieren, niemals die eigentliche App oder deren Daten löschen.

Mit verbundenem Android-Gerät und eingerichteter ADB-Autorisierung:

```bash
python3 scripts/android_device_probe.py --discover-only --output build/device-055/discovery
python3 scripts/android_device_probe.py --apk emberfall-pixel-probe.apk \
  --source-commit <exakter-export-commit> --aapt /path/to/aapt2 \
  --serial <bereits-autorisiertes-gerät> --output build/device-055/profile
```

Ab Stand 055 läuft jede Klasse in Balanced/Battery 200 reale Sekunden mit gewöhnlichem Start-Equipment; abgeschlossene Etage-1-Läufe starten unverändert neu. Der Beobachter verweigert Emulatoren, prüft das isolierte ARM64-Offline-Paket und erfasst Frame-Verteilung, CPU-/verfügbare GPU-Zeit, Prozessspeicher, Thermaldaten und Akku-Zustand. Quelle/APK und System-Rohbelege stehen im Bericht. `measured_touch_pending` bedeutet abgeschlossene Profilierung, keine Freigabe. Fehlende Hardware heißt `unavailable` / Exit 3. Details, Messgrenzen und Touch-Schritte stehen im [Geräteplan 055](device-quality-055.md).

Für Wärme und Verbrauch anschließend mit dem **regulären Solo-Testbuild** 20 Minuten spielen. Helligkeit, Bildwiederholrate, Ladezustand, Grafikmodus und Umgebungstemperatur protokollieren; ohne Ladekabel messen. Akkustand und Android-Batterietemperatur vor und nach dem Versuch erfassen, subjektive Handwärme separat notieren. Battery und Balanced in vergleichbaren, getrennten Sitzungen mit abgekühltem Gerät untersuchen. Keine Akku- oder Leistungsverbesserung behaupten, bevor diese Messungen vorliegen.

## Gameplay-Material

Der [Gameplay-Clip](previews/success-loop/emberfall-gameplay-040.mp4) zeigt tatsächlichen Kampf und tatsächliche erste Beute mit normaler Startausrüstung. Er ist ein vorbereiteter Entwurf, noch nicht veröffentlicht. Vor Verwendung im Store aktuelle Spieloberfläche, Geräte-Aufnahme, Seitenverhältnis und Anforderungen des jeweiligen Kanals prüfen. Render-Fixtures mit erhöhtem Leben aus früheren Grafiktests gehören nicht in Werbematerial.
