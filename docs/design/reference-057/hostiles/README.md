# Native Gegner 057

Hexer, Bulwark, Elite und alle vier Guardians verwenden jetzt dieselbe originale erwachsene Native65-Anatomie wie der geprüfte Raider aus 056. Kopf, Augen, Brauen, Bart, Hände, Füße, Knochenhierarchie und inverse Bindes bleiben erhalten. Eine gemeinsame Ranger-Kleidungsdatei ersetzt die alte Peasant-Tunika. Rollen unterscheiden sich durch Kapuze, Schulter- und Unterarmrüstung, Materialfarbe, ursprüngliche Projektwaffe und ihre gebundenen Zauber- beziehungsweise Klingenclips. Die Guardians teilen weiterhin diese Anatomie.

Die ursprünglichen Ranger-Ärmel enthielten Handschuhe, die über den separat geprüften Händen lagen. Der Offline-Builder schneidet diese Enden 10 mm vor dem ursprünglichen Handgelenk ab. Der Stoff liegt außerdem 4 mm entlang seiner Originalnormalen außerhalb des stellenweise deckungsgleichen nackten Unterarms. Bestehende Ärmel-UVs, Normalen und Gewichte bleiben erhalten; neue Randvertices interpolieren die Originalattribute. Diese begrenzten Kleidungsänderungen und ihre Quellen stehen im [Manifest](../../../../assets/models/hostiles057/manifest.json). Die übrigen Kleidungsflächen behalten ihre Originalgeometrie.

Die männliche Metallbrustplatte besitzt einen eigenen Geometrie-Cache und berücksichtigt die erhöhten Gurtstücke des ursprünglichen Ranger-Outfits. Ihr Abstand von 46 mm zur fitted Tunika ergibt in den tatsächlich gewichteten Aktions-, Treffer- und Todesposen mindestens **4,599 mm** freien Abstand zu Tunika und Gurt. Der Bulwark-Schild ist am Unterarm befestigt. Beim Tod setzen Körper, starre Waffe und Schild getrennt auf dem Boden auf; eine aus der tatsächlichen sichtbaren Kleidung und Rüstung berechnete Tabelle enthält 181 Samples pro Rolle. Bossphasen und besiegte Lesbarkeit verändern die sichtbaren, pro Actor duplizierten PBR-Materialien.

| Rolle | Sichtbare Dreiecke | Skinned MeshInstance-Teile | Starre Waffenteile |
| --- | ---: | ---: | ---: |
| Hexer | 28.506 | 11 | 5 |
| Bulwark | 22.162 | 14 | 4 |
| Elite | 22.114 | 13 | 4 |
| Guardian 0 | 24.494 | 13 | 2 |
| Guardian 1 | 29.392 | 12 | 5 |
| Guardian 2 | 29.070 | 12 | 5 |
| Guardian 3 | 22.138 | 13 | 3 |

Die Dreieckswerte zählen alle sichtbaren ursprünglichen Körperteile, Kleidungsflächen, Rüstungsteile und Waffen anhand der tatsächlichen Indices. Die im Rohlog verwendete Bezeichnung `visible_skin_surfaces` zählt MeshInstance-Teile. Die gemeinsame Kleidung enthält 13.460 Dreiecke; alle Rollen liegen unter der unveränderten 40.000-Grenze. Importierte LOD-Indices bleiben beim abgeleiteten Handmesh erhalten. Diese Inventarwerte beschreiben Geometrie und belegen keine Telefon-Framerate.

Die finale fokussierte Prüfung lief mit **Godot 4.7.2**, echtem Prozess-Exit 0 und ohne Script-, Shader- oder Engine-Fehler:

| Prüfung | Ergebnis | Originalbeleg |
| --- | --- | --- |
| Neuimport der korrigierten Assets | Exit 0, keine Engine-Fehler | [Log](import-separated-sleeves.log), [Receipt](import-separated-sleeves-receipt.json) |
| Native-Hostile-Smoke | **3.775 Checks, 0 Fehler** | [Log](native-hostile-smoke-separated-sleeves.log), [Receipt](native-hostile-smoke-separated-sleeves-receipt.json) |
| Zusätzliche lebende Prop-Bodenprüfung | 49 weitere tatsächliche Posen, insgesamt 3.824 Checks / 0 Fehler; minimal 39,429 mm Prop-Freigang | [Log](living-prop-floor-audit.log), [Receipt](living-prop-floor-audit-receipt.json), [unveränderter Testquelltext](living-prop-floor-audit.gd.txt) |
| Unabhängiger finaler Offline-Neubau | Exit 0; alle 14 GLB-, Manifest-, Grounding- und Lizenzdateien byteidentisch | [Log](reproduction-final.log), [Receipt](reproduction-final-receipt.json) |
| Native Studio-Aufnahme | Exit 0; **28 unveränderte 1000 × 1000 PNGs** | [Log](native-hostile-preview.log), [Hashes und Receipt](native-hostile-preview-receipt.json) |

Die Handprüfung rekonstruiert originale, tatsächlich indexierte und mit allen vier Einflüssen gewichtete Hautdreiecke. Gegen die tatsächlichen Griffdreiecke ergeben 49 Posen maximal **0,769 mm** Eingriff, **1,874 mm** Fingerabstand und **2,390 mm** Daumenabstand. Die bestehenden Grenzen von 1 mm Eingriff und 3 mm Kontaktabstand bleiben bestehen; drei Fingerkontakte müssen dem Daumen gegenüberliegen. Hinzu kommen alle 65 Bone-Translations und Skalierungen, Release-Anschluss, reale Hit_Chest-Reaktion, Bodenhöhe, unveränderte autoritative Actor-Position, Materialwiederherstellung und Unabhängigkeit eines gleichartigen lebenden Actors.

Alle 28 finalen Studio-PNGs wurden direkt angesehen. Die gefundenen deckungsgleichen Ärmel und durchstehenden Gurtstücke sind in den finalen Aufnahmen beseitigt. Guard, Load, Release und Death zeigen vollständige Figuren und starre, geschlossene Griffe. Das Studio nutzt die tatsächlichen Laufzeitmeshes und gebundenen Originalclips, eine feste Kamera sowie Licht auf den tatsächlichen Actor-Ebenen. Der Renderer ist OpenGL Compatibility mit Mesa llvmpipe; Dummy-Audio wurde ausdrücklich gewählt. Die Aufnahmen sind eine gezielte Modellkontrolle. Durchgehende normale Expeditionen und die gesamte Produktionsabnahme werden separat in Qualität 057 dokumentiert.

| Rolle | Guard | Load | Release | Death |
| --- | --- | --- | --- | --- |
| Hexer | [PNG](native/hexer-guard.png) | [PNG](native/hexer-load.png) | [PNG](native/hexer-release.png) | [PNG](native/hexer-death.png) |
| Bulwark | [PNG](native/bulwark-guard.png) | [PNG](native/bulwark-load.png) | [PNG](native/bulwark-release.png) | [PNG](native/bulwark-death.png) |
| Elite | [PNG](native/elite-guard.png) | [PNG](native/elite-load.png) | [PNG](native/elite-release.png) | [PNG](native/elite-death.png) |
| Guardian 0 | [PNG](native/guardian_0-guard.png) | [PNG](native/guardian_0-load.png) | [PNG](native/guardian_0-release.png) | [PNG](native/guardian_0-death.png) |
| Guardian 1 | [PNG](native/guardian_1-guard.png) | [PNG](native/guardian_1-load.png) | [PNG](native/guardian_1-release.png) | [PNG](native/guardian_1-death.png) |
| Guardian 2 | [PNG](native/guardian_2-guard.png) | [PNG](native/guardian_2-load.png) | [PNG](native/guardian_2-release.png) | [PNG](native/guardian_2-death.png) |
| Guardian 3 | [PNG](native/guardian_3-guard.png) | [PNG](native/guardian_3-load.png) | [PNG](native/guardian_3-release.png) | [PNG](native/guardian_3-death.png) |

Die verworfenen Prüfläufe und ursprünglichen PNGs bleiben byteerhalten. [Ausgewählte originale Fehlerbilder und Rohlogs](rejected/) sowie ein [Hashinventar der aufbewahrten Originaldateien](rejected/preserved-original-index.json) dokumentieren die Korrekturen. Insbesondere der 44-mm-Plattenversuch unterschritt während der echten Hit-Overlay-Pose den unveränderten 3-mm-Freigang und wurde verworfen. Diese Zwischenläufe sind keine finale Source-Abnahme. Der [eigene Quellstand](owned-source-snapshot.json) bindet die fokussierten Belege an die geprüften Gegnerdateien; der endgültige Commit steht in der zentralen Qualitätsdokumentation.

Die Körper- und Kleidungsquellen stammen aus den erhaltenen Quaternius-Paketen. Rohquellen und Lizenzdateien bleiben erhalten: [Basis](../../../../assets/models/hostiles057/BASE-LICENSE.txt), [Outfit](../../../../assets/models/hostiles057/OUTFIT-LICENSE.txt), [Animation 1](../../../../assets/models/hostiles057/ANIMATION1-LICENSE.txt), [Animation 2](../../../../assets/models/hostiles057/ANIMATION2-LICENSE.txt). Die gehaltenen Waffen stammen aus den bereits vorhandenen Emberfall-Projektmodellen und werden im Manifest ausdrücklich so benannt. [Builder](../../../../tools/art/build_hostiles057.py) und [Smoke-Test](../../../../tests/native_hostile_smoke.gd) bleiben reproduzierbar im Repository.
