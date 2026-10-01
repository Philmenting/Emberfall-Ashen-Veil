# Grafiküberarbeitung: Ashen Veil

Die Überarbeitung führt die vorhandenen Godot-Figuren und Dungeons zu einem detailreicheren Dark-Fantasy-Look. Die laufende Kampfsimulation, Gegenstandswerte, Speicherformate und Zufallsfolgen werden durch diese Änderungen nicht verändert.

## Figuren und Oberflächen

Die elliptischen Körperprofile verwenden analytisch berechnete, durchgehend geglättete Seitennormalen und getrennte Abschlussflächen. Wiederverwendete, abgeschrägte Meshes ersetzen scharfkantige Rüstungsteile. Geschichtete Schulterpanzer, Verschlüsse und Nieten ergänzen alle bekleideten Rollen. Die Vowkeeper-Rüstung erhält Brustplatten und ein eigenes Brustzeichen. Der Arcanist trägt zusätzliche Ketten und einen Fokus. Der Ranger erhält einen Schulterriemen und einen Köcher. Der Mantel besitzt modellierte Falten und zwei sichtbare Seiten.

Der gemeinsame Figuren-Shader unterscheidet Metall, Stoff, Leder, Haut, Knochen und leuchtende Elemente. Oberflächendetails werden bei kleinen Bildschirmflächen gefiltert, um Flimmern zu reduzieren. Starre Teile bleiben in ihren beweglichen Gelenken zusammengefasst. Die zusätzlichen Details führen dadurch nicht zu einem eigenen Zeichenaufruf pro Niete.

Eine eigene, nahtlose Godot-Rauschtextur erzeugt gröbere Steinstruktur, kleinere Poren und wechselnde Rauheit. Lava erhält dunkle Basaltkruste und langsam fließende Glutrisse. Wasser verwendet Wellenrelief mit korrekter Oberflächenorientierung und zurückhaltenden Reflexionen. Die Projektion folgt den Weltkoordinaten und funktioniert auf Böden und Wänden. Der Stein im Sunken Archive erhält zusätzlich feuchte Stellen. Die Normalenberechnung benötigt keine nachträglich importierten Tangenten.

## Räume und Licht

Abgeschrägte Architektur, Gesimse, Reliefs, Nischen und Randfundamente geben den Ruinen mehr Tiefe. Zusätzliche Details liegen überwiegend an den hinteren Raumgrenzen. Ein unsichtbarer Reflexionshimmel, abgestimmtes Haupt- und Gegenlicht, zurückhaltender Glow und sechs weiche Lichtstrahlen ergänzen die regionale Atmosphäre. Die Kamera rückt etwas näher heran. Die reguläre Darstellung verwendet vierfache Kantenglättung.

Der Battery-Modus schaltet Glow, Lichtstrahlen und Schatten ab. Er behält die vorhandene halbierte Renderauflösung und deaktivierte Kantenglättung. Reduced Motion behält seine bisherige Wirkung auf Kameraimpulse und Zoom.

## Prüfung

Der separate Workflow Graphics Review prüft den Godot-Import sowie Grafik, Regionen, Dungeon, Optionen und Kampfbewegung. Er rendert mit Godot 4.7.2 und dem Compatibility-Renderer alle zwölf Kombinationen aus vier Gebieten und drei Klassen sowie drei nähere Figurenansichten und vier separate Bossansichten. Dieselbe Aufnahmeszene läuft anschließend auf dem unveränderten Ausgangsstand 610c343073e7186589cba92c3fefb55a4db68e12.

Die Bilder im Workflow-Artefakt sind echte Godot-Aufnahmen. Die Bossansichten verwenden eine stationäre Testaufstellung im letzten Raum und belegen keine erspielte Kampagnenprogression. Der verwendete Software-Renderer eignet sich zum Prüfen der Darstellung und Shader. Seine Bildrate ist kein Leistungsnachweis für Android-Geräte. Die Aufnahmeszene verwendet isolierte Testdaten und wird wie die übrigen tests-Szenen aus regulären Exporten ausgeschlossen.

Die erweiterten Grafikprüfungen kontrollieren Normalen, Modellwiederverwendung, beidseitige Mantelflächen, wiederherstellbare Grafikeinstellungen und unveränderte Kampfsnapshots. Das vorhandene Android-Build-Verfahren bleibt zusätzlich aktiv.

## Gestaltungsreferenz und Grenzen

Diablo Immortal dient als Referenz für Lichtführung, Materialtrennung, Silhouetten und die Atmosphäre eines düsteren Action-RPG. Alle neuen Modelle, Shader und Oberflächen werden eigenständig im Projekt erzeugt. Die Gestaltung wahrt einen eigenständigen Abstand zur Referenz im Sinne von [§ 23 Absatz 1 UrhG](https://www.gesetze-im-internet.de/urhg/__23.html).

Die Änderungen erreichen keine nachgewiesene grafische Gleichwertigkeit mit Diablo Immortal. Für dessen Detailgrad wären insbesondere individuell modellierte und texturierte Figuren, aufwendigere Charakteranimationen, zusätzliche Umgebungsassets und eine Leistungsoptimierung auf physischen Zielgeräten nötig.
