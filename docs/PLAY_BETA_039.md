# Play-Beta-Kandidat 0.39.0-beta.1

Diese Version bereitet einen geschlossenen **Solo-/AFK-Test** vor. Nyra bewegt
sich, kämpft, wirkt Fähigkeiten und weicht automatisch aus. Die Entscheidungen
liegen bei Klasse, Attributen, Ausrüstung, Techniken, Kampfstil und Farm-Ziel.
Die Richtung bleibt ein eigenes düsteres Dungeon-RPG mit Build- und Beutefokus;
Grafik und Inhalt sind keine Nachbildung von Diablo Immortal.

## Was sich für Spieler verbessert

- Längere AFK-Abwesenheit wird auf Android mit einer sichtbaren Fortschrittsanzeige
  in kleinen Rechenschritten ausgewertet. Kampf, Seed, Beute und Restzeit bleiben
  identisch zur bisherigen Simulation. Ein gespeicherter Restzeit-Eintrag erlaubt
  die Fortsetzung nach einem Abbruch, ohne doppelte Belohnungen.
- Farm-Prognosen geben Rechenzeit zwischen Simulationsschritten frei. Ihre
  Bewertung berücksichtigt weiterhin alle 256 tatsächlichen Muster.
- Der Beutebildschirm nutzt die volle Breite und zeigt tatsächliche Kampfdauer,
  besiegte Gegner, gewirkte Fähigkeiten und Ausweichmanöver. Kampagne, Hunts und
  Trials haben passende Folgeaktionen. Niederlagen führen zum Build.
- „Equip clear upgrades“ legt nur erhaltene Gegenstände an, die keinen der
  verglichenen Kampfwerte verschlechtern und keine höheren Manakosten verursachen.
  Abgelegte Gegenstände bleiben im Inventar. Alternativen mit Wertetausch müssen
  weiter manuell verglichen werden.
- Eine eigene Boss-Lebensanzeige ergänzt Gefahrenflächen und Countdown. Display-
  Aussparungen und Navigationsleisten fließen in die Android-Randabstände ein.
- Erste Schritte im Camp erklären die nächste sinnvolle Aktion. Unter
  **Options → Beta / Privacy** stehen lokale Speicherung, Wiederherstellung und
  ein überprüfbarer Feedback-Text. Das Spiel sendet den Text nicht automatisch.

Die Beta enthält drei Klassen, vier Regionen, sechs Ausrüstungsslots,
gezielte Hunts, 30 einmalig belohnte Ash Trials und bis zu 24 Stunden AFK.
Spieloberfläche: **Englisch**. Online-Testkonten, Fellowship und Server-Profil
sind in den Beta-Presets nicht aktiviert. Keine Werbung, Analytik oder Käufe.

## Reproduzierbare Prüfungen

```sh
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 python3 scripts/run_beta_checks.py
python3 -m unittest discover -s tests -p test_android_release.py -v
python3 scripts/check_play_release.py
```

Der aktuelle lokale Stand besteht **19 Godot-Suiten mit 1.401 Prüfungen**, die
Server-JavaScript-Prüfung und fünf Android-/Release-Prüfungen. Die neue Beta-
Suite vergleicht alle Klassen und Kampfstile, gezielte Hunts und einen echten
Save/Reload-Abbruch mit den vollständigen ursprünglichen AFK-Ergebnissen.

Die UI-Captures wurden mit dem echten Godot-Renderer bei 1280×720 und 854×480
geprüft, einschließlich ausdrücklich simulierter Display-Aussparungen.
[Ansichten](previews/play-beta/). Diese Desktop-Prüfung beweist keine Smartphone-
Bildrate, Temperatur oder Treiberkompatibilität. [Geräte-Testplan](play/DEVICE_TESTS.md).

## Android-Artefakte und Signierung

| Eigenschaft | Play-Bundle | Separate Test-APK |
|---|---|---|
| Paket | `com.philmenting.emberfallashenveil` | `com.philmenting.emberfallashenveil.closedbeta` |
| Version | 0.39.0-beta.1 / Code 43 | 0.39.0-beta.1 / Code 43 |
| Plattform | Android 7+ / min SDK 24 / Ziel-SDK 36 | Android 7+ / min SDK 24 / Ziel-SDK 36 |
| Architektur | ARM64 | ARM64 |
| Ausrichtung | Querformat | Querformat |
| Internet-Berechtigung | keine | keine |
| Automatisches OS-Backup | deaktiviert | deaktiviert |

APK und AAB wurden lokal exportiert und signiert. Bundletool bestätigt die
Bundle-Struktur, Jarsigner die Signatur und die Manifest-Prüfung die Identität,
SDKs, fehlenden Berechtigungen, Querformat und deaktivierte Debug-/Backup-
Funktionen. Beide ARM64-Bibliotheken haben mindestens 16-KB-ausgerichtete
ELF-LOAD-Segmente. Auch eine per Bundletool aus dem AAB abgeleitete APK besteht
`zipalign -c -P 16 4` und die APK-Signaturprüfung.

**Lokale und PR-Artefakte sind Validierungs-Builds mit einem separaten Testschlüssel.**
Sie dürfen nicht als dauerhafter Play-Upload verwendet werden. Unterschiedlich
signierte Test-APKs können einander nicht aktualisieren. Vor einer Neuinstallation
den eigenen Spielstand über Save Backup sichern; die Test-APK ist vom Play-Paket
getrennt und überträgt dessen Spielstand nicht automatisch.

Der bisher hängende CI-Aufruf zur Vorlageninstallation wurde durch eine explizite
Installation des offiziellen `android_source.zip` ersetzt. Der erzeugte Gradle-
Build nutzt AGP 8.10.1. Die reguläre CI liefert überprüfte Test-APK/AAB-Artefakte.
Der zusätzliche **Android Beta Runtime**-Workflow baut eine getrennte x86_64-QA-
Installation und prüft exakte AFK-Belohnungen sowie Neustart auf Android 16. Diese
Fixture ist kein Shipping-Build und prüft keine ARM64-Geräteleistung.

## Store-Paket

[store.json](play/store.json) enthält deutsche und englische Store-Texte und
Release Notes. Titel, Kurzbeschreibung, Beschreibung und Release Notes werden
gegen die Play-Längenlimits geprüft. [assets](play/assets/) enthält das vorhandene
512×512-App-Icon, eine 1024×500-Feature-Grafik und vier unveränderte Spielansichten.
Die Feature-Grafik wird als neue Komposition aus der eigenen 3D-Szene gerendert;
sie zeigt keine erfundene höherwertige Spielgrafik. Die Screenshots stammen aus
isolierten Renderer-Fixtures mit echten regulären Kampfwerten.

Der [Datenschutz-Entwurf](play/privacy-policy-draft.html) braucht noch den
bestätigten Entwicklerkontakt und eine öffentliche HTTPS-Adresse. Angaben zur
Datensicherheit sind ein Entwurf für den nachweislich offline exportierten
Build; die tatsächlichen Console-Antworten, Zielgruppe und IARC-Inhaltsbewertung
müssen für dieses Spiel abgeschlossen werden.

## Den upload-signierten Kandidaten erstellen

1. Den öffentlichen Entwicklernamen, Supportkontakt und veröffentlichte
   Datenschutz-URL in `docs/play/store.json` ergänzen. Die App in der Play Console
   anlegen; bei einer vorhandenen App Paket-ID und den bisher höchsten Version
   Code prüfen. Code 43 muss höher sein als bereits hochgeladene Codes.
2. Den Geräte-Test durchführen und einen konkreten Ergebnisbericht hinterlegen.
   `device_test_report` zeigt auf dessen Repository-Pfad. `play_app_created` wird
   erst nach tatsächlicher Anlage der App auf `true` gesetzt.
3. Den dauerhaften, zur Play-App passenden Upload-Key als Repository-Secrets
   `EMBERFALL_UPLOAD_KEYSTORE_B64`, `EMBERFALL_UPLOAD_ALIAS` und
   `EMBERFALL_UPLOAD_PASSWORD` konfigurieren. Schlüssel und Passwörter niemals
   in Issues, Quellcode oder Chat-Nachrichten posten. Bestehende Schlüssel behalten.
4. `python3 scripts/check_play_release.py --strict` muss bestehen. Der manuell
   gestartete Workflow **Google Play Beta Release Candidate** prüft danach alle
   Tests, signiert AAB und Test-APK, prüft ein daraus abgeleitetes APK und liefert
   Checksummen. Er lädt nichts in die Play Console hoch.
5. Den verifizierten AAB-Kandidaten in den geschlossenen Testtrack laden, Console-
   Erklärungen und Store-Materialien abschließen, Testergruppe und Opt-in-Link
   einrichten und den Play-Pre-Launch-Bericht prüfen. Vor dem Rollout dessen
   tatsächliche Abstürze und Darstellungsprobleme beheben.

**Offene Release-Gates:** Console-Status, dauerhafter Upload-Key, bestätigter
öffentlicher Kontakt, veröffentlichte Datenschutz-URL und physische Geräte-
Abnahme. Die strenge Prüfung meldet fehlende Angaben als blockiert. Ein erfolgreich
exportiertes Bundle allein ist keine Store-Freigabe.
