# Ausrüstung und Niederlagen — 0.39.0-beta.3

Diese Erweiterung soll Fehlbedienung und Ratlosigkeit zwischen Expeditionen verringern. Ob sie Spieler häufiger zurückbringt, muss der vorbereitete Spieltest zeigen; es gibt noch keine gemessene Verbesserung der Spielerbindung.

## Ausrüstung behalten und finden

**Protect** schützt einzelne Gegenstände in Tasche und Ausrüstung vor Verkauf. Geschützte angelegte Gegenstände werden außerdem nicht durch „Equip safe upgrades“ ersetzt. Bewusstes manuelles Anlegen, Austauschen und Tempern bleibt möglich. Der Schutz folgt dem Gegenstand beim Wechsel in die Tasche und bleibt bei Neustart und Backup erhalten. **Unprotect** hebt ihn auf. Beim Umschalten bleibt die Scrollposition erhalten.

Die Tasche kombiniert einen Slotfilter mit **All gear**, **Class gear**, **Safe upgrades** oder **Protected**. Class gear zeigt die auf die gewählte Klasse abgestimmten Gegenstände; andere Klassen dürfen sie weiterhin tragen. Filter verändern keine Gegenstände und werden nicht dauerhaft gespeichert. Ein leerer Filter erklärt den Zustand und bietet „Show all gear“ an.

Beim ersten Sieg auf Etage 1 wird für die garantierte Klassenreliquie bei voller Tasche nur ein ungeschützter Gegenstand ersetzt und dessen Verkaufswert gutgeschrieben. Sind alle 20 Gegenstände geschützt, bleibt die Reliquie separat in Lager, Tasche und Ergebnisansicht zum Abholen stehen. Sie kann nach Freigeben eines Taschenplatzes genau einmal eingesammelt werden. Diese Reserve gilt auch bei Offline-Abrechnung und über Neustart sowie Backup hinweg. Sonstige überzählige neue Beute wird weiterhin automatisch verkauft; vorhandene geschützte Ausrüstung bleibt erhalten.

## Nach einer Niederlage weiterkommen

Die Ergebnisansicht zeigt den tatsächlich erreichten Raum beziehungsweise den verbleibenden Lebensanteil des erreichten Wächters. Gescheiterte Ash Trials behaupten nicht mehr, Gold oder XP ausgezahlt zu haben.

Eine passende nächste Handlung wird aus dem aktuellen Profil gewählt: freie Attributpunkte, ein sicheres Upgrade in der Tasche, eine passende noch ungenutzte Klassenreliquie oder bezahlbares Tempern. Die Schaltfläche öffnet die richtigen Kontrollen beziehungsweise gefilterten Gegenstände. Der Hinweis beschreibt eine vorhandene Verbesserungsmöglichkeit und behauptet keine unbelegte Todesursache.

Nach einer Niederlage oberhalb der ersten Etage lässt sich eine bereits freigeschaltete niedrigere Etage mit normalen Regeln wiederholt spielen. Der Lauf übernimmt keinen Schwur und keinen Hunt-Aufschlag. Er stoppt nach einer Niederlage; das separat konfigurierte Offline-Farmziel bleibt erhalten. Die Ansicht verspricht keine garantierte Siegrate.

## Online-Test repariert

Der lokale Nakama-Integrationstest lief mit `--fixed-fps 60`: Im ungebremsten Headless-Betrieb verstrich die simulierte Zeit schneller als die reale Netzwerkzeit und HTTP-Anfragen liefen in den Timeout. Der Integrationstest verwendet nun Echtzeit; reine Kampfsimulationen behalten ihre deterministischen Schritte.

Danach wurde ein tatsächlicher Fehler der Gemeinschaftssuche sichtbar: Nakama 3.41.0 verbietet die Kombination aus Namensfilter und Open-Filter. Namenssuchen verwenden jetzt nur den Namensfilter und entfernen geschlossene Gruppen aus der offenen Ergebnisliste. Die ungefilterte Übersicht nutzt weiterhin den serverseitigen Open-Filter. Der Integrationstest prüft zusätzlich eine geschlossene Gruppe und beide Suchvarianten. Die Solo-Beta erhält dadurch keine Online-Funktion und keine Internet-Berechtigung.

## Nachweise und Spieltest

[Lokaler Prüfbericht](audit/2026-10-02/gear-recovery-regression.json): 23 Godot-Suiten, nach abschließenden gezielten Prüfungen insgesamt 1.658 unterschiedliche bestandene Checks. Fünf Android-Release-Prüfungen und die serverseitigen Progressionstests bestanden ebenfalls.

- `tests/recovery_smoke.gd`: Verkaufsschutz, automatisches/manuelles Anlegen, Filter, volle Tasche, einmalige Abholung, Offline-Belohnung, Neustart, Backups und konkrete Folgeaktionen.
- `tests/cloud_transfer_e2e.gd`: 36 Prüfungen gegen lokalen PostgreSQL-16-/Nakama-3.41.0-Server; Gastkonten, serverseitiger Fortschritt, Backup, Transfer mit gesperrter Wiederverwendung, offene/geschlossene Gemeinschaften und persistenter Gruppenchat bestanden.
- `tests/android_success_flow.gd`: erste echte Klassenreliquie über UI-Signal schützen/anlegen, Taschenfilter bedienen und den Schutz zusammen mit dem Cinders-Checkpoint nach kaltem Neustart prüfen. Der Android-Workflow exportiert die zusätzlichen Ansichten.
- [QA-Ansichten](previews/gear-recovery/): Außenbildschirm-Verhältnis 1200 × 535, geöffnetes Verhältnis 1040 × 1080 und 854 × 480 mit großer Schrift. Die Niederlage wird mit normaler Startausrüstung auf einer absichtlich freigeschalteten späten Etage erzeugt. Das sind Oberflächentests, kein Werbematerial und keine Handy-Leistungsmessung.

Ergänzung für den [geschlossenen Spieltest](SUCCESS_PLAYTEST.md): Ohne Erklärung einen Gegenstand schützen, verkaufen versuchen, anlegen, wechseln und wiederfinden lassen. Nach einer Niederlage beobachten, ob der Vorschlag verstanden wird und zur gewünschten Verbesserung führt. Bei voller geschützter Tasche die zurückgehaltene Reliquie abholen lassen. Fehler, Hilfebedarf und Zeit bis zur nächsten bewussten Handlung protokollieren; keine weitere automatische Datenerfassung.
