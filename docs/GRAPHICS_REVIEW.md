# Grafiküberarbeitung: Ashen Veil

Die Figuren verwenden jetzt zusammenhängende anatomische Körper mit ausgearbeiteten Gesichtern und Fingern. Zwei glTF-Modelle ersetzen die bisherigen vereinfachten Körper. Jeder Körper besitzt 14.517 Vertices, 26.756 Dreiecke und sieben gewichtete Gelenke vor der Godot-Optimierung. Die sichtbare Körperoberfläche folgt den vorhandenen Bewegungen für Laufen, Angreifen, Treffer und Tod.

Die Vowkeeper-Rüstung erhält gebogene Brustplatten, geschichtete Schulterpanzer, Metallverzierungen, einen ausgeformten Schild und eine Klinge mit erhöhtem Mittelgrat. Arcanist trägt eine offene Kapuze, gefaltete Robe und einen neu gestalteten Stab mit Kristallfassung. Ranger erhält einen gebogenen Bogen mit Sehne und Pfeil, Lederrüstung, Köcher und Haarsträhnen. Gesicht und Hände bleiben unter der Ausrüstung sichtbar. Die Gegner verwenden die ausgearbeitete männliche Anatomie mit ihrer jeweiligen regionalen Gestaltung.

Sechs echte Materialtexturen für Stahl, Leder, Leinen, Haut, Knochen und Kalkstein ergänzen Geometrie und Licht. Die Haut nutzt eine Normalmap. Rüstung und Architektur erhalten gefiltertes Oberflächenrelief und wechselnde Rauheit aus den Texturen. Wasser, Basaltkruste und Glutrisse, Ruinengesimse und Nischen sowie die bereits überarbeitete Lichtführung bleiben Teil der Gesamtgestaltung.

Die Modellbasis und Morphdaten stammen aus ausdrücklich als CC0 freigegebenen MakeHuman-Assets. Die besondere Assetfreigabe ist von der Lizenz des Anwendungsprogramms getrennt. Es wurde kein MakeHuman-Anwendungscode übernommen. Herkunft, eingefrorene Quellstände, vollständige CC0-Freigabe und Texturprompt stehen in [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md). Der unabhängige Konverter tools/build_anatomy.py erzeugt die beiden Modelle aus geprüften Originaldaten neu.

Diablo Immortal dient als gestalterische Referenz für einen düsteren Action-RPG-Look. Das Spiel erhält eigene Rüstung, Waffen, Materialien und regionale Gestaltung. Es werden keine Blizzard-Assets übernommen. Für die eigenständige Gestaltung wurde [§ 23 Absatz 1 UrhG](https://www.gesetze-im-internet.de/urhg/__23.html) berücksichtigt.

Der Workflow Graphics Review prüft Import, gewichtete Gelenke, endliche Geometrie, die Weitergabe der Kampfposen an das sichtbare Modell, Regionen, Dungeon, Optionen und Kampfbewegungen. Er rendert alle zwölf Kombinationen aus vier Gebieten und drei Klassen, drei frontale Figurenansichten und vier separate Bossansichten. Dieselbe Aufnahmeszene läuft auf dem unveränderten Ausgangsstand 610c343073e7186589cba92c3fefb55a4db68e12.

Die Vergleichsbilder sind echte Godot-Aufnahmen. Die Bossansichten verwenden eine stationäre Testaufstellung im letzten Raum. Der Software-Renderer eignet sich zur Prüfung von Darstellung und Shadern. Die Leistung auf physischen Android-Geräten wurde in dieser Umgebung nicht gemessen. Die neuen Modelle benötigen zusätzliche Geometrieverarbeitung und Texturspeicher.

Die Aufnahmeszene verwendet isolierte Testdaten. Die Kampfsnapshots werden vor und nach dem Aufbau verglichen. Der Battery-Modus schaltet Glow, Lichtstrahlen und Schatten ab und verwendet weiterhin eine geringere Renderauflösung. Reduced Motion behält seine vorhandene Wirkung auf Kameraimpulse und Zoom.
