# Set-Ziele und geprüfte Taschenbereinigung

Dieser Ausbau baut auf dem neuesten Stand des offenen Release-Branches auf:
0.41 mit gemalten Figuren, kontinuierlichen Animationen, kombinierten Schwüren
und mehrphasigen Wächtern. `main` stand bei der Sichtung noch auf 0.38.

Die nächsten Verbesserungen konzentrieren sich auf Entscheidungen zwischen
Expeditionen: ein nachvollziehbares Ausrüstungsziel, verständliche Effektwechsel
und weniger einzelne Verkäufe nach einer AFK-Rückkehr.

## Set-Ziele im tatsächlichen Spiel

Unter **Gear → Equipment → Regional Sets & Hunt Goals** zeigt jede Region die
angelegten Teile, den Drei-Teile-Bonus und bereits vorhandene Taschenfunde in
fehlenden Slots. Mehrere Funde desselben Slots zählen nur einmal. Die
Set-Auswahlregel bleibt gleich: die meisten angelegten Teile gewinnen, bei
Gleichstand die frühere Region. Ein Set mit drei Teilen ist deshalb nicht
zwangsläufig das aktive Set.

**Review Set Pieces in Bag** öffnet die echten Gegenstände mit einem Set-Filter.
**Prepare … Hunt** wählt einen noch nicht angelegten oder in der Tasche
vorhandenen Slot auf der einfachsten bereits abgeschlossenen Etage der Region
und öffnet **World → Hunts**. Dort sind Gegnerverstärkung und tatsächliche
Farm-Prognose sichtbar; erst **Start Selected Farm** startet den Lauf.
Die Auswahl gilt auch für AFK. Alte AFK-Zeit wird zuerst mit dem vorherigen
Farmziel abgerechnet. Ein noch nicht abgeschlossenes Gebiet lässt sich auf
diesem Weg nicht farmen. Die Lagerübersicht führt ebenfalls zu den Set-Zielen.

Ein Beispiel: Zwei angelegte Ashen-Vigil-Teile und ein passendes Paar Handschuhe
in der Tasche führen zur Prüfung dieser Handschuhe. Ein bereits vorhandener
Slot wird nicht nochmals als nächstes Jagdziel vorgeschlagen.

## Effekte vor dem Anlegen verstehen

Die Beutekarte nennt neben den bisherigen Zahlen ausdrücklich **Set Lost**,
**Set Activated**, **Signature Lost** und **Signature Activated**, einschließlich
der jeweiligen Wirkung. Bei einem Set-Wechsel erscheinen Verlust und Gewinn.
Eine fremde Klassenreliquie verspricht keinen Effekt für die aktuelle Klasse.

Ein drittes Set-Teil mit gleichen Werten kann jetzt als sicheres Upgrade gelten,
wenn es einen Set-Bonus aktiviert. Ein aktives Set, eine aktive Signatur und
geschütztes Equipment bleiben vor dem Sammelbutton geschützt. Alle fünf
Attribute werden ebenfalls verglichen: Mehr maximales Mana darf zum Beispiel
nicht einen Spirit-Verlust und damit schlechtere Mana-Rückgewinnung verdecken.

Der Sammelbutton beendet vor dem Anlegen dieselbe eingefrorene
Schwur-AFK-Konfiguration wie manuelles Anlegen und rechnet vorher verstrichene
Zeit mit den alten Werten ab. Ohne anlegbares Upgrade bleibt die Konfiguration
erhalten.

## Duplikate mit einer konkreten Verkaufsvorschau

**Gear → Bag → Review Duplicate Sales** listet eindeutig unterlegene oder
gleiche Duplikate aus der ganzen Tasche mit Einzelpreis und Gesamterlös.
Berücksichtigt werden alle Rohattribute, Rüstung, Gegenstandswert, Tier und
Qualität gegenüber dem jeweils angelegten Teil. Die Region muss identisch
sein, damit Optionen für andere Sets erhalten bleiben.

Geschützte Teile, Klassenreliquien, Epic/Legendary, verstärkte Teile,
Fremdklassen-Ausrüstung, andere Regionen und unbekannte Affixe werden nicht
vorgeschlagen. Die Prüfung ist bewusst konservativ; nicht vorgeschlagene
Gegenstände können weiterhin einzeln geprüft und verkauft werden.

Erst **Sell … Items** verkauft die angezeigte Liste. **Keep Gear & Return**,
Android Back und das Verlassen der Taschenansicht verwerfen die Vorschau.
Vor dem Verkauf werden die tatsächlichen Gegenstandsreferenzen, Werte,
Schutzflags, Klasse und Eignung erneut geprüft. Eine veraltete Liste verkauft
gar nichts. Ein zweiter Aufruf zahlt kein weiteres Gold aus. Es gibt keine
automatischen Verkäufe durch diese neue Funktion.

Die vorhandenen Spielstand- und Backup-Formate reichen für Set-Teile und
Jagdziel aus. Eine unbestätigte Verkaufsvorschau wird nicht gespeichert.
Kampfregeln, Dropwahrscheinlichkeiten und Inventarlimit bleiben bei diesem
Ausbau auf dem vorhandenen Stand.

## Prüfung

Die neue `gear_goals_smoke.gd` enthält 114 Prüfungen: konservativer Verkauf
über alle Klassen und Rohattribute, Abbruch und veraltete Vorschau, atomare
Auszahlung, Set-Gewinn/Verlust, Signaturwechsel, Spirit-Grenzfall, gesperrte
Regionen, echte Jagdregeln, Spielstand-Wiederaufnahme, eingefrorene AFK-Regeln
und native UI-Interaktionen in drei Displaygrößen.

Die vollständige Beta-Regression enthält nun auch diese Suite sowie die
vorhandene, bisher nur separat ausgeführte Animationssuite. **Gameplay Quality**
führt die gemeinsame Regression unabhängig vom Android-Paketbau auf GitHub
aus und bewahrt den Bericht auf. Das schützt auch Änderungen am offenen
Release-Branch.

Die [native Vorschau](../tests/gear_goals_preview.gd) verwendet ein isoliertes
Testprofil mit normalen Ausrüstungswerten und vorbereiteten Set-Zuordnungen.
Sie ist eine UI-Prüffixture, keine Aufnahme eines erspielten Fortschritts.
Sechs gerenderte Ansichten bei 854×480 / Large Text, 1200×535 und 1040×1080
wurden auf horizontales Überlaufen geprüft. Die Bilder liegen unter
[`previews/gear-goals`](previews/gear-goals).

Gezielte Wiederholung:

```bash
python3 scripts/run_beta_checks.py --suite gear_goals
godot --path . --audio-driver Dummy tests/gear_goals_preview.tscn -- --capture-dir=/tmp/emberfall-gear-goals-preview
```

Das Prüfergebnis und die Grenzen des Durchlaufs stehen im
[Prüfprotokoll vom 3. Oktober](audit/2026-10-03/gear-goals.md).
