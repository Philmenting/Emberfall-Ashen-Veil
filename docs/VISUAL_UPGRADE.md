# Grafischer Ausbau und flüssigere Animationen – 0.15

## Bewegung und Treffer (0.15)

Die zusätzliche Referenz *Nonstop Knight 2* lenkt den Blick auf den kontinuierlichen Lauf und die deutliche Schlagwirkung. Die Spielfigur und Gegner bewegen ihre Beine jetzt im Rhythmus ihrer tatsächlich zurückgelegten Strecke; Oberkörper, Arme und Mantel gleichen die Schritte aus. Im Stand halten leichte Atem- und Gewichtsbewegungen die Figuren lebendig.

Angriffe teilen sich in Ausholen, Trefferbewegung und Rückkehr zur Grundhaltung. Kommt ein weiterer Schlag während einer Pose, wird er eingereiht. Treffer lösen ein kurzes Taumeln aus; Stürze variieren leicht nach Rolle und Gebiet. Diese Änderungen wirken nur auf die Darstellung. Sie greifen weder in Kampfschritte noch Zufall, Belohnungen oder AFK-Fortschritt ein.

Sieben zusätzliche Animationstests kontrollieren Bewegungstakt, gegensätzliche Schritte, Schlagbewegung, Trefferreaktion, eingereihte Schläge und Fallpose.

## Gestaltung

Die schräge 3D-Kamera, düstere Ruinen, lesbare Gegnerrollen und sichtbare Waffen-/Zaubereffekte orientieren sich am bereits betrachteten Action-RPG-Spielablauf. Sämtliche neuen Modelle, Shader und Effekte wurden direkt in Godot erstellt. Es werden keine Diablo-Modelle oder -Texturen verwendet.

- **Figuren:** zusammenhängende elliptische Profilmeshes für Körper, Helme, Kapuzen, Roben, Armschienen, Klingen und Schilde. Schmalere Köpfe und angepasste Schultern lösen die bisher stark klobigen Proportionen ab. Zauberer tragen geschichtete Gewänder; normale Nahkampfgegner erhalten freiliegende Rippen und Krallen. Die drei Klassen haben unterschiedliche Angriffsposen.
- **Oberflächen:** eigene Shader unterscheiden rauen Stoff, abgenutztes Metall und körnigen Stein. Kontaktverschattung verankert Figuren am Boden. Gestaffelte, abgeschrägte Steinplatten ersetzen das gleichmäßige quadratische Raster der neuen Dungeon-Routen.
- **Architektur:** zusätzliche gotische Arkaden, tiefe Wandnischen, Sockel, mehrstufige Fundamente, Felsen und Trümmer geben den Räumen Tiefe. Wasser und Lava bleiben eigenständige animierte Flächen.
- **Atmosphäre:** schwebender Staub, bewegter Nebel unter den Wegen, animierte Flammensilhouetten, größere warme Lichtbereiche und ein zurückhaltendes Gegenlicht. Die Kamera rückt näher an die Figuren; der Randfilter wurde abgeschwächt.
- **Kampf:** kurze Waffenbögen und Funken ergänzen Treffer. Die Einblendungen bleiben lesbar, mit transparenteren dunklen Flächen und schmalen bronzenen Rahmen.

## Technik und Prüfung

Figuren behalten ihre beweglichen Gelenke. Starre Teile werden pro beweglichem Körperteil zu einem Mesh zusammengefasst und pro Erscheinungsbild zwischengespeichert. Ein gemeinsamer Shader liest Farbe, Metallanteil und Leuchtstärke aus den Vertex-Daten; unterschiedliche Rüstungs- und Stoffflächen benötigen dadurch keine eigenen Zeichenaufrufe. Auch die Profilmeshes werden wiederverwendet. Statische Architektur wird weiterhin gebündelt; Bodenplatten und Schmutzflächen berechnen keine unnötigen eigenen Schatten. Die Reichweite des gerichteten Schattens ist auf den sichtbaren Nahbereich begrenzt.

Die Kampfsimulation, Gegenstandswerte und Belohnungsregeln wurden für diesen Ausbau nicht verändert. Die zusätzlichen Effekte verwenden ausschließlich den visuellen Zufallszahlengenerator. Automatische Prüfungen kontrollieren auswärts gerichtete Modelloberflächen, nach oben gerichtete Steinplatten, alle Figurenrollen, Mesh-Wiederverwendung, unveränderte Kampfsnapshots, regionale Wasser-/Lavaflächen und das Entfernen kurzlebiger Effekte.

Der reguläre Android-Arcanist-Lauf wird mit unveränderter Startausrüstung aufgezeichnet. Die separate regionale Grafikprobe zeigt alle vier Gebiete und drei Klassen; sie erhöht Leben und Rüstung ausschließlich für die Darstellung und ist ausdrücklich kein Balance- oder Fortschrittsnachweis. Beide Test-Szenen sind aus den regulären Exporten ausgeschlossen.

## Nachweise

- **791 Prüfungen in 14 Suiten bestanden**, davon 42 Grafik-/Animationsprüfungen. Alle bestehenden 749 Prüfungen für Kämpfe, Beute, Speicherung, AFK und Expeditionen bleiben grün. Der GitHub-Android-Build mit diesen Prüfungen war erfolgreich.
- Android-Emulator API 36, 1280 × 720, OpenGL ES 3.0 über Intel UHD: ein regulärer Arcanist-Lauf mit Startausrüstung endet nach 72,9 Simulationssekunden erfolgreich, mit 380 Leben, 126 Mana und seltenen Veilwalker Treads.
- Während der Bildschirmaufnahme wurden nach 2/12/35/60 Sekunden 39/40/40/33 FPS und 430/574/519/452 Zeichenaufrufe gemessen. Das sind einzelne Momentaufnahmen, keine Mindest-FPS oder Messung auf einem Telefon. Die Beuteansicht erreichte 60 FPS.
- Die neue Bündelung der Figuren reduziert in der vergleichbaren frühen Szene die Zeichenaufrufe von etwa 940 auf 570. Der erste Shaderstart kann wegen einer Cache-Neukompilierung länger dauern.
- Alle zwölf Kombinationen aus drei Klassen und vier Gebieten wurden im separaten Android-Grafiktest erfasst. Wasser, Lava, regionale Bosse und Klassenmodelle sind enthalten.
- Das lokale Gameplay-Video `build/previews/emberfall-015-animation.mp4` enthält 30 Sekunden echte Android-Darstellung, 1280 × 720, H.264, ohne Tonspur; vollständig dekodiert geprüft.

## Grenzen

Dies ist ein eigener stilisierter Dark-Fantasy-Look. Individuell handmodellierte High-Poly-Figuren, aufwendige Gesichtsanimationen und der Detailgrad eines großen Studios sind damit nicht erreicht. Messungen im Emulator ersetzen keine Leistungsprüfung auf physischen Android-Geräten. Der vorhandene Battery-Modus reduziert Auflösung und Schatten für langsamere Geräte.
