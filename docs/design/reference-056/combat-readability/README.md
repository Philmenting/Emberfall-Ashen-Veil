# Rasterfreie Verdeckung, Prüfung 056

Der frühere 4×4-Bayer-Cutaway ist aus `character_surface.gdshader` entfernt. Raider, Guardian und deren Waffen behalten ihre opaken Oberflächen und vollständigen ursprünglichen Schatten. Der zusätzliche Schattenkörper `UnmaskedBodyShadow` entfällt.

Ein separater, dezenter Sichtbarkeitspass zeigt ausschließlich Nyras tatsächlich verdeckte Körper-, Kleidungs- und Stabfragmente: dieselben Meshes, Skins, Skeletons und aktuellen Hand-/Proptransforms. Die originale PBR-Darstellung bleibt unverändert. Der warme, entsättigte Rand erhält nur wenig innere Füllung; es gibt kein Raster, keine pulsierende Farbe und keine Änderung an Kameraposition, Gegnerposition, Schaden oder Warngeometrie. Der Shader liest die vorhandene Szenentiefe. Direkt projizierte einzelne Bone-/Propbounds verhindern, dass ein hinterer Arm oder ein Kleidungsstück durch Nyras eigene opake Vorderseite scheint.

Die vier verlinkten Dateien sind originale PNGs aus Godot 4.7.2 im Compatibility-Renderer, normale UI bei 1200×536. Die Guardian-Inspektion besitzt zusätzliche Life. Die zweite Position ist eine bewusst erzeugte **Renderer-Überlappung**, keine tatsächlich gespielte Ausweichbewegung. Kamera und vollständiger Simulationssnapshot bleiben in dieser Inspektion unverändert.

- [Natürliche Position ohne Sichtbarkeitsakzent](boss-natural-opaque.png)
- [Natürliche Position mit Sichtbarkeitsakzent](boss-natural-reveal.png)
- [Gezielte Verdeckung ohne Sichtbarkeitsakzent](boss-overlap-opaque.png)
- [Gezielte Verdeckung mit Sichtbarkeitsakzent](boss-overlap-reveal.png)

Der akzeptierte native Lauf endet tatsächlich mit Exit 0 und enthält keine Script-, Shader- oder Compilefehler. Der finale gezielte Occlusion-Smoke besteht mit 25 Checks und 0 Fehlern. Der Guardian-Smoke besteht mit 274 Checks und 0 Fehlern; dieser Lauf liegt vor der abschließenden schwachen Füllung und der engeren Bone-Depth-Abgrenzung. Die finale Gesamtprüfung und die vollständige Kampfaufnahme werden im übergeordneten Qualitätsbeleg separat ausgewiesen.

Die finale Einschaltprüfung umfasst auch den tatsächlichen gehaltenen Stab, damit eine isolierte Waffenverdeckung den Akzent aktiviert. Diese Erweiterung wurde nach den Bildern ergänzt; in beiden abgebildeten Positionen war der Pass bereits eingeschaltet. Helper, Shader und Fixture der akzeptierten Bilder sind in [receipt.json](receipt.json) mit SHA-256 gebunden. Die gesamte parallel bearbeitete Spielquelle war während dieser einzelnen Probe noch nicht eingefroren.

Die ursprünglichen Logs behalten auch gescheiterte Versuche. Insbesondere ist der erste scheinbare Exit-0-Lauf nach einer parallel auftretenden Evade-Compilefehlermeldung **kein akzeptierter Beleg**. Erst der anschließende saubere Lauf `native-accepted.log` gilt als Rendererprüfung.

Die Bilder zeigen Verdeckung und Materialkontinuität, keine kontinuierliche Animationsbewertung und keine Messung auf einem physischen Android-Gerät. Ein konservativer Depth-Guard kann kleine Restverdeckungen innerhalb der vordersten Hero-Tiefe stehen lassen, damit Körperteile niemals durch Nyra selbst scheinen. Warnflächen werden nicht vom Sichtbarkeitsshader ausgeschnitten.
