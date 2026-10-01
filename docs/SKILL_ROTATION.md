# Automatische Fähigkeiten – 0.12

## Auswahl und Ablauf

Unter **Gear → Skills** werden zwei zusätzliche Techniken je Klasse ausgerüstet. Die Klassenfähigkeit bleibt erhalten. Jede Klasse speichert ihre eigene Auswahl. Eine bereits im anderen Platz liegende Technik tauscht bei Auswahl die Plätze; während einer Expedition bleibt der Build gesperrt.

Die Simulation entscheidet anhand derselben Positionen und Werte wie der sichtbare Kampf:

1. Angefangene Ausweichbewegung, Zauber und das Erreichen der Angriffsreichweite werden abgewickelt.
2. Eine benötigte Schutztechnik hat Vorrang, wenn Leben unter 70% liegt oder ein Bodenangriff droht. Bereits wirksamer Guard verhindert unnötiges erneutes Wirken.
3. Die Klassenfähigkeit wird bei passender Zielgruppe eingesetzt.
4. Danach kommen passende Angriffstechniken infrage. Sind beide Plätze zugleich sinnvoll und bereit, wählt der Lauf-Seed zwischen ihnen; bei nur einer passenden Technik wird diese genommen.
5. Ohne passende bezahlbare Fähigkeit wird normal angegriffen.

Jede Technik hat Mana-Kosten, eine eigene Abklingzeit und eine Wirkzeit. Mana und Abklingzeit werden beim Beginn verbraucht. Ein nötiges Ausweichen kann das Wirken abbrechen; es gibt dann keine Erstattung. Mehrere Fähigkeiten ersetzen damit kein Ressourcenmanagement. Der Fähigkeitenschaden der Ausrüstung und Attribute bestimmt auch den Schaden der Techniken.

| Klasse | Technik | Mana / Abklingzeit | Wirkung |
|---|---|---|---|
| Vowkeeper | Oath Bastion | 16 / 14 s | 5 s Guard, 45% weniger eingehender Schaden |
| Vowkeeper | Sundering Arc | 22 / 8 s | Flächenhieb um die Figur, 78% des Fähigkeitenschadens |
| Vowkeeper | Ashen Judgment | 26 / 10 s | Schwerer Schlag gegen Elite/Boss oder verwundete Ziele, 150% |
| Arcanist | Frost Mantle | 22 / 14 s | 3,5 s Guard und 4 s Verlangsamung naher Gegner |
| Arcanist | Veil Lightning | 28 / 8 s | Bis zu drei Ziele, höchstens 4 m pro Sprung, je 72% |
| Arcanist | Ashen Starfall | 38 / 12 s | Nach 0,8 s Einschlag auf der markierten Position, 120% |
| Ranger | Cinder Veil | 16 / 14 s | 2,8 s Guard und Rückzug, wenn ein sicherer Zielort existiert |
| Ranger | Thornfall | 28 / 9 s | Pfeile auf markierter Fläche, 90%, 1,7 s Verlangsamung |
| Ranger | Marked Shot | 24 / 8 s | Gezielter Schuss, 120%, ignoriert Schildträger-/Elite-Schadensreduktion |

Prozentwerte sind vor kritischen Treffern und gegnerischer Reduktion. Bodenfähigkeiten treffen die markierte Fläche; herausgelaufene Gegner werden nicht nachträglich getroffen. Ein Kettenblitz sucht von jedem getroffenen Gegner aus das nächste erreichbare Ziel. Schutzwirkungen werden nicht aufaddiert. Der Arcanist behält seine separate Mana-Barriere.

## Darstellung und Bedienung

Das Kampf-HUD zeigt beide Techniken mit bereit/nicht genug Mana/Wirken/Abklingzeit. Eigene Godot-Zeichnungen liefern die Symbole. Schutzplatten, Kettenblitze, markierte Einschlagflächen und Trefferstrahlen entstehen aus eigenen Godot-Meshes. Zwei zusätzliche synthetisierte Klangereignisse begleiten Blitz und Starfall.

Ein Android-Touch-Test deckte auf, dass Karten und Buttons Wischgesten abfingen. Ihre Maus-/Touch-Ereignisse werden jetzt an den übergeordneten ScrollContainer weitergereicht; dekorative Fortschrittsbalken ignorieren Eingaben. Zwei echte Android-Wischgesten scrollten ohne versehentliches Ausrüsten, anschließend aktivierte ein gezieltes Antippen Starfall in Platz I. Die Godot-Regeln dazu stehen in der offiziellen [Control-Dokumentation](https://docs.godotengine.org/en/stable/classes/class_control.html) und [ScrollContainer-Dokumentation](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html).

## Speicherung und Kompatibilität

Neue Expeditionen enthalten `skill_rotation=1`, ihre konkrete Auswahl und die verbleibenden Abklingzeiten. Spielstände speichern die Auswahl getrennt je Klasse. Der Seed legt zugleich Dungeonform, Gegnergruppen, Spawnpositionen und mögliche Fähigkeitenentscheidungen fest. Skip, Live-Spiel und Offline-Farmen verwenden dieselbe Simulation; Farm-Prognosen berücksichtigen den Build.

Laufende Expeditionen aus 0.11 und früher werden mit ihren ursprünglichen Regeln fortgesetzt. Zwölf vorher mit dem unveränderten 0.11-Code erzeugte Checkpoints vergleichen die vollständigen Endzustände. Erst ein neuer Lauf erhält die Rotation. Ungültige neue Rotationszustände werden beim Laden zurückgewiesen.

## Nachweise

- **681 erfolgreiche lokale Prüfungen in zwölf Suiten**: darunter 133 neue Prüfungen der Rotation und vier zusätzliche Audioprüfungen. Alle neun Techniken, tatsächliche Kosten/Wirkungen, Zielbedingungen, Abbruch, Abklingzeiten, Auswahl/Speicherung, alte Checkpoints und temporäre Grafikobjekte sind enthalten.
- Alle 64 Startvarianten je Klasse vergleichen Live und Skip, auch wenn zwei Fähigkeiten gleichzeitig bereit sind. Kombinationen werden über alle vier Gebiete geprüft. Dies ist kein vollständiger Beweis jeder späteren Ausrüstungskombination.
- **Realer Android-Emulatorlauf** (API 36, 1280×720): Arcanist, Etage 1, unveränderte Startausrüstung. Starfall per Touch in Platz I, Lightning in Platz II. Sieg nach 70,7 s Simulationszeit, 380 Leben, 123 Mana, zweimal Starfall, einmal Lightning. Reguläre Beute: seltene Veilwalker Treads. Keine erhöhten Testwerte.
- Screenshots: `build/previews/android-012-*.png`; Ereignisse: `build/reports/android-012-skills.log`. Ein 85-Sekunden-Mitschnitt zeigt Auswahlabschluss, automatischen Dungeonlauf und Beute (`build/previews/emberfall-012-gameplay.mp4`, ohne Audio).
- Der bestehende Fortschrittsbot gewann mit den Standardtechniken 480 ausgewählte Läufe je Klasse: Vowkeeper nächste Etage 90 / 18,06 simulierte Stunden, Arcanist 97 / 12,36 Stunden, Ranger 97 / 11,58 Stunden. Eine Beutefolge, ein Ausrüstungsalgorithmus; keine vollständige Klassenbalance. Rohdaten: `build/reports/balance-012-0.log`.

## Offene Grenzen

Es gibt zwei wählbare Technikplätze und eine Klassenfähigkeit, noch keinen verzweigten Fähigkeitenbaum. Der Nahkämpfer benötigt im Fortschrittsbot weiterhin länger. Menschliche Langzeittests, physische Android-Geräte, weitere Bildschirmformate und die Play-Console-Prüfung bleiben offen. Der Stand bleibt lokal/solo ohne Mehrspieler-Server.
