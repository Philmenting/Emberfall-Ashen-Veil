# Sichtprüfung der Kampfbewegung 055

Diese unabhängige Prüfung vergleicht gezielte Bildfolgen aus den beiden vollständigen Aufnahmen: je 2.496 Frames, 83,2 Sekunden, gleicher erster Arcanist-Dungeon. Sie ist keine Echtzeit-Sichtung aller Einzelbilder und keine visuelle Releasefreigabe. Die erfolgreiche Simulation und die bestandenen Geometrieprüfungen werden nicht als Beleg für hochwertige Bewegung interpretiert.

Die zwölf geprüften MP4-Frames je Aufnahme sind **unveränderte Vollbild-PNGs aus der verlustbehafteten H.264-Dekodierung**, keine nativen Original-PNGs: `6, 7, 45, 46, 49, 50, 52, 54, 793, 794, 796, 799`. Zusammen belegen die temporären Dekodierungen 17.217.874 Bytes Scratchspeicher; es wurden keine Filmduplikate oder bearbeiteten Bilder in das Spiel übernommen. Die identischen Bildnummern lassen sich aus den unten verknüpften MP4s mit `select=eq(n\,FRAME)` und `-fps_mode passthrough` erneut dekodieren. Wiedergabezeit ist `FRAME / 30` Sekunden.

- [BEFORE-MP4](before/ordinary-arcanist-complete.mp4): SHA-256 `a7377a8c9b55d9c242d85e4942bf125a73f23bed42d6a724611950325565a16b`.
- [AFTER-MP4](after/ordinary-arcanist-complete.mp4): SHA-256 `4e3af95ae6bf92a27398cdbd6e6d6f39c45f6297515cd8f076b5492121fffa4e`.

Zusätzlich wurden die **nativen Original-PNGs** beider Aufnahmen an Frames `320, 347, 2039, 2099, 2153` und die ursprüngliche kurze 3-Sekunden-Probe geprüft. Der AFTER-Endzustand wurde am nativen Originalbild `2405` kontrolliert. Quellen und Aufnahmebedingungen stehen in den jeweiligen Receipts; die kurze Probe ersetzt keinen vollständigen Lauf.

| Szene und Bilder | Tatsächlicher Sichtbefund |
| --- | --- |
| Basiszauber, MP4-Dekodierungen 45–54; Originalbilder 44/51 | Die freie Hand geht aus der Vorbereitung in die ausgestreckte Ziellinie. Rechte Stützhand und Stab bleiben plausibel verbunden; in diesen Bildern ist kein neuer Griffversatz, kein gedehntes Gliedmaß und kein abgeschnittener Stab sichtbar. Die Änderung des Handverlaufs ist im Gesamtbild subtil. Der Torso und beide Boots bleiben sehr ruhig; es entsteht dadurch noch keine große, körperbetonte Angriffsbewegung. |
| Signatur, MP4-Dekodierungen 6/7; Originalbild 9 | Die höhere Sammelhaltung ist von der niedrigeren Basisphrase unterscheidbar. Der ausgeschnittene Gegner unmittelbar vor Nyra verdeckt einen Teil der Handbewegung; sein sichtbares Raster ist weiterhin auffällig. Aus den wenigen Handpixeln im Gesamtbild wird keine übertriebene Aussage über natürliche Beschleunigung abgeleitet. |
| Chain-Abbruch, MP4-Dekodierungen 793/794/796/799 | Der echte Evade-Abbruch geht in beiden Aufnahmen in einen aufrechten Gehschritt über. Die Stabhaltung bleibt erhalten; in der geprüften Folge ist kein einzelner sichtbarer Posebruch oder nachträglich ausgesendeter Zauber zu erkennen. Dies ist weiterhin eine Gehbewegung beim Ausweichen, keine eigenständige Dodge- oder Rollanimation. |
| Guardian, Originalbilder 2039/2099/2153 | Das Metall erscheint im AFTER dunkler und weniger plastikartig. Am Frame 2153 ist die Glocke weiter links neben dem Körper sichtbar und der Hieb leichter abzulesen. Nyra und der helle Stab bleiben bei Raumbeitritt und Warnung erkennbar; die kleine Spielfigur und das überlagerte Warnungs-/Effektbild begrenzen jedoch die Ablesbarkeit ihrer Oberkörperphrase. |

Die vollständigen Frame-Protokolle bestätigen den gleichen echten Chain-Abbruch an Frame 794 und denselben erfolgreichen Endzustand mit 357 Life. Ein einzelner gemessener Handpunkt ist jedoch kein Sichtnachweis für eine flüssige Figur: Diese Prüfung beurteilt dafür die dargestellte Figur und nennt die Grenzen ausdrücklich.

Die verbleibende sichtbare Qualitätslücke liegt besonders bei den Raiders: In den Originalbildern `00000` und `00044` bleiben die Körper kantig, die Köpfe nahezu gesichtslos und die Materialien flach. Die Überarbeitung hat deren ursprüngliche Modellgeometrie nicht ersetzt. Zusammen mit der überwiegend ruhigen Körperhaltung Nyras und dem einfachen Geh-Ausweichen verhindert das weiterhin eine Bewertung als Diablo-Immortal- oder veröffentlichungsreife Bild-/Animationsqualität.

Es wurden für diese Prüfung keine Engine gestartet und keine Spielquellen, Kameras, Simulationen, Materialien oder Animationsdateien verändert.
