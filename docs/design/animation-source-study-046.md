# Geprüfte Animationsquellen nach 0.46

Stand: 4. Oktober 2026. Diese Untersuchung ergänzt den offenen
[visuellen Review](graphics-review-046-final.md). Sie verändert den Spielcode
oder die ausgelieferten Animationen nicht.

Die kostenlosen Standard-Ausgaben der Quaternius Universal Animation Library
enthalten technisch nutzbare Schwertbewegungen. Sie liefern keinen Bogensatz.
Der einfache Zaubersatz löst die bemängelte Ganzkörperbewegung ebenfalls nicht.
Ein Paketimport allein schließt die Qualitätslücken deshalb nicht.

## Quellen und Lizenz

| Quelle | Tatsächlich geprüfter Inhalt |
|---|---|
| [Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html), [offizieller Download](https://quaternius.itch.io/universal-animation-library) | Standard-ZIP, 15.904.933 Bytes; 43 Clips je GLB/FBX, 65 Knochen; normale und Root-Motion-Dateien |
| [Universal Animation Library 2](https://quaternius.com/packs/universalanimationlibrary2.html), [offizieller Download](https://quaternius.itch.io/universal-animation-library-2) | Standard-ZIP, 18.735.003 Bytes; 43 Clips je GLB/FBX, 65 Knochen; normale und Root-Motion-Dateien |

Beide offiziellen freien ZIPs wurden ohne Konto oder Zahlung bezogen und
enthalten eine **CC0 1.0 Universal**-Lizenzdatei. Beide Standard-GLBs ließen sich
in einem isolierten Godot-4.7.2-Projekt laden; Blender 4.3.2 bestätigte dasselbe
Clipinventar für die FBX-Dateien. Das allgemeine Setup-Bild mit Bogen-Clips
belegt deren Verfügbarkeit nicht: In beiden freien Dateien fehlen sie.

ZIP-SHA256:

- UAL1: `cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724`
- UAL2: `4008ea208a604773a2b2177d965f0f5d3195498b5bf838c3f5785d68e95f2a68`

## Tatsächliche Bewegungen

Zeitfenster wurden aus 30-Hz-Quellkurven und Quellposen abgelesen. Sie sind
keine mitgelieferten Treffer-Marker und noch keine auf Emberfall übertragenen
Bewegungen.

| Clip | Bewegung und Dauer | Eignung |
|---|---|---|
| UAL1 `Sword_Attack` | 1,533 s; Vorbereitung bis etwa 0,333 s, absteigender Hieb bis 0,533 s, Nachlauf bis 0,80 s, danach Rückkehr; deutlicher Beinwechsel | Ausgangsmaterial für einen vollständigen Hieb |
| UAL2 `Sword_Regular_A` | 0,433 s plus 0,967 s Recovery; Absenken bis 0,20 s, aufsteigender Hieb bis 0,30 s | Bewegungsrichtung passt nicht zu einem absteigenden Hieb |
| UAL2 `Sword_Regular_B` | 0,533 s plus 1,033 s Recovery; beginnt im hohen Guard, absteigender Hieb etwa 0,133–0,30 s | Passendere Richtung; Übergang aus unserem Idle fehlt |
| UAL1 `Spell_Simple_Enter` | 0,533 s; linke Hand steigt um bis zu 87,6 cm, Becken bewegt sich nur 2,5 cm | Armhebe-Geste, keine kräftige Ganzkörperattacke |
| UAL1 `Spell_Simple_Shoot` | 0,500 s; kurze Bewegung aus bereits ausgestrecktem Arm, Handspannweite 6,7 cm, Becken 2,0 cm | Kein belegter Ersatz für die gewünschte Zauberbewegung |

## Erforderliche Übertragung und offene Grenzen

- **Skelett:** 65 Quellknochen müssen auf 29 native Knochen abgebildet werden.
  Drei Wirbelsäulensegmente werden auf unsere Brust zusammengeführt; Kleidung,
  Haare und Waffen brauchen eigene Kurven. Restposen, lokale Knochenachsen,
  Blickrichtung und Gliedmaßenlängen unterscheiden sich. Direktes Kopieren der
  Drehwerte wäre falsch.
- **Schritte und Griffe:** Ein fester Root bedeutet keine festen Füße. Der
  Schwertclip enthält reale Schritte. Dauerhaft festgehaltene Fußziele würden
  die Bewegung zerstören. Es fehlen Waffenmodelle und Waffenknochen; Griff,
  Klingenspitze, Schild und Bodenkontakt müssen auf der Zielfigur geprüft werden.
- **Zeitablauf:** Emberfalls übliche 0,30 s Vorbereitung, die bestehende um
  0,085 s vorgezogene sichtbare Geschossfreigabe und 0,34 s Rückkehr erfordern
  eine gezielte Anpassung je Phase. Bloße Beschleunigung des gesamten Clips
  würde den eigentlichen Hieb wieder auf wenige Bilder zusammenziehen.
- **Bewertung:** Erfolgreicher Dateiimport beweist keine bessere Animation.
  Ein sinnvoller nächster technischer Versuch wäre die isolierte Übertragung
  eines vollständigen Schwertangriffs mit Schritt- und Kontaktkurven. Erst ein
  Vergleich in der normalen Spielkamera könnte dessen Nutzen belegen. Für
  Bogen und kraftvolle Magie fehlt weiterhin geeignetes Ausgangsmaterial.

Die Untersuchung wurde durch einen Asset-Producer als Ersatz für die nicht
verfügbare spezielle Skill-Rolle durchgeführt. Keine fremden Animationsdateien
wurden in die Fassung 0.46 integriert; eine visuelle Verbesserung durch diese
Bibliotheken wird nicht behauptet.
