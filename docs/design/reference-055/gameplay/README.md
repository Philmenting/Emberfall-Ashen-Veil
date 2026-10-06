# Durchgehender Spielvergleich mit Ton

Beide Aufnahmen sind vollständig abgeschlossen und geprüft. Sie zeigen den ersten Arcanist-Dungeon ohne Schnitte vom ersten Kampf bis zur sichtbaren Beuteanzeige, jeweils mit Spielton. Beide Aufnahmestarter endeten tatsächlich mit Exit 0; die vollständige Bild-/Ton-Dekodierung ist erfolgreich.

| Aufnahme | Quellstand | Umfang |
| --- | --- | --- |
| [Vorher: Stand 054](before/ordinary-arcanist-complete.mp4) | `4b152d0fc8b99cf51569585af2695bf3554416ed` mit fünf dokumentierten Aufnahme-Overlays | 2.496 Bilder, 83,2 Sekunden, Stereo-Ton |
| [Nachher: Stand 055](after/ordinary-arcanist-complete.mp4) | `ad4d50bb9dbdc07cea42e2306a79fc65bb642489`, alle 168 erfassten Eingaben exakt zugeordnet | 2.496 Bilder, 83,2 Sekunden, Stereo-Ton |

## Gleicher Spielablauf

Die Aufnahme zeigt eine gewöhnliche erste Arcanist-Expedition mit sechs Stationen, Reise, Kämpfen, Bell Warden und Beuteanzeige. Chain und Starfall werden durch die normale Armory-Aktion ausgewählt. Startausrüstung, Lebenspunkte, Schaden und Gegnerwerte werden nicht überschrieben. Das ursprüngliche Main-HUD, die Weltkamera und die Spieleffekte bleiben sichtbar; Reiseabschnitte werden nicht herausgeschnitten. Ein Aufnahmefixture steuert die normalen Aktionen und schreitet mit festen 1/30-Sekunden-Schritten fort. Das ist ein reproduzierbarer Spielablauf, keine menschliche Touch-Abnahme.

Beide Läufe enden nach 80,2 Simulationssekunden mit besiegtem Wächter, 26 besiegten Gegnern, zwölf Fertigkeitseinsätzen, drei Ausweichmanövern, +428 XP und +190 Gold. Danach bleiben 90 Aufnahmeschritte für den ursprünglichen verzögerten Wechsel zur Beuteanzeige erhalten. Die beiden letzten dekodierten Bilder zeigen tatsächlich „DUNGEON CLEARED“ und die Klassenreliquie Veilglass Conductor. Beide gesamten MP4-Dateien lassen sich mit Bild und Ton fehlerfrei dekodieren.

Der [vollständige Vergleich](comparison.json) bestätigt identische Startwerte, Seeds, Fertigkeitsauswahl und autoritative Simulationsspur über alle 2.496 Frames. Beide Läufe enthalten 19 bestätigte Angriffe, 18 Auslösungen und einen echten Ausweich-Abbruch. Die neue Darstellung wird damit am selben Spielablauf beurteilt; Pose und Darstellung gehören nicht zur autoritativen Simulationsspur.

Die unveränderte Kamera regelt beim Raumeintritt ein und zieht bei zwei realen Wächterwarnungen einmalig entlang ihres Auslegers zurück. Sie pendelt dabei nicht zurück. Die letzten 108 Wächter-Kampfbilder besitzen exakt dieselbe Kameraposition und -basis in beiden Läufen, einschließlich Warnungen und tatsächlicher Treffer. Das belegt stabile Teilintervalle; der gesamte Kampf wird nicht als statisch bezeichnet. Die [Analysebeschreibung](ANALYSIS.md) erklärt diese Grenze.

## Herkunft von Bildern und Ton

Godot 4.7.2 rendert die unveränderten 1.200 × 536 Pixel großen Originalbilder mit dem Compatibility-Renderer auf Linux/llvmpipe. Die unter `selected-frames/` aufbewahrten PNGs sind unveränderte native Einzelbilder. Das MP4 enthält die vollständige chronologische Bildfolge mit verlustbehafteter H.264-Kompression. Die separat gespeicherte `decoded-ending-frame-02495.png` stammt aus dem fertigen MP4 und ist ausdrücklich kein zusätzliches natives Originalbild. Sie bestätigt die tatsächlich sichtbare Beuteanzeige; der bloße Wechsel des internen Seitenzustands wird nicht als sichtbare Anzeige gezählt.

Der AudioDirector meldet die tatsächlich akzeptierten Musik- und Effektstreams samt sechs Effektplätzen, Lautstärke und Pausenstatus. Native Godot-Decoder mischen daraus passend zur 30-Hz-Aufnahme Stereo-PCM mit 44.100 Hz; FFmpeg kodiert diese Spur als AAC im MP4. Jeder Lauf enthält genau 3.669.120 Stereo-Sampleframes für 83,2 Sekunden, 68 akzeptierte Cues und 67 natürliche Effektenden. Beide originalen PCM-Spuren sind byteidentisch. Die unveränderten PCM-Bytes liegen zusätzlich verlustfrei als `native-game-audio.f32le.gz` vor; daraus lässt sich der [Analysehelper reproduzieren](ANALYSIS.md). Der unabhängige Nachher-Scan prüft sämtliche Samples auf endliche Werte.

Dies ist eine native Mischung mit fester Aufnahmeuhr. Eine physische Lautsprecheraufnahme oder die Echtzeit-Ausgabe des AudioServers wird damit nicht belegt. Readback-, PNG- und Exportwartezeiten messen keine Spiel-Framerate.

## Prüfnachweise

- [Vorher-Receipt](before/receipt.json) und [Nachher-Receipt](after/receipt.json), ihre Metadaten, Spielzusammenfassungen und vollständigen `frames.jsonl` dokumentieren die tatsächlichen Läufe.
- Die [Vorher-Analyse](before/analysis.json) und [Nachher-Analyse](after/analysis.json) verifizieren Quellen, Zeitfolge, sechs Stationen, akzeptierte Angriffe, Kamera und Wächterkampf. Von 158 Referenzeingaben stimmen 153 exakt mit dem ursprünglichen Git-Stand überein; die fünf ausschließlich für Aufnahme und Audio verwendeten Overlays stehen in der [Baseline-Provenienz](before/baseline-provenance.json). Nachher stimmen alle 168 Eingaben exakt mit `ad4d50b` überein. Beide Quellenbestände blieben während ihrer Aufnahme unverändert.
- Die [Vorher-](before/ending-frame-receipt.json) und [Nachher-Endbildnachweise](after/ending-frame-receipt.json) binden die aus den MP4-Dateien dekodierten letzten Bilder an die vollständigen Aufnahmen.
- Die PCM-Archive besitzen [Vorher-](before/native-pcm-archive-receipt.json) und [Nachher-Hashes](after/native-pcm-archive-receipt.json); der [unabhängige vollständige PCM-Scan](after/independent-pcm-verification.json) ergänzt den Mixer-Nachweis.
- Der [gezielte Bewegungsvergleich](MOTION_REVIEW.md) beschreibt die geprüften dichten Angriffs-/Abbruchfolgen und die sichtbaren Grenzen im normalen Bildausschnitt.
- Die [abschließende Integritätsprüfung](evidence-integrity-receipt.json) verifiziert beide Filme, Framechroniken, jeweils 22 native PNGs, die verlustfreien PCM-Archive und die Endbilder. Tatsächliche Reproduktionen aus den abgelegten Dateien sind für [Vorher](before/analysis-reproduction-receipt.json) und [Nachher](after/analysis-reproduction-receipt.json) erfolgreich.

Die vollständigen Gameplay-Videos zeigen Arcanist im ersten Dungeon. Die drei nativen Klassen und die übrigen Regionen haben separate [Klassenprüfungen](../classes/README.md) und [unveränderte Android-Aufnahmen](../android/README.md). Dieser Vergleich bestätigt weder Handy-Framerate noch Wärme, Akku, Fingerbedienung oder eine allgemeine visuelle Veröffentlichungsreife. Die Gegner verwenden weiterhin ihre vorhandenen modularen Modelle; die Durchsichtbarkeit bei verdeckten Figuren und die geringe Gesichtsdetailtiefe bleiben sichtbare Qualitätsgrenzen.
