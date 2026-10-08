# Durchgehende Arcanist-Expedition 054

[Die vollständige Aufnahme](ordinary-arcanist-complete.mp4) zeigt den gewöhnlichen ersten Abstieg vom Start bis zur tatsächlichen Beuteanzeige: **2.496 chronologische Frames, 83,2 Sekunden Wiedergabe**. Der Wächter fällt nach 75,4 Sekunden Simulation, die Expedition endet erfolgreich nach 80,2 Sekunden mit 357 von 380 Life.

Quellstand: `c788464aa95ae91c29ffcf13e60deba319889335`. Gewöhnliche Anfangsausrüstung, Seed 1979; Chain und Starfall sind über die reguläre Armory ausgewählt. Keine erhöhten Kampfwerte oder übersprungenen Reiseabschnitte.

- [Receipt](receipt.json): unveränderte Quellen-Hashes, vollständige MP4-Dekodierung, Framezahl und SHA-256.
- [Metadaten](capture-metadata.json): Ausrüstung, Renderer und genauer Umfang der Aufnahmeszene.
- [Zusammenfassung](capture-summary.json), [Auswertung](analysis.json) und [Frameprotokoll](frames.jsonl): echte Simulation, Angriffe, Treffer, Guardian-Warnungen und Kamera.
- [Wächter beim Betreten](selected-frames/frame-02039.png), [erste Requiem-Warnung](selected-frames/frame-02099.png) und [Starfall in der letzten Phase](selected-frames/frame-02153.png) sind unveränderte native PNGs. Alle 22 begrenzt ausgewählten Originalbilder stehen in `selected-frames`; ihre Hashes sind im Receipt enthalten.
- [Tatsächliche Ergebnisanzeige](decoded-result-frame-02495.png) ist Frame 2495 aus der H.264-Datei. Dieses Bild wurde aus dem Video dekodiert; es ist kein ursprüngliches natives PNG. [Provenienz](decoded-result-provenance.json).

Die feste Simulation und Wiedergabe laufen mit 30 Hz. Das Software-Rendering, Readback und PNG-Streaming benötigen mehr reale Zeit; dies ist **keine Messung der Geräte-FPS**. Die Aufnahme enthält kein Audio. Ihre Vollständigkeit ersetzt keine visuelle Freigabe oder einen physischen Android-Test.
