# Set-Ziele und Beuteverwaltung — lokale Prüfung

Basis: `4a9aa0d55e228fb50f945dd0c54531a7500b47a6`, neuester Kopf von
`release/google-play-beta-039` bei der Sichtung. `main` lag auf `610c343` / 0.38;
PR #3 enthielt bereits die 0.41-Welt und Animationen. Dieser Ausbau enthält
die zusätzlichen Änderungen an Vorbereitung und Beuteverwaltung.

## Tatsächlich ausgeführt

- Godot **4.7.2.stable.official.ed1daf0bf**, identisch mit der im Repo
  angeforderten Engine-Version; native Assets importiert.
- `python3 scripts/run_beta_checks.py`: **30 Godot-Suiten, 3.368 Checks,
  0 Fehler**. Enthält Reise, Dungeon, Speicherung, AFK, Klassen,
  Schwur-/Bossphasen, Prognosen, Einführung, Beute, Optionen,
  Darstellung, Animationen und isolierte Online-UI-/Identitätsprüfungen.
- Neue Set-/Beutesuite separat nach der letzten Gameplay-Korrektur:
  **114 Checks, 0 Fehler**; zusammen mit Recovery und Success Loop
  **249 Checks, 0 Fehler**.
- `node --check server/modules/emberfall.js` und
  `node tests/progression_runtime_test.js`: bestanden.
- Native OpenGL-Compatibility-Vorschau auf X11 / Mesa llvmpipe:
  **sechs gespeicherte Renderansichten**, kein horizontales Überlaufen,
  keine Script- oder Shader-Fehler im Renderprotokoll.
- `git diff --check`: bestanden.

Die ursprünglichen ersten drei Suiten des vollständigen Durchlaufs wurden nach
der letzten Änderung an der Upgrade-Prüfung nochmals ausgeführt. Der
GitHub-Workflow `Gameplay Quality` ist zusätzlich für den fertigen Commit
eingerichtet; sein Ergebnis ist im Pull Request sichtbar.

## Neue Regressionen

Die Verkaufstests prüfen tatsächliche Inventar- und Goldänderungen, nicht nur
die Texte des neuen Buttons. Abbruch, Schutzänderung nach der Vorschau,
Klassenwechsel, gleichwertiges Ersatzobjekt, ein ungültiges Element in einer
mehrteiligen Liste und doppelte Bestätigung bleiben ohne fehlerhafte Auszahlung.
Alle drei Klassen sowie jedes Rohattribut werden berücksichtigt.

Set-Tests prüfen Aktivierung durch ein gleichwertiges drittes Teil, Erhaltung
eines aktiven Sets, echten Set-Wechsel, verbleibende aktive Sets bei vier oder
mehr Teilen und aktive/klassenfremde Reliquien. Ein größerer Mana-Pool mit
weniger Spirit bleibt ein manuell zu prüfender Tausch.

Die Jagdtests prüfen den tatsächlich aufgebauten `Contract.hunt`, die richtige
Region/Etage, keine kostenlose Beute oder automatisch gestartete Expedition,
gesperrte Regionen sowie Speicherung und Kaltstart. Der Sammel-Upgrade-Test
vergleicht eine alte 300-Sekunden-Schwur-AFK-Abrechnung gegen den unveränderten
eingefrorenen Zustand, bevor das neue Teil angelegt wird.

## Gerenderte Ansichten

Die PNG-Größen entsprechen echten Renderflächen. Godots expandierender
960×540-Canvas besitzt bei den kleineren Renderflächen andere logische Maße.

| Renderfläche | Logischer Canvas | Schrift | Ansichten |
|---|---|---|---|
| 854×480 | 960×540 | Large Text | Set-Ziele, Verkaufsvorschau |
| 1200×535 | 1211×540 | Standard | Set-Ziele, Verkaufsvorschau |
| 1040×1080 | 960×996 | Standard | Set-Ziele, Verkaufsvorschau |

Alle sechs Bilder wurden gespeichert. Die kompakte Set-Ansicht, breite
Verkaufsvorschau und nahezu quadratische Set-Ansicht wurden visuell geöffnet
und geprüft; die anderen Ansichten wurden automatisch auf Überlaufen geprüft.
Die zuletzt gespeicherten Bilder enthalten auch die korrekte Auswahl der
Equipment-Registerkarte und den Singular bei einem einzelnen Verkauf.
Der abschließende UI-Feinschliff ordnet Verkaufen und Abbrechen in einer
gemeinsamen Zeile an. Die neue Suite und alle sechs nativen Renderansichten
wurden danach wiederholt; bei der kurzen Verkaufsliste liegen jetzt beide
Aktionen in allen drei Größen vollständig innerhalb der sichtbaren
Scrollfläche, auch bei kompakter Large-Text-Darstellung.

## Grenzen

Dies ist eine lokale Gameplay- und Darstellungsprüfung. Für diesen neuen Ausbau
wurden keine Android-APK/AAB erstellt, kein physisches Telefon geprüft und
keine menschlichen Langzeit- oder Rückkehrdaten erhoben. Der neue
GitHub-Workflow ersetzt die vorhandenen Android-Veröffentlichungsgates nicht.
Die Store-Version und die dauerhaft signierte Veröffentlichung sind kein Teil
dieser Änderung. Mesa-Software-Rendering ist kein Pixel-Leistungsnachweis.
