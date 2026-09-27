# Vier Gebiete – Version 0.5

Die gemeinsame, automatisch begehbare Route erhält vier eigenständige Gestaltungen. Gebiet 1 beginnt auf Etage 1, Gebiet 2 auf 11, Gebiet 3 auf 21 und Gebiet 4 auf 31. Die Wege und Kampfpakete bleiben bislang gleich; unterschiedliche Bossmechaniken und weitere Routen sind noch offen.

| Gebiet | Umgebung | Bossmerkmale |
|---|---|---|
| Hollow Spire | Kalter Stein, Bögen, Sarkophage, Banner, geborstene Glocke | Bell Warden mit Glockenschultern |
| Sunken Archive | Wasser, feuchter Stein, Bücherregale, Schilf, Geisterlicht | Silt Abbot mit Mitra und langer Robe |
| Crow Ossuary | Offene Knochenbögen, Kristalle, Knochenfelder, violetter Nebel | Mourning Queen mit gezackter Krone und Knochenfortsätzen |
| Last Ember Citadel | Lava unter der Festung, Öfen, Gitter, Ketten, Kronentor | Cinder Sovereign mit Ofenschloten und glühender Brustplatte |

Alle Modelle, Dekorationen und Shader sind direkt in Godot erstellt. Es werden keine Texturen, Modelle oder anderen Dateien der Diablo-Vorlage verwendet. Gebietspaletten und Gegnernamen liegen in `scripts/dungeon_theme.gd`; Wasser/Lava in `assets/shaders/dungeon_water.gdshader`.

## Optimierung

Statische Primitive werden pro Raum, Material und Geometrie gebündelt. Bei Figuren werden nur starre Teile innerhalb derselben Gelenke zu gemeinsamen Meshes zusammengeführt. Gelenke und deren Animation bleiben erhalten. Dadurch sinkt die Zahl der Zeichenaufrufe, ohne die Silhouette zu vereinfachen.

## Nachweise vom 27.09.2026

- 50 Kampf-/AFK-Prüfungen, 68 Speicherprüfungen und 36 Gebietsprüfungen erfolgreich: **154 Prüfungen, 0 Fehler**.
- Vier native Vergleichsaufnahmen ohne Render-/Skriptfehler.
- Acht Android-Aufnahmen mit laufendem Kampf: vier normale Begegnungen und vier Bossräume; keine Skriptfehler.
- Android-Emulator API 36, x86_64, 1280×720, OpenGL Compatibility, integrierte Intel-Grafik des Entwicklungsrechners. Erhöhte Helden-Lebenspunkte in der separaten Testszene halten spätere Gebiete für die Grafikmessung am Leben. Dies ist kein Nachweis für die Spielbalance.

Kurzer Vergleich vor/nach dem Zusammenführen starrer Figurenteile:

| Szene | Mittlere momentane FPS vorher | danach | Zeichenaufrufe vorher | danach |
|---|---:|---:|---:|---:|
| Spire, Gruppe | 45,2 | 50,8 | 1498 | 959 |
| Archiv, Gruppe | 42,8 | 48,7 | 1288 | 872 |
| Ossuarium, Gruppe | 43,6 | 50,8 | 1229 | 813 |
| Zitadelle, Gruppe | 41,8 | 49,5 | 1272 | 856 |
| Spire, Boss | 57,8 | 59,7 | 840 | 555 |
| Archiv, Boss | 52,7 | 59,0 | 884 | 596 |
| Ossuarium, Boss | 53,4 | 59,0 | 871 | 565 |
| Zitadelle, Boss | 54,7 | 56,8 | 891 | 597 |

FPS sind kurze Stichproben (arithmetisches Mittel von 1/Framezeit, nach zwei Sekunden Aufwärmzeit); die Zeichenaufrufe stammen jeweils aus dem Aufnahmeframe. Emulator, Shader-Cache, Gegnerbewegung und Rechnerlast beeinflussen die Werte. Diese Messung ist keine Garantie für 60 FPS auf realen Smartphones und kein Dauerlasttest.

Die Fixture `tests/android_regions.tscn` wird nur in einem separaten Paket verwendet und ist in den normalen Exportprofilen ausgeschlossen. Sie speichert `region-0.png` bis `region-7.png` im eigenen `user://`-Verzeichnis. Die reguläre Hauptszene bleibt `Main.tscn`.
