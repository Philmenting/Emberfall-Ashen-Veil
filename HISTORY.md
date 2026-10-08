# Historische Entwicklungsberichte

Diese Berichte dokumentieren frühere Quellstände. Den aktuellen Entwicklungsstand beschreibt [README.md](README.md).

# Emberfall: Ashen Veil

## Teststand: 0.48.0-beta.1 · Raumanschlüsse und Stützbewegungen

Dünnere regionale Wände, tiefe Öffnungen, gebrochene Mauerkronen und bündig
angebundenes Pflaster ersetzen die bisherigen geschlossenen Raumblöcke.
Bodenanschlüsse folgen dem tatsächlichen Außenrand; innere Rechtecknähte
bekommen keine Fundamentseiten mehr. Steinmaterialien verwenden je eine
Texturgruppe mit exportierten Meter-UVs und Tangenten. Zauber und Bogen laden
Stützbein, Hüfte und Rumpf stärker und halten die Rückkehr zusammen. Arcanists
Geschoss startet an der linken Zauberhand; Schwertbewegung, Kampfzeiten,
Kamera und Spielregeln bleiben erhalten. Android-Version-Code **54**.

**Die Figurenrekonstruktion ist nicht fertig.** Beide isolierten Kostümproben
von Flare und MPFB/MakeHuman wurden verworfen. Keine ihrer Figuren, Texturen,
Rigs oder Shader wurde übernommen; alle elf 0.47-Modelle bleiben unverändert.
Die [Quellenbewertung](docs/design/figure-source-assessment-048.md) hält die
sichtbaren Mängel und den noch offenen Gestaltungsbedarf fest.

[Gameplay CI 37212951293](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37212951293)
besteht auf [Quellstand 850721f](https://github.com/Philmenting/Emberfall-Ashen-Veil/commit/850721fd010dd62ddbf1a6c681f73955ffddc8b3)
mit **34 Suiten, 3.642 Prüfungen, 0 Fehlern** und beiden Serverprüfungen.
Im [kontrollierten 0.47/0.48-Vergleich](docs/audit/2026-10-04/render-048/README.md)
sank die mediane Framezeit in allen Fällen: **44,0–51,1 % in Balanced** und
**11,8–18,1 % in Battery**. Das ist ein einziges sequenzielles Vergleichspaar
unter Linux/llvmpipe, keine Messung realer Telefon-FPS. Wärme, Akku, Eingabe
und dauerhafte Leistung auf dem Pixel 9 Pro Fold bleiben ungeprüft.

Das [native Belegpaket](docs/previews/constructed-world/README.md) ist
vollständig: **34 Ansichten, vier Clips und ein 24-Sekunden-Vergleich** mit
0.47. Vollständige Dekodierung, Framezahlen und eingefrorene Quellen sind
geprüft. Der Reiseclip zeigt die echte Lesepause und den Weg in die Kammer
Pilgrim’s Well; am Ende nähert sich Nyra noch dem Heilpunkt. Er belegt keine
Ankunft am Heilpunkt oder Heilung.

[Android-Build und Runtime-Versuch 2](docs/audit/2026-10-04/android-048/README.md)
bestanden auf demselben Quellstand. Das
[Testpaket-Archiv](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37214678280/artifacts/11307604661)
ist bis 18. Oktober 2026 verfügbar: **emberfall-closed-beta-ci.apk** ist das
Offline-Testpaket; **emberfall-debug.apk** gehört zum separaten Online-Test.
Die temporäre CI-Signatur belegt keine Update-Kompatibilität mit anderen
Signaturschlüsseln oder Veröffentlichung bei Google Play.

Runtime-Versuch 1 endete vor dem Emulatortest: Exporter-Code 250 nach dem
Asset-Import, zuletzt eine abgewiesene ADB-Daemon-Verbindung. Die genaue
Ursache ist nicht geklärt; Versuch 2 bestand ohne Quelländerung. Alle 28
Android-Bilder wurden geprüft, zwei Originale zusätzlich vollständig geöffnet.
Die Emulatorzeiten belegen keine realen Telefon-FPS.

Die [frische vollständige Prüfung](docs/design/graphics-review-048.md)
bestätigt gültige Belege, verlangt aber **Neuaufbau (`rebuild`)**. Offen bleiben:

- Fertige Körper-, Kleidungs- und Materialassets für alle elf Figuren.
- Glaubwürdige Übergänge vom Spielboden ins Umfeld sowie fertige Reliquiar- und Objektgestaltung.
- Lesbare Ganzkörperbewegungen für Zauber und Bogen auf den rekonstruierten Figuren bei normaler Kameragröße.
- Eine bessere Verteilung von Helligkeit und Materialdetail, damit die bewegten Figuren vor der Umgebung auffallen.
- Dauerhafte Leistung, Wärme, Akku, Touch/Zurück und Bildschirmeinpassung auf dem echten Pixel 9 Pro Fold.

Die dünnen gebrochenen Raumbögen, durchgängigen sichtbaren Wege, offenen
Becken, ruhige Kamera, vollständigen Warnflächen und UI-Zustände sind
bestätigte Stärken. Der Schwertablauf und die eng begrenzte Verbesserung der
Software-Renderzeit bleiben erhalten. Dieser Stand hat **keine visuelle oder
Veröffentlichungsfreigabe**. Nach dem zweiten Neuaufbau-Urteil auf gültigen
Belegen erfordert eine weitere Rekonstruktionsrunde zunächst die Rücksprache
mit dem Nutzer, sobald dieser Teststand als Commit und PR konkret vorliegt;
eine weitere Runde gilt hier nicht als begonnen oder abgeschlossen.

[Richtung und Grenzen](docs/design/graphics-direction-048.md),
[aktuelles natives Designsystem](DESIGN.md),
[Zauber-/Bogenbewegung und begrenzter Nachweis](assets/animations/bodyphrase-048/README.md).

## Vorheriger Teststand: 0.47.0-beta.1 · Sichtbare Angriffe und gebaute regionale Räume

Schwert, Stab und Bogen verwenden neue Schritt-, Lade- und Rückkehrkurven
bei unveränderten Kampfzeiten. Vowkeepers Schwertabläufe nutzen passend zum
nativen Skelett übertragene CC0-Grundlagen von Quaternius; Zauber und Bogen
bleiben eigene Abläufe. Neue Körper-, Hand-, Stiefel- und Kleidungsformen
umgeben Nyras erhaltenes gemeinsames Gesicht. Tiefe regionale Raummodule,
gefasste Archivbecken und ein eigenes Mauerwerksmaterial ergänzen den an den
Weg angepassten Boden. Die feste Kamera und echte Lesepause bleiben erhalten;
der deaktivierte Loot-Knopf behält jetzt Füllung und Beschriftungsabstand.
Porträts werden nur bei sichtbaren neuen Posen gezeichnet. Eine freiwillig
kopierbare Leistungsanzeige sammelt Framezeiten während des Spiels im Speicher.
Android-Version-Code **53**.

Die korrigierte Regression besteht mit **34 Suiten, 3.635 Prüfungen,
0 Fehlern** und beiden Serverprüfungen; außerdem bestehen die **404** gezielten
Korrekturprüfungen. Alle drei CI-Läufe für Gameplay, Android-Paketierung und
Android-16-Emulator bestanden auf
[Quellstand 2648672](https://github.com/Philmenting/Emberfall-Ashen-Veil/commit/2648672c4e7700ed57d223bd3a9fb7bf1e874491).
[CI-Belege und Testpakete](docs/audit/2026-10-04/android-047/README.md)
enthalten die genaue Reichweite. Die Pakete sind temporär CI-signiert;
eine Google-Play-Veröffentlichung oder Update-Kompatibilität mit anderen
Signaturschlüsseln ist nicht belegt.

Im [kontrollierten Vergleich auf demselben Rechner](docs/audit/2026-10-04/render-047/README.md)
war 0.47 in allen Fällen langsamer: **+47,0–81,3 % Framezeit in Balanced**,
**+11,0–30,3 % in Battery**, trotz weniger oder gleicher Zeichenaufrufe.
Das war ein einziges sequenzielles Vergleichspaar unter Linux/llvmpipe;
es belegt keinen Leistungsgewinn und ersetzt keine Messung auf einem Telefon.
Die getrennten Android-CI-Messungen stammen ebenfalls aus einem langsamen
Softwareemulator. Echte Geräte-FPS, Wärme, Akku und Touch bleiben ungeprüft.

Die [vollständige visuelle Prüfung](docs/design/graphics-review-047.md)
verlangt **Neuaufbau (`rebuild`)**. Die Figuren behalten eine zu glatte,
zusammengesetzt wirkende Anatomie und Kleidung; Bodenränder, massive
Wandkurse und Raumübergänge bilden noch keine glaubwürdig zusammenhängende
Welt. Schwertangriffe zeigen lesbaren Körpereinsatz. Bei Zauber und Bogen
bleiben koordinierte Hüft-, Stützbein- und Rückkehrbewegungen aus der normalen
Kampfkamera zu schwach. Figuren- und Materialgestaltung, Raumübergänge,
Zauber/Bogen und reale Telefonleistung bleiben offen. Gemeinsame Nyra-Identität,
ruhige Kamera, vollständige Warnflächen und die verbesserten UI-Zustände
bleiben erhalten.

Das [korrigierte Belegpaket](docs/previews/visible-combat/provenance.json)
ist vollständig: **34 native Ansichten, vier vollständig dekodierte Clips**
und ein abgeleiteter **24-Sekunden-Vergleich** mit 0.46. Die drei zuvor
betroffenen Sequenzen wurden vollständig neu aufgenommen; vier reine
Renderer-Vorlaufframes veränderten keine Kampfzeit. Alle zehn Segmentanfänge
sind befüllt und geprüft. Die Provenienz trennt die beiden korrigierten
Aufnahme-Helfer von unverändertem Spielcode und unveränderten Assets und hält
151 passende aktuelle Quellhashes fest. Die erste
[Neuaufnahme-Anforderung](docs/design/graphics-review-047-recapture.md)
bleibt archiviert.

Dieser 0.47-Stand ist ein abgeschlossenes Testergebnis, **keine visuelle oder
Veröffentlichungsfreigabe**. Eine weitere Umsetzungsrunde im beauftragten
Gesamtumbau wird vorbereitet. Frühere 0.46-Ergebnisse gelten nur für ihren
archivierten Quellstand.

[Richtung und Umfang](docs/design/graphics-direction-047.md),
[aktuelles natives Designsystem](DESIGN.md),
[Animierungsquellen](assets/animations/SOURCE.md),
[Geometrieherkunft](tools/art/CHARACTER_ASSETS_047.md).

## Vorheriger Teststand: 0.46.0-beta.1 · Angriffsbewegungen und zusammenhängende Ruinen

Die Überarbeitung setzt bei den tatsächlichen Kampfbewegungen und der begehbaren
Welt an: eigene Abläufe für Schwert, Stab und Bogen, passende Übergänge am
Geschossstart und geformte Rüstung, Hände und Stoffbahnen. Durchgehender
unregelmäßiger Steinboden, tiefe Wandnischen und regionale Hallen ersetzen die
freistehenden Bodenplatten. Die kompaktere Kampfleiste lässt mehr Raum für die
Figuren; Kamera, Warnflächen und Lesepause bleiben fest an das Spiel gebunden.
Android-Version-Code **52**. Die unabhängige visuelle Prüfung verlangt einen
weiteren Neuaufbau; dieser Stand hat keine visuelle Beta-Freigabe.
Die vollständige Regression mit **3.580 Prüfungen**, Android-Paketierung sowie
die Funktions- und Animationsprüfung im Android-16-Emulator bestehen auf
Quellstand `883d65e`. Eine Leistungsfreigabe für echte Telefone ist damit nicht belegt.

[Umsetzung und Prüfgrenzen](docs/SCENE_FINISH_046.md),
[Angriffe aller drei Klassen](docs/previews/scene-finish/emberfall-attacks-046.mp4),
[Review und Testbuild](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5).

## Vorheriger Ausbau: 0.45.0-beta.1 · Neue Gesichter, räumliche Ruinen und Materialien

Die Grafik folgt einer düsteren isometrischen ARPG-Richtung: eigene regionale
Umgebungen, verwitterter Stein, geschichtete Rüstung und örtliche Lichtquellen.
Schmiede, Expeditionstisch mit Karte und Portal sind echte 3D-Objekte. Eine
steilere feste Kampfperspektive hält Warnflächen und Fähigkeiten sichtbar.
Nyra erhält in allen drei Klassen eine neue zusammenhängende Gesichtsgeometrie,
geformte Augenlider, natürliche Lippen und feinere Haare. Die Live-Porträts
zeigen dieselben Modelle wie Lager und Kampf. Alle elf Figuren behalten ihre
nativen Skelettanimationen. Version-Code **51**.

[Umsetzung, native Ansichten und Prüfgrenzen](docs/GRAPHICS_OVERHAUL_045.md),
[Gameplay mit Lesepause](docs/previews/graphics-overhaul/emberfall-graphics-045.mp4),
[Review und Testbuild](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5).

## Vorheriger Ausbau: 0.44.0-beta.1 · Fähigkeiten sichtbar und Kampf in Ruhe verstehen

Die drei tatsächlich ausgerüsteten Fähigkeiten stehen während des Kampfes in
einer kompakten Leiste: bereit, am Wirken, Abklingzeit oder zu wenig Mana.
Antippen erklärt die jeweilige Regel und pausiert den Kampf. Schließen oder
Android-Zurück stellt den vorherigen Spielzustand wieder her; eine manuelle
Pause bleibt erhalten. Guard, Mana Ward, Lebensverlust und der Fortschritt
durch die Kammern sind direkt sichtbar. Kamera und Warnungsgeometrie halten
den Platz für die Leiste frei. Android-Version-Code **50**.

[Native Ansichten und Umsetzung](docs/COMBAT_READABILITY_044.md),
[Gameplay und echte Lesepause](docs/previews/combat-readability/emberfall-combat-044.mp4),
[Review und Testbuild](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5).

## Vorheriger Ausbau: 0.43.0-beta.1 · Vollständig animierte 3D-Figuren und ruhige Kamera

Alle elf Figuren verwenden echte beleuchtete 3D-Modelle, 29 Skelettknochen und
neun native Animationsclips. Nyra hat erwachsene Proportionen, ein durchgehendes
Gesicht, helle Haare und eng anliegende Rüstung. Schritte halten die Standsohle
am Boden; Schwert, Stab und Bogen laden, treffen und schwingen unterschiedlich
nach. Beim Fallen geben Knie, Hüfte und Schulter nacheinander nach, bevor Kopf
und Mantel ruhen. Lager, Porträts und Kampf teilen dieselben Figuren.

Die Kampfkamera wackelt bei Treffern und Zielwechseln nicht mehr. Unterwegs
bleibt Nyra auch auf dem aufgeklappten Bildschirm im Bild. Bogen und Zauber
lassen genau beim Start des sichtbaren Geschosses los; der tatsächliche Schaden
bleibt unverändert. Android-Version-Code **49**.

[Gameplay mit Schwert](docs/previews/characters-3d/emberfall-vowkeeper-043.mp4),
[Stab](docs/previews/characters-3d/emberfall-arcanist-043.mp4),
[Bogen](docs/previews/characters-3d/emberfall-ranger-043.mp4),
[Bewegungsprüfung aller Figuren](docs/previews/characters-3d/emberfall-motion-043.mp4),
[Umsetzung und Prüfgrenzen](docs/CHARACTERS_3D_043.md),
[Review und Android-Pakete](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5).

## Vorheriger Ausbau: 0.42.0-beta.1 · Ganzkörperbewegung und lesbarerer Kampf

Alle elf Figuren verlagern bei Angriffen Gewicht zwischen Hüfte, Rumpf und
Beinen. Dreidimensionale Rumpfdrehung, ein klarer geladener Moment und
Nachschwingen geben Schwert, Stab und Bogen mehr Körperlichkeit. Anhalten setzt
die Füße nacheinander auf; Treffer folgen Richtung und Stärke, beim Fallen geben
zuerst die Knie nach. Nyra und ihr tatsächliches Ziel werden hervorgehoben,
Hintergrundkämpfer und gefallene Figuren treten zurück. Die Kampfsimulation
bleibt unverändert. Android-Version-Code **48**.

[Vorher/Nachher-Video](docs/previews/animation-craft/emberfall-motion-comparison.mp4),
[neuer Gameplay-Clip](docs/previews/animation-craft/emberfall-gameplay-042.mp4),
[Umsetzung, Prüfungen und Geräte-Grenzen](docs/ANIMATION_CRAFT_042.md).

## Neu im Entwicklungsbranch: klare Set-Ziele und geprüfte Beuteverwaltung

Die Schmiede zeigt regionale Set-Fortschritte, vorhandene Taschenfunde und
gezielte Jagden auf fehlende Slots. Beutevergleiche erklären Set- und
Signaturwechsel. Unterlegene Duplikate lassen sich mit einer konkreten
Verkaufsvorschau gesammelt verkaufen; wertvolle Build-Optionen bleiben
geschützt. Sichere Sammel-Upgrades erhalten Mana-Rückgewinnung und rechnen
eingefrorene Schwur-AFK-Regeln vor dem Anlegen korrekt ab.
[Bedienung, Regeln und native Ansichten](docs/GEAR_GOALS.md).

## Vorheriger Ausbau: 0.41.0-beta.1 — fließende Figurenanimationen

Der freigegebene Stilentwurf wird mit gemalten, animierten 2.5D-Figuren in der räumlichen Godot-Spielwelt umgesetzt: drei Klassen, vier Wächter, eigene Regionen und ein Lager mit Schmiede, Schwurtisch und Portal. Bis zu zwei von drei Schwüren wirken gemeinsam mit Klassenreliquien, Sets und Techniken. Jeder Wächter besitzt drei echte Gesundheitsphasen; Warnung, Ausweichen, Skip, Offline-Wiederholung und Neustart verwenden dieselben Regeln. Alte laufende Spielstände behalten ihre ursprünglichen Kampfergebnisse. Version-Code 46.

[Animationen und Prüfanleitung](docs/ANIMATIONS_041.md), [Gameplay-Clip 0.41](docs/previews/animations/emberfall-gameplay-041.mp4), [Bewegungsprüfung aller Figuren](docs/previews/animations/emberfall-motion-041.mp4), [gemalte Welt](docs/REDESIGN_040.md), [Regeln und Kompatibilität](docs/OATHS_AND_PHASES_040.md), [Grafik und Herkunft](docs/design/ASSET_PROVENANCE.md), [Spieltest und Pixel-Probe](docs/SUCCESS_PLAYTEST.md). Menschliche Rückkehrdaten sowie Leistung, Wärme und Akkulaufzeit auf dem Pixel sind noch nicht erhoben. Die älteren Berichte unten dokumentieren vorherige Versionen.

## Kathedralenräume: Grafikaufwertung der Beta 0.39

Originale Maßwerkfenster, geschnitzte Bodenintarsien und modellierte Feuerschalen
ergänzen die neuen Figuren. Regionale Glasfarben, Fensterlicht, verwitterter Stein
und korrigierte Wasserreflexionen geben den vier Gebieten mehr Tiefe. Der
Battery-Modus schaltet die zusätzliche Beleuchtung ab. [Änderungen, Technik und
acht tatsächliche Spielansichten](docs/SANCTUARY_GRAPHICS.md).

## Geschlossener Play-Beta-Kandidat 0.39

Android-AFK-Rückkehr mit sichtbarem Fortschritt und wiederherstellbarem Restzeit-
Eintrag, breiterer Beutebildschirm mit direkten Folge-Expeditionen, sichere
Ausrüstungs-Upgrades, eigene Boss-Lebensanzeige und Display-Randabstände. Die
Solo-/AFK-Beta enthält keine Werbung oder Käufe und speichert lokal.
**19 Godot-Suiten / 1.401 Prüfungen bestanden**, APK und AAB lokal gebaut und
geprüft. Play-Upload mit dauerhaftem Schlüssel und Geräte-Abnahme stehen noch aus.
[Umfang, Store-Paket und konkrete Release-Gates](docs/PLAY_BETA_039.md).

## Kampflesbarkeit und vorbereitbare Kampfstile

Unter **Gear → Skills** lassen sich pro Klasse Balanced, Assault oder Bastion
wählen: unveränderte Balance, mehr Schaden mit höherem Risiko oder mehr Schutz
auf Kosten des Schadens. Die Auswahl gilt für neue Runs, Farm-Prognosen und AFK;
pausierte Expeditionen behalten ihre ursprünglichen Regeln. Schraffierte
Gefahrenflächen mit echtem Countdown, fliegende Fernangriffe und hervorgehobene
kritische Treffer machen die Kämpfe leichter lesbar.
[Regeln, Screenshots und Prüfungen](docs/COMBAT_CRAFT.md).

**Emberfall: Ashen Veil** ist ein eigenständiger, im Querformat gestalteter Godot-Prototyp für ein düsteres Idle-Action-RPG. Gegner haben eigene Lebensleisten; Nyra kämpft in automatischen Schlägen bis ein Gegner fällt. Alle zehn Etagen wechselt die Kampagne Gebiet, Dungeon-Namen und Boss: vom Hollow Spire bis zur Last Ember Citadel. Ein Boss-Sieg garantiert mindestens ein seltenes Ausrüstungsteil und schaltet sofort die nächste Etage frei. Vowkeeper, Arcanist und Ranger haben unterschiedliche Kampfvorteile; Attribute stärken ihre Werte und Klassenfähigkeiten. Die vier Gebiete besitzen eigene Materialien, Architekturdetails, Umgebungen und Bossmerkmale; jedes Gebiet besitzt seit 0.11 einen eigenen begehbaren Grundriss. Sechs Ausrüstungsslots, fünf Qualitäten und Stufen T1–T10 bilden die Beute-Progression. Angelegte Ausrüstung kann beim Schmied bis +5 verstärkt werden.

## Seedgesteuerter Auto-Kampf und variable Dungeon-Erkundung (0.38 Closed-Beta-Kandidat)

Nyra setzt in den Angriffspausen kurze, seedgebundene Positionswechsel ein: Die Vowkeeperin umrundet Gegner auf Nahkampfreichweite, während Arcanist und Ranger ihre Schussposition variieren. Sie prüft die nächsten Schritte gegen angekündigte Gefahren und bleibt in der begehbaren Kammer. Ein bereiter Angriff hat Vorrang; ein Positionswechsel setzt in der nächsten Angriffspause fort. Laufwege und Gegnerbewegung bleiben zielgerichtet; Zufall sorgt für unterschiedliche Kampfbilder, ohne Zuschauen, Skip und AFK auseinanderlaufen zu lassen. Generation 5 ergänzt diese Kampfbewegung; pausierte ältere Läufe behalten ihre gespeicherte Version.

Neue Läufe verwenden Dungeon-Generation 6 und Route-Version 4: Jeder Korridor wählt seedgebunden eine von vier Wegformen – mehrspurige Kurve, kurzer Seitengang, breiter Seitenschwung oder Zickzackpfad. Boden, Laufbewegung und Minikarte folgen denselben Wegpunkten. Dazu bleiben Gegneraufstellungen, Spawnpositionen, Flanken und zwei zeitversetzte Verstärkungen seedgebunden; die Zahl der Gegner und die Beutemenge ändern sich nicht. Automatische Fähigkeiten, Zuschauen, Skip und AFK rechnen denselben Lauf. Pausierte Routen der Versionen 1–3 behalten ihre Wegform.

Die 256er-Bank hält dieselben Läufe für Zuschauen, Skip und AFK reproduzierbar.

Bei ähnlich wichtigen Gegnern entscheidet der Seed beim nächsten bereiten Angriff neu, wen Nyra fokussiert. Während sie auf Reichweite läuft oder ihr Angriff abklingt, bleibt das Ziel stabil. Das ergänzt zufällige Gegneraufstellungen und automatische Fähigkeitswahl, ohne hektisches Umschalten oder unterschiedliche Skip-/AFK-Ergebnisse.

## Kampfkamera und reduzierte Bewegung (0.30)

Die isometrische Kamera gibt Nyra einen kleinen Vorlauf in Laufrichtung und hält das gewählte Ziel besser im Bild. In Bossräumen zieht sie sich sanft näher heran; schwere Treffer und Bossimpakte geben einen kurzen, begrenzten Kameraimpuls. Unter **Options → Reduced Motion** lassen sich Zoom und Erschütterung abschalten. Die Änderung ist rein visuell und beeinflusst weder Kampf noch Beute, Skip oder Offline-Fortschritt. Neue Expeditionen wählen Weg und Kampfmuster aus derselben 256er-Bank; dadurch kann AFK exakt passende Kämpfe wiederverwenden, während Beute weiterhin den individuellen Run-Seed nutzt. Angefangene ältere Läufe behalten ihre bisherige Wegführung.

## Freiere Laufwege (0.31)

Neue Läufe schicken Nyra auf seedgebundenen S-Kurven durch die Verbindungsgänge. Die Route ist im Dungeon und auf der Karte dieselbe; zufällige Gegnergruppen, Formationen, Hinterhalte und passende Fähigkeitswahl laufen weiter automatisch. Das Muster bleibt über Zuschauen, Skip und AFK identisch. Version-1-Checkpoints und ältere pausierte Läufe behalten ihren bisherigen Weg.

## Serverfortschritt (0.33 · Online-Test)

Die Android-Testprofile verbinden nun einen Nakama-Laufzeitserver mit einem getrennten serververwalteten Testprofil. Der Server rechnet AFK-Zeit aus seiner eigenen Uhr ab (höchstens 24 Stunden), ermittelt Sieg oder Niederlage aus serverseitiger Charakterstärke und Etage und erzeugt Beute mit frischen kryptografischen Zufallsstarts. Er begrenzt freigeschaltete Etagen und verwaltet Klassenwahl, Attribute, Inventar, Verkauf, Ausrüstung und Verstärkung. Für Gold, Siege oder Gegenstände nimmt er keine vom Client vorgegebenen Werte an. Nakama-Speicher lässt Spieler das Profil lesen, aber nicht direkt überschreiben.

Das Serverprofil ist noch nicht mit Nyras lokalem Charakter verbunden. Der bestehende lokale Spielstand wird nicht importiert oder überschrieben; sichtbarer Dungeon-Kampf, lokale Belohnungen und Kampagnenfortschritt laufen weiterhin auf dem Gerät. Die Testoberfläche zeigt den getrennten Serverstand unter **Options → Online Test**. Zusätzlich bleiben offene Nakama-Gemeinschaften und persistenter Echtzeit-Gruppenchat verfügbar. Details und Startanleitung: [Lokaler Online-Test](docs/ONLINE_TEST.md).

## Grafischer Ausbau (0.14)

Schlankere Figuren mit zusammenhängenden Rüstungs- und Kleidungsformen, gotische Arkaden, unregelmäßige Steinplatten, tiefere Fundamente, animierte Feuer und Nebel geben den Dungeons mehr Atmosphäre. Neue Waffenbögen, Trefferfunken und eine nähere Kamera machen Kämpfe besser sichtbar. Alle neuen Grafikbestandteile sind in Godot erstellt. [Umsetzung und Grenzen](docs/VISUAL_UPGRADE.md).

## Flüssigere Bewegung und Treffer (0.15)

Nyra und Gegner takten ihre Schritte passend zur tatsächlichen Laufgeschwindigkeit. Schläge holen sichtbar aus und federn zurück; Treffer lösen ein kurzes Taumeln aus, Gegner fallen mit leichten Variationen. Atem- und Mantelbewegungen lockern den Stand. Die Animationen laufen rein visuell und verändern weder Kampfwerte noch Offline-Ergebnisse.

## Zufällige Dungeonläufe (0.16)

Jeder Lauf nutzt seinen Seed für leicht veränderte Wege, Gegnergruppen, Formationen und Fähigkeitsentscheidungen. Nyra wählt bereitstehende Fähigkeiten nach der Situation; wenn mehrere passen, wechselt die Auswahl von Lauf zu Lauf. Dieselbe Expedition bleibt beim Zuschauen, Überspringen und AFK-Fortschritt reproduzierbar. [Design und Grenzen](docs/GAMEPLAY_DIRECTION.md).

## Klassenbalance (0.17)

Der Vowkeeper erhält als Klassenmerkmal 20% zusätzliches Leben und Rüstung. Die 480-Läufe-Farmprobe stieg damit von Farmetage 58 (476 Siege) auf Etage 84 (479 Siege); Arcanist und Ranger blieben auf Etage 86 mit 479 bzw. 480 Siegen. [Messung und Grenzen](docs/GAMEPLAY_DIRECTION.md#klassenbalance-017).

## Sichtbare Ausrüstungsbeute (0.18)

Nach dem besiegten Boss zeigt das geöffnete Reliquiar bis zu zwei der tatsächlich erhaltenen Gegenstände als schwebende, nach Qualität eingefärbte 3D-Beute mit Name und Ausrüstungsslot. Das ist dieselbe Beute, die im anschließenden Beutefenster erscheint; die Szene erzeugt keine zusätzlichen Gegenstände.

## Lesbar auf kompakten Querformatdisplays (0.19)

Bei kleinen Querformatfenstern skaliert die Oberfläche Schrift automatisch um 20 Prozent und vergrößert Aktionsflächen auf mindestens 52 logische Pixel. Unter **Options → Large Text** lässt sich die Schrift auf jedem Display weiter vergrößern; die Einstellung bleibt gespeichert. Sie greift auch auf bereits geöffnete Ansichten und das Kampf-HUD durch.

## Mehr Abwechslung pro Dungeon (0.20)

Neue Läufe wählen aus 256 wiederholbaren Seedmustern: Wegführung, Gegnergruppen und Formationen verändern sich sichtbar. Räuber versuchen die Flanken zu erreichen, Hexer halten je Lauf einen eigenen Abstand und variieren ihre angekündigten Zauber; Eliten setzen gelegentlich einen ausweichbaren Flächenangriff ein. Nyra läuft weiterhin zielgerichtet durch verbundene Gänge und aktiviert Fähigkeiten selbstständig nach Situation. Zuschauen, Skip und AFK bleiben für denselben Seed identisch. Pausierte Läufe aus älteren Versionen behalten ihre bisherigen Regeln.

## Bosskämpfe mit variierenden Angriffen (0.21)

Jeder Gebiets-Boss nutzt jetzt zwei seedgebundene Formen seines Bodenangriffs und wechselt beim nächsten Angriff zur jeweils anderen. Ring, Flutbahn, Grabkreise und Feuerkreuz bleiben pro Gebiet erkennbar; ihre Gefahrenzonen ändern sich sichtbar. Nyra liest weiterhin die Vorwarnung und weicht selbstständig aus. Wiederholung, Skip, AFK und gespeicherte Kämpfe verwenden dieselbe Auswahl.

## Spielstand sichern und umziehen (0.22)

Unter **Options → Save Backup** kannst du einen geprüften Backup-Code kopieren und außerhalb des Geräts aufbewahren. Der Code enthält Held, Ausrüstung, Einstellungen und einen pausierten Dungeon-Checkpoint. Auf einem neuen Gerät fügst du ihn wieder ein. Der vorherige lokale Stand bleibt als Wiederherstellung verfügbar; **Undo Last Restore** setzt ihn zurück. Der Code enthält persönliche Spielstanddaten und sollte privat bleiben.

## Lesbareres Kampf-HUD auf kleinen Querformatdisplays (0.23)

Die kleinsten Ziel-, Raum- und Kampfhinweise sind jetzt größer; die Routenkarte zeigt den aktuellen Standort mit größeren Knoten. Die Änderungen betreffen ausschließlich die Darstellung. Sie wurden bei 854×480 und 1280×720 verglichen; der Text kann weiterhin von echten Geräten und den Android-Anzeigeeinstellungen abhängen.

## Persönliche Zufallsfolge (0.24)

Neue Spielstände erhalten beim ersten Start einen eigenen Zufalls-Startwert. Er bestimmt die Reihenfolge reproduzierbarer Dungeonläufe und variiert auch die Beute. Derselbe Lauf behält seinen Seed beim Zuschauen, Überspringen, Pausieren, Neustart und AFK-Fortschritt; ältere Spielstände bekommen den neuen Wert einmalig beim Laden und Speichern.

## Zufälligere Gegnerformationen (0.25)

Spawnformationen werden jetzt pro Lauf gedreht und die Positionen leicht individuell verschoben. Dadurch unterscheiden sich auch die Abstände und Anmarschwinkel der Gegner, während Wege, Gegnerrollen, Fähigkeiten und AFK-Ergebnis weiter seedgebunden reproduzierbar bleiben. 256 unterschiedliche Formationen sind geprüft; Anzahl und Stärke der Gegner bleiben unverändert.

## Wechselnde Laufwege (0.26)

Auf jedem neuen Lauf liegt die Abbiegung in jedem Verbindungsgang an einer anderen Stelle. Der vollständige Lauf-Seed bestimmt den sichtbaren Weg; Gegner, Kampf und Offline-Berechnung behalten ihre gemeinsame 256er-Kampfmusterbank. Alle möglichen Abbiegungen haben dieselbe Weglänge, damit AFK-Zeit und Balance davon unberührt bleiben. Angefangene Läufe aus 0.25 behalten den bisherigen Weg beim Wiederaufnehmen.

## Zeitversetzte Hinterhalte (0.27)

In zwei zufällig gewählten Räumen taucht je ein Gegner erst während des automatischen Kampfes auf. Die Auswahl und Verzögerung sind pro Run-Seed festgelegt. Die Figur läuft weiter zielgerichtet, während Hinterhalte zusätzliche Überraschungsmomente bringen. Gegnergesamtzahl und Loot bleiben unverändert; Live, Skip und AFK spielen dieselbe Begegnung ab. Alte Dungeon-Checkpoints behalten ihre bisherigen Abläufe.

## Beutejagden und Aschenprüfungen (0.13)

Nach dem ersten Kampagnensieg bietet **World → Hunts** gezieltes Farmen für einen gewählten Ausrüstungsslot – sichtbar und offline, gegen stärkere Gegner. **Ash Trials** enthält 30 separate Prüfungsstufen mit 150 Sekunden Zeitlimit und einmaliger Epic-Abschlussbeute. Die Farm-Prognose berücksichtigt die gewählte Schwierigkeit. [Regeln, 749 Prüfungen und Balance-Messung](docs/HUNTS_AND_TRIALS.md).

## Automatische Fähigkeiten (0.12)

Unter **Gear → Skills** wählst du zwei von drei zusätzlichen Techniken je Klasse. Zusammen mit der Klassenfähigkeit entstehen automatische Rotationen aus Schutz, Flächenangriffen und gezielten Treffern. Mana, Abklingzeiten, Gegnergruppen und Gefahren bestimmen den Einsatz. Die Auswahl bleibt je Klasse gespeichert und gilt auch für Skip und Offline-Farmen. Eigene Godot-Symbole, Schutzschilde, Kettenblitze und Bodenmarkierungen machen den Ablauf sichtbar. Wischen über Karten und Buttons scrollt die Ausrüstungsliste jetzt zuverlässig. [Regeln und Prüfungen](docs/SKILL_ROTATION.md).

## Dungeon-Erkundung (0.11)

Vier räumlich unterschiedliche Wege, eine Übersichtskarte, 26 Gegner und automatische Zwischenziele bringen den Ablauf näher an die Gameplay-Referenz. Nyra benutzt einen Heilbrunnen, öffnet über ein bewachtes Siegel den Bosszugang und birgt das finale Reliquiar. Zuschauen, Skip und AFK rechnen denselben Weg. Alte laufende Expeditionen werden mit ihren bisherigen Regeln fortgesetzt. [Referenzbeobachtungen, Umsetzung, 544 Prüfungen und nächste Gameplay-Schritte](docs/GAMEPLAY_DIRECTION.md).

## Klassen-Builds (0.10)

Der Arcanist hält zwischen seinen Zaubern automatisch Abstand und nutzt eine breitere, stärkere Veil Nova mit sichtbarer violetter Welle. Neue Beute hat Klassenprofile und enthält stets das passende Hauptattribut; vorhandene Ausrüstung bleibt erhalten und alle Gegenstände bleiben klassenübergreifend nutzbar. [Regeln, 438 Prüfungen und Balance-Vergleiche über 4.320 Expeditionen](docs/CLASS_BUILDS.md).

## Gebiets-Bosse (0.9)

Bell Warden, Silt Abbot, Mourning Queen und Cinder Sovereign besitzen jetzt eigene Bodenangriffe: Ring, Flutbahn, drei Grabkreise und Feuerkreuz. Unter halbem Leben werden sie stärker. Nyra sucht automatisch sichere Bereiche; das HUD zeigt Angriff und Vorwarnzeit. Angefangene alte Expeditionen behalten ihre bisherigen Regeln. [Bossmechaniken, Speicherung und 380 Prüfungen](docs/BOSS_ENCOUNTERS.md).

## Mana-Barriere (0.8)

Der Arcanist absorbiert automatisch bis zu 35 Prozent eingehenden Schadens mit überschüssigem Mana. Eine Nova bleibt reserviert. Ein violetter Schild und das Kampf-HUD zeigen den Schutz an. Begonnene Expeditionen aus älteren Versionen behalten ihre ursprünglichen Regeln. [Regeln, 295 Prüfungen und offene Balance-Fragen](docs/MANA_WARD.md).

## Ton, Optionen und Zurück-Navigation (0.7)

Originale, in Godot synthetisierte Klänge begleiten Lager, Dungeon, Treffer, Klassenfähigkeiten und Beute. Im Optionsmenü lassen sich Gesamtlautstärke, Musik und Effekte getrennt regeln. Ein Battery-Modus reduziert die 3D-Auflösung, deaktiviert Schatten und begrenzt die Darstellung auf 30 FPS. Die Kampfsimulation bleibt unverändert. Schadenszahlen sind abschaltbar.

Android Back oder Escape öffnet im Dungeon ein Pausenmenü. Schließen setzt nur einen vorher aktiven Lauf fort. Aus Ausrüstung, Karte oder Beute führt Back zurück zum Lager. Die Optionen werden mit dem Spielstand gespeichert; How to Play erklärt die wichtigsten Abläufe. [Prüfungen und Grenzen](docs/SOUND_AND_OPTIONS.md).

## Einstieg, Ausrüstung und Farm-Prognosen (0.6)

Neue Spielstände beginnen mit einer Klassenwahl und einer kurzen Erklärung des automatischen Spielablaufs. Bestehende Spielstände werden direkt fortgesetzt. Die Armory besitzt eigene Reiter für Tasche, angelegte Ausrüstung sowie Klasse und Attribute. Beim Klassenwechsel werden verteilte Attributpunkte vollständig zurückgegeben; eine kostenlose Rückgabe ist auch manuell möglich.

Gegenstände zeigen die tatsächlichen Änderungen für die aktuelle Klasse: Angriff, Fähigkeitenschaden, Leben, Rüstung, Mana und kritische Trefferchance. Erhöht ein Gegenstand den Fähigkeitsrang, wird auch der zusätzliche Mana-Verbrauch pro Einsatz angezeigt. Die Krit-Chance ist auf die tatsächlich wirksamen 100 Prozent begrenzt.

Im Lager werden Dungeon und gewählte Farm-Etage mit allen 256 Kampfmustern der aktuellen Ausrüstung bewertet. Die Prüfung läuft in kleinen Portionen, lässt die Oberfläche bedienbar und verbraucht keine Spielzeit, Laufnummern oder Beute. Die Anzeige zeigt Erfolgsrate und Dauer; für AFK wird die Mindestdauer von 30 Sekunden pro abgerechnetem Lauf berücksichtigt. Werte gelten bei unveränderter Klasse/Ausrüstung und ersetzen die frühere pauschale Kampfpunkt-Empfehlung. Offline-Ergebnisse stehen bei der Rückkehr oben im Lager.

## Vier Gebiete (0.5)

- **Hollow Spire:** kalter Stein, verfallene Bögen, Banner und eine geborstene Glocke über dem Heiligtum.
- **Sunken Archive:** überflutete Umgebung, feuchter Stein, verfallene Bücherregale und türkisfarbene Geisterlichter. Der Silt Abbot trägt eine hohe Mitra und eine lange Robe.
- **Crow Ossuary:** offene Knochenbögen, schwarze Kristalle, Knochenfelder und violettes Licht. Die Mourning Queen trägt eine gezackte Krone und knöcherne Schulterfortsätze.
- **Last Ember Citadel:** dunkle Lava, Öfen, Gitter und Ketten. Der Cinder Sovereign trägt eine glühende Brustplatte und Ofenschlote.

Gegnernamen und Farben folgen dem Gebiet. Der automatische Kampf bleibt dieselbe verifizierte Simulation. Wiederholte statische Quader, Kugeln, Zylinder und Ringe werden pro Raum und Material gebündelt, damit die zusätzlichen Details weniger Zeichenaufrufe benötigen. Starre Teile der Figuren werden innerhalb ihrer beweglichen Gelenke zu gemeinsamen Meshes zusammengeführt. Wasser und Lava sind eigene animierte Godot-Shader. Alle Modelle und Materialien sind im Projekt erstellt.

## Verlässliche Wiederaufnahme (0.4.1)

- Ein laufender Dungeon wird einschließlich Positionen, Gegner-Leben, Mana, Fähigkeiten, Ausweichbewegung und Zufallszustand gespeichert. Auch Pause und Wiederholung bleiben nach einem Neustart erhalten.
- Bei aktivem Offline-Farmen wird zuerst der bereits laufende Kampf um die verstrichene Zeit fortgesetzt. Erst anschließend werden weitere Farm-Läufe berechnet. Ein pausierter Lauf bleibt pausiert.
- Zwei Speicherdateien wechseln sich ab. Jede Generation wird vor der Übernahme geprüft und atomar ersetzt. Bei einer beschädigten Datei wird der vorherige gültige Checkpoint geladen und ein Hinweis angezeigt. Sind beide Dateien unlesbar oder gehört ein Stand zu einer neueren Version, bleiben die Dateien erhalten und Schreibzugriffe werden gesperrt.
- Alte Spielstände werden übernommen; die ursprüngliche Datei bleibt als zusätzliche Sicherung erhalten. Ohne Server sind Gerätewechsel, Neuinstallation und Manipulationsschutz nicht abgesichert.
- Beim abrupten Prozessabbruch kann höchstens der letzte Checkpoint (normalerweise bis zu fünf Sekunden) fehlen. Mit aktiviertem AFK-Farmen wird diese Zeit nachgerechnet. Reguläres Wechseln in den Hintergrund speichert sofort.

## Automatische Gruppenkämpfe und Farmen (0.4)

- **Sechs Gegnergruppen / 26 Gegner:** schnelle Nahkämpfer, Schildträger, Hexer, ein Elitehauptmann und ein Boss mit Begleitern. Hexer wirken unterbrechbare Bodenzauber, Schildträger reduzieren physischen Schaden, der Boss kündigt Flächenangriffe an.
- **Vowkeeper:** bindet Gegner im Nahkampf, trifft mehrere Ziele mit Ember Oath, heilt sich und erhält kurzzeitig Guard.
- **Arcanist:** wählt Gegneransammlungen für Veil Nova, verursacht Flächenschaden, verlangsamt und unterbricht Hexer.
- **Ranger:** priorisiert Hexer, weicht bei zu geringer Distanz zurück und nutzt Cinder Volley gegen mehrere Ziele. Alle Klassen versuchen angekündigten Bodenangriffen auszuweichen; dafür gilt eine Abklingzeit.
- Mana und Abklingzeiten begrenzen Fähigkeiten. Das HUD zeigt das aktuelle Ziel, verbleibende Gegner und die Abklingzeit der Klassenfähigkeit.

### Farmgebiet und Wiederholung

Im Lager die **Farm Floor** mit **− / +** auswählen und **Start Auto Farm** starten. Höhere Farm-Etagen müssen zuerst freigeschaltet werden. **Repeat: On/Off** im Dungeon schaltet die Wiederholung der aktuellen Etage um. Bei Erfolg wird Beute eingesammelt und derselbe Dungeon erneut gestartet; bei einer Niederlage endet die sichtbare Wiederholung. **Skip to Loot** beendet die Wiederholung und öffnet die Beuteansicht.

Offline wird die gewählte Farm-Etage wiederholt. Die Berechnung verwendet die ausgerüsteten Werte, tatsächliche Kampfdauer und dieselben Angriffs-/Ausweichregeln wie beim Zuschauen. Überfordernde Etagen werden nicht mehr über eine pauschale Zufalls-Erfolgschance freigeschaltet. Beide Modi garantieren bei einem Boss-Sieg mindestens seltene Beute. Volle Taschen verkaufen weitere Funde; Gold und XP aus AFK-Läufen werden im Bericht abgeholt.

Die Kampfsimulation ist bei gleichen Werten, Etage und Startwert reproduzierbar. Neue Läufe teilen Weg- und Kampfmuster in 256 wiederkehrende Varianten; identische Läufe lassen sich daher innerhalb einer AFK-Berechnung exakt wiederverwenden, ohne das Ergebnis zu schätzen. Beute nutzt weiterhin den individuellen Startwert jedes Laufs. Etagenwahl, Laufzähler, Zeitrest und ausstehende Belohnungen werden gespeichert; höchstens 24 Stunden werden berechnet.

## 3D-Dungeon (0.3)

Im Lager **Descend to Floor** oder auf der Weltkarte **Enter Dungeon** wählen. Die Figur läuft sichtbar durch einen zusammenhängenden 3D-Dungeon. Die schräge Kamera folgt ihr durch sechs benannte Kammern und die gebietsspezifischen Verbindungswege bis zum Boss und seiner Truhe. Ausrüstung, Klassenwerte, Schadensberechnung und Beute bleiben Teil des bestehenden Spielmodells.

- Vollbild-Spielwelt mit darüberliegender Lebens-/Manaleiste, Fortschritt, Pause und Überspringen.
- Automatische Zustände: Laufen → Angriff in Waffenreichweite → Gegner fällt → nächster Abschnitt. Die feste Kampfsimulation löst Angriffe und ihre Animationskontakte aus.
- Selbst gebaute Godot-Modelle mit artikulierten Armen/Beinen, Mantelbewegung, Schwert/Schild, Stab oder Bogen; sichtbare Trefferzahlen und Klasseneffekte.
- Originale prozedurale Steinmaterialien, Säulen, Sarkophage, Banner, Fackelbeleuchtung, Schatten und Distanznebel. Keine Assets aus Diablo oder dem Referenzvideo.
- Kurzes Wechseln in den Hintergrund erhält die Szene und setzt denselben Kampf fort; sobald dieser während der Abwesenheit endet, zeigt das Lager den Offline-Bericht. Doppelte Resume-Ereignisse vergeben keine zusätzlichen Belohnungen.

**Aktueller Umfang:** ein lokaler 3D-Prototyp mit vier gebietsspezifischen Dungeon-Routen. Modelle und Animationen sind vorläufig, die Gegner verwenden einen gemeinsamen Grundkörper mit unterschiedlichen Proportionen, Waffen und Rollen. Es gibt noch keinen Mehrspieler-Server. Die Gestaltung bleibt bewusst eigenständig und stilisiert. Die Offline-Berechnung nutzt dieselbe Kampfsimulation wie die sichtbaren Läufe.

## Starten

Das Projekt mit Godot 4.7.2 öffnen und `Main.tscn` starten. Die Spielfläche ist fest auf Querformat ausgelegt. Der erste Spielstand beginnt mit Nyra auf Stufe 1 und einer Auswahl zwischen allen drei Klassen.

### Android-Test- und Beta-Build

Das Exportprofil `Android Debug` erstellt eine installierbare ARM64-Test-APK `build/emberfall-038-online-test-debug.apk` mit eigener Paketkennung. `Android Emulator Debug` baut für x86_64 nach `build/emberfall-038-emulator-debug.apk`. `Google Play Beta` zielt auf Android API 36, ARM64 und Version `0.38.0-beta.1`. `EMBERFALL_BETA_AAB=build/emberfall-038-play-beta.aab python3 scripts/export_google_play_beta.py` signiert das AAB mit dem lokalen Upload-Key. Für den Export werden Godots Gradle-Build-Vorlage mit Android Gradle Plugin 8.10.1, OpenJDK 17, Android SDK Platform 36 und Build-Tools 36.1.0 benötigt.

Für einen direkten manuellen Closed-Beta-Test erstellt `python3 scripts/export_closed_beta_apk.py` das release-signierte ARM64-APK `build/emberfall-038-closed-beta.apk` samt SHA-256-Datei. Es verwendet eine eigene Paketkennung, erzwingt Querformat, zielt auf API 36 und fordert keine Internetberechtigung an. Das APK ist sideloadbar, aber kein Google-Play-Upload; ein Play-AAB bleibt der erforderliche Store-Build.

Die manuelle Prüfrunde steht in [docs/BETA_TESTING.md](docs/BETA_TESTING.md). Sie enthält Installationsdaten, Prüfschritte für Kampf, Beute und Kaltstart sowie ein Fehlerbericht-Schema. Zum Testen über GitHub öffne **Actions → Android Debug APK**, wähle den neuesten erfolgreichen Lauf auf `main` und lade das Artefakt `emberfall-ashen-veil-android-ci-validation-only` herunter. Darin liegt `build/emberfall-closed-beta-ci.apk`.

GitHub Actions prüft bei Änderungen die Android-Test-APK, das Closed-Beta-APK-Profil und das Play-Bundle. Das CI-Artefakt ist 14 Tage verfügbar und mit einem nur für diesen Lauf erzeugten Schlüssel signiert. Vor dem Installieren eines Artefakts aus einem neuen Lauf muss eine ältere CI-Installation entfernt werden. CI-Artefakte können keine lokal oder über Google Play signierten Installationen aktualisieren und sind keine Veröffentlichung.

Der Quellstand 0.38 ergänzt seedgebundene Zielwechsel zwischen taktisch gleichwertigen Gegnern. Die vollständige Regression besteht mit 17 Godot-Suites und 1.199 Checks ohne Fehler; Reise, Speicherung und Dungeon/AFK enthalten davon 557 gezielte Checks. Das release-signierte ARM64-APK 0.38 / Code 42 ist auf Signatur und Manifest geprüft. Installation auf Android, Play-AAB und gemeinsamer Online-Dungeon sind weiterhin offene Veröffentlichungsgates; es gibt keine Freigabe in der Play Console.

## Steuerung im Prototyp

- **Lager**: Figur ansehen und den nächsten Dungeon beginnen.
- **Ausrüstung**: zwischen Vowkeeper, Arcanist und Ranger wechseln, Attributpunkte verteilen und Gegenstände anlegen oder verkaufen.
- **Weltkarte**: mit „Enter Dungeon“ die sichtbare Lauf- und Kampfszene starten, Nyra durch den Gang begleiten oder direkt bis zur Beute vorspulen.

Ein Lauf kann jederzeit abgeschlossen oder übersprungen werden. Im Hintergrund wird kein dauerhaft laufender Prozess benötigt: beim nächsten Start rechnet das Spiel bis zu 24 Stunden Fortschritt aus dem gespeicherten Zeitpunkt nach.

Der erste Prototyp spielt sich allein und lokal. Godot speichert den letzten Zeitpunkt und simuliert beim erneuten Öffnen abgeschlossene Läufe samt Etagenfortschritt, Gold, Erfahrung und Ausrüstung. Beute über dem Inventarlimit wird automatisch verkauft.

## Lokale Prüfungen

Der gebündelte lokale Offline-Regressionslauf ist `python3 scripts/run_beta_checks.py`. Er führt 17 Godot-Suites mit temporär isolierten Spielständen sowie Syntax- und Laufzeitprüfungen des Servermoduls aus. Für eine gezielte Godot-Suite kann `--suite` verwendet werden, zum Beispiel `python3 scripts/run_beta_checks.py --suite options`. Emulator-/Gerätetests, der Nakama-E2E-Test und der Play-AAB-Export bleiben separate Veröffentlichungsgates.

Einzelne Prüfungen lassen sich auch mit separatem Datenverzeichnis ausführen, damit der eigene Spielstand unangetastet bleibt:

```bash
XDG_DATA_HOME=/tmp/emberfall-journey-data godot --headless --path . --fixed-fps 60 --script tests/journey_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-smoke-data godot --headless --path . --fixed-fps 60 --script tests/dungeon_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-persistence-data godot --headless --path . --fixed-fps 60 --script tests/persistence_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-balance-data godot --headless --path . --fixed-fps 60 --script tests/balance_survey.gd -- 0
XDG_DATA_HOME=/tmp/emberfall-regions-data godot --headless --path . --fixed-fps 60 --script tests/regions_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-gear-data godot --headless --path . --fixed-fps 60 --script tests/gear_forecast_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-onboarding-data godot --headless --path . --fixed-fps 60 --script tests/onboarding_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-options-data godot --headless --path . --fixed-fps 60 --script tests/options_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-fellowship-ui-data godot --headless --path . --fixed-fps 60 --script tests/fellowship_ui_smoke.gd
XDG_DATA_HOME=/tmp/emberfall-cloud-identity-data godot --headless --path . --script tests/cloud_identity_smoke.gd
```

Der vollständige 0.35-Quellstand bestand am 29. September 2026 17 Offline-Godot-Suites mit insgesamt 1.127 Checks; Node-Syntax und Serverlaufzeitprüfung waren ebenfalls erfolgreich. Sechs Balance-Seeds aus 0.34 ergaben mittlere Farmetagen 92,3 / 94,8 / 91,0 für Vowkeeper / Arcanist / Ranger und Siege von 2.879/2.880, 2.876/2.880 und 2.876/2.880. Die einzelne Bot-Heuristik belegt keine allgemeine Klassenbalance. Die damals genannte 0.34-Prüfnotiz ist im Repository nicht enthalten.

Die Prüfung deckt alle drei Klassen, Bewegung, Reichweite, Pause, Bossabschluss, Beute, Überspringen, Niederlage und Hintergrundwechsel ab. `tests/android_preview.tscn` ist ein separater Test-Einstieg: startet automatisch einen frischen Lauf und speichert nach 2/12/25/40/58/75 Sekunden sowie beim ersten angekündigten Bossangriff Screenshots unter `user://`. Nur mit einer separaten Android-Paketkennung und einem eigenen Spielstand verwenden; `Main.tscn` bleibt der normale Einstieg.

`tests/persistence_smoke.gd` prüft exakte Kampffortsetzung, Speicher-Generationen, Korruption, Migration, Pausen und einmalige AFK-Auszahlung. `tests/android_lifecycle.tscn` ist ein weiterer separater Test-Einstieg für echte Android-Prozessabbrüche. Ablauf und Nachweise stehen in [docs/PERSISTENCE.md](docs/PERSISTENCE.md).

### Technischer Aufbau

- `scripts/expedition_simulation.gd`: feste 100-ms-Schritte für Bewegung, Zielwahl, Fähigkeiten, Gegner und Ergebnisse; dieselbe Logik für sichtbar/Skip/AFK.
- `scripts/dungeon_layout.gd`: seedgebundene Varianten für Wege, Gegnergruppen und Spawnpunkte; derselbe Lauf bleibt bei Zuschauen, Skip und AFK identisch.
- `scripts/dungeon_world.gd`: zusammenhängende Welt, Kamera, Darstellung der Simulation und Effekte.
- `scripts/dungeon_actor.gd`: ursprüngliche Godot-Geometrie und Gelenkanimationen für Figuren.
- `scripts/battle_art.gd`: 3D-Viewport und Verbindung zum Spielmodell.
- `scripts/main.gd`: Klassen, Werte, HUD, Ausrüstung, Belohnungen und Speicherung.
- `scripts/fellowship_service.gd`: Nakama-Gemeinschaften, serverseitige Mitgliedschaft, Online-Präsenz und persistenter Gruppenchat im Online-Test-Build.
- `server/modules/emberfall.js`: serververwaltetes Testprofil, AFK-Abrechnung, Beutewürfe und validierte Ausrüstungs-/Attributaktionen; noch nicht an Nyras lokales Spielmodell angeschlossen.
- `scripts/progression_service.gd`: Godot-Client für den getrennten serverautoritativen Fortschritt im Online-Test-Build.

- `scripts/save_store.gd`: versionierte, geprüfte Speichergenerationen und Legacy-Migration.

- `scripts/dungeon_theme.gd`: Gebietspaletten und Gegnernamen.
- `tests/android_regions.tscn`: separater Android-Einstieg für zwölf Gebiets-/Klassenaufnahmen und eine kurze Bildratenmessung; kein Progressionstest.

Die kurzen Android-Vergleichsmessungen und ihre Grenzen stehen in [docs/REGIONS.md](docs/REGIONS.md).

- `scripts/farm_forecast.gd`: schrittweise, rein lesende Bewertung aller Kampfmuster für eine Etage.
- `tests/android_ux.tscn`: separater Android-Einstieg für Touch-Tests, Zustandsprotokolle und Screenshots.

Prüfablauf für den Einstieg, Ausrüstungswerte und echte Android-Toucheingaben: [docs/HERO_AND_GEAR.md](docs/HERO_AND_GEAR.md).

### Beta.2: Einstieg und Spielziele

[Schneller Erstkampf, Schwüre und Klassenreliquien](docs/SUCCESS_LOOP.md), vier regionale Sets, Wächtersiegel und optionale Haptik. [Geschlossener Spieltest und Pixel-Probe](docs/SUCCESS_PLAYTEST.md); [Gameplay-Clip](docs/previews/success-loop/emberfall-gameplay-beta2.mp4). Historischer Stand dieser Beta.2/Beta.3-Berichte: 0.39.0-beta.3, Version-Code 45. Damals folgender Kandidat: 0.41.0-beta.1, Version-Code 47; aktueller Teststand siehe oben.

[Geschützte Ausrüstung, Taschenfilter und konkrete Hilfe nach Niederlagen](docs/GEAR_AND_RECOVERY.md). Die erste Klassenreliquie bleibt bei vollständig geschützter voller Tasche zum Abholen erhalten; der lokale Online-Integrationstest ist repariert.
