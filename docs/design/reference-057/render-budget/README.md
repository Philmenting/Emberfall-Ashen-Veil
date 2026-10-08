# Darstellungsbudget 057

Die tatsächlichen Produktionsprüfungen bestehen mit **287 Headless-Checks und 300 nativen GL-Checks, jeweils null Fehler und tatsächlichem Prozessexit 0**. Der akzeptierte Lauf vom 7. Oktober 2026 benötigt 7,542 bzw. 28,823 Sekunden Wandzeit. Diese Dauer ist die gesamte Diagnosezeit einschließlich Aufbau und Prüfungen, keine Spiel-Frametime. [Originalreceipt und Quellenbindung](receipt.json), [Headless-Bericht](headless-operations-report.json) und [nativer GL-Bericht](native-gl-primitives-report.json) sind erhalten. Alle **406 erfassten Skript-, Modell-, Shader-, Material- und Projektquellen** bleiben während beider Läufe unverändert; die Gesamtquelle war zu diesem Zeitpunkt noch nicht als Git-Commit eingefroren.

## Weniger vermeidbare Arbeit

Die zusätzlichen Hero-Sichtbarkeitsmeshes und ihr gemeinsam verwendetes Akzentmaterial entstehen erst bei einer tatsächlichen Verdeckung. Zwölf unverdeckte Updates des zusätzlichen Hero-Passes aller drei realen Helden erzeugen **null zusätzliche Meshes und Materialien** und benötigen **null Bounds-, Kamera-Inversions-, Transform-, Sichtbarkeits- oder Uniformoperationen**. Nach einem echten Reveal erfordern die folgenden deaktivierten Frames ebenfalls keine dieser Operationen; identische sichtbare Posen erzeugen keine redundanten Server-Schreibvorgänge.

| Tatsächlicher Held | Sichtbare Quellmeshes in Ruhe | Meshes beim ersten Reveal | Gemeinsame Akzentmaterialien | Später zugeschaltete Pfeilmeshes |
| --- | ---: | ---: | ---: | ---: |
| Arcanist | 24 | 24 | 1 | 0 |
| Vowkeeper | 17 | 17 | 1 | 0 |
| Ranger | 16 | 16 | 1 | 3 |

Der in Ruhe unsichtbare Ranger-Pfeil bleibt zunächst nur ein schwacher Kandidat. Der tatsächliche Cast aktiviert seine drei ursprünglichen Meshteile; erst dann entstehen genau deren Replay-Geschwister. Die Kopien teilen Mesh, Skin, Skeletonparent, LOD-Bias und Custom-AABB ihrer Quelle. Schatten werden für den zusätzlichen Akzent ausgeschaltet; die originalen Körper- und Propoberflächen samt Schatten bleiben erhalten. Ein tatsächlicher Transformunterschied von einem Mikrometer wird weiterhin exakt übertragen. Dispose entfernt alle zusätzlichen Geschwister.

Der Tiefenguard berechnet den exakten Support eines transformierten AABB statt aller acht Ecktransforms. Während der sechs wirklichen Basis-/Signaturproben pro Klasse ersetzt dies **848 → 106** Eck-/Zentrumsberechnungen beim Arcanist, **632 → 79** beim Vowkeeper und **688 → 86** beim Ranger. Körper und Kleidung teilen ihre Bone-Transforms, benötigen aber getrennte Boxen; die jeweiligen Bone-/Prop-Transforms betragen 67 / 67 / 70. Der größte Unterschied zur unabhängigen Acht-Ecken-Referenz beträgt **0,00261 mm** und liegt innerhalb der unveränderten 0,1-mm-Prüfgrenze. Die Referenz benutzt dieselben aktuellen Produktionsboxen einschließlich der neuen begrenzten Kleidungsbewegung. Dies ist ein mathematischer Operationsvergleich und keine gemessene Gesamtlaufzeit von 056 gegen 057.

In den vier realen Dungeonregionen prüft der Dekor-Broadphase 37 / 35 / 3 / 7 besuchte geeignete Batches. Davon liegen 34 / 31 / 2 / 6 vollständig hinter der Hero-Grenze und werden vor jeder Perspektivprojektion verworfen. Die erste Diagnose benötigt dadurch **24 / 32 / 8 / 8 Eckprojektionen**; eine identische Wiederholung benutzt **null Eckprojektionen, null Tiefensupport-Neuberechnungen und null Kamera-Inversionen**. Kamera-, Linsen-, Batch- und Hero-Fensteränderungen werden gegen das ursprüngliche Verfahren geprüft. Die normalen Reise- und besiegten Zustände erzeugen keine Hero-Verdeckungsfenster. Alle autoritativen Simulationssnapshots und Kameratransforms bleiben unverändert.

Die nativen Spieler und Gegner legen außerdem keine unbenutzten kompatiblen ShaderMaterial-Instanzen an; ihre tatsächlich sichtbaren PBR-Materialien behalten ihre Identität. Vorhandene Textur-Preloads werden damit nicht als eingesparter Texturspeicher ausgegeben. Der Randshader verwendet `edge * edge` für denselben mathematischen Quadratterm; daraus wird kein gemessener GPU-Instruktionsgewinn behauptet.

## Importierte LODs und richtige Schatten

Die LOD-Indizes werden aus der öffentlichen RenderingServer-Oberfläche gelesen. Unabhängig bekannte Meshes mit 8, 65.536 und 65.537 Vertices prüfen die exakte 16-/32-Bit-Packungsgrenze und den vollständigen Roundtrip durch ein dynamisch abgeleitetes Mesh. Eine zusätzliche nicht indizierte Dreiecksfläche prüft den korrekten Vertex-Fallback bei `index_count = 0`.

Normalenfinish behält die ursprünglichen Positionen und sämtliche importierten LOD-Indizes sowie das gleiche originale zusammengeführte Schattenmesh. Die fünf dynamischen Arcanist-Datensätze und je zwei Ranger-/Vowkeeper-Datensätze behalten ebenfalls jeden ursprünglichen LOD-Abstand und Index. Bewegte Kleidungsmeshes zeichnen ihre wirklich aktualisierten Hauptvertices als Schatten, sodass eine bewegte Falte kein veraltetes statisches Schattenmesh benutzt. Dies fügt keine Geometrie-Darstellungsfläche hinzu.

Die folgenden Zahlen stammen von den tatsächlichen sichtbaren Produktionsmeshes in Ruhe. „Verfügbar gröbste“ summiert die niedrigste vorhandene Indexstufe jeder Oberfläche. Diese Summe ist eine Ressourceneigenschaft und keine Behauptung über die im Spiel gleichzeitig ausgewählten Stufen.

| Figur/Rolle | Hochaufgelöste Dreiecke | Verfügbar gröbste Dreiecke | Oberflächen mit LODs |
| --- | ---: | ---: | ---: |
| Arcanist | 28.708 | 2.406 | 21 |
| Vowkeeper | 31.440 | 4.910 | 15 |
| Ranger, ohne unsichtbaren Pfeil | 32.884 | 2.814 | 14 |
| Hexer | 28.506 | 1.744 | 16 |
| Bulwark | 22.162 | 4.248 | 14 |
| Elite | 22.114 | 4.200 | 14 |
| Guardian 0 | 24.494 | 4.254 | 12 |
| Guardian 1 | 29.392 | 3.164 | 16 |
| Guardian 2 | 29.070 | 3.174 | 16 |
| Guardian 3 | 22.138 | 4.322 | 13 |

Jede neue Gegnerrolle stimmt mit ihrer tatsächlichen deklarierten Geometriezahl überein und hält das Budget von 40.000 Dreiecken ein. Der Bericht enthält pro Mesh alle Stufen und ursprünglichen gepackten Indexgrößen. Die Byteinventare zählen Haupt-, Attribut-, Skin- und LOD-Buffer pro unterschiedlicher sichtbarer Meshressource innerhalb einer Figur nur einmal; andere Figuren, versteckte Quellen, Texturen, Schattenbuffer und Treiberallokationen gehören nicht zu dieser Zahl.

## Tatsächliche native Renderer-Zähler

Der native Lauf verwendet Godot **4.7.2**, X11, GL Compatibility / `opengl3`, Mesa 25.0.7 und **llvmpipe**, vier Software-Rendererthreads sowie ein tatsächliches 960×540-Fenster. Dummy-Audio dient ausschließlich dieser Grafikdiagnose. Die V-Sync-Warnung des Softwaretreibers ist im unveränderten Log enthalten; Script-, Shader-, Parser-, Track- und allgemeine Enginefehler fehlen.

Pro Klasse misst die Suite dasselbe eingefrorene anfängliche Dungeonbild vor allen diagnostischen Cast-/Occlusion-Proben: vier echte Renderframes mit ausgelieferter LOD-Schwelle 1,0, vier mit deaktiviertem LOD und vier nach exakter Wiederherstellung. Insgesamt sind dies **36 Renderframes**. Kamera, Actortransform und autoritativer Snapshot müssen identisch bleiben; nach Wiederherstellung stimmen alle vier Renderer-Zähler exakt mit dem Anfang überein.

| Klasse | Sichtbare Primitive: LOD 1,0 / aus | Schattenprimitive: LOD 1,0 / aus | Sichtbare Draw Calls: beide |
| --- | ---: | ---: | ---: |
| Arcanist | 89.292 / 232.586 | 78.790 / 197.826 | 309 |
| Vowkeeper | 91.632 / 235.318 | 81.130 / 200.558 | 297 |
| Ranger | 91.620 / 236.762 | 81.118 / 202.002 | 295 |

Die tatsächliche native LOD-Auswahl zeichnet in diesen drei Ansichten etwa **61–62 % weniger sichtbare Primitive** als dieselbe komplette Ansicht bei ausgeschaltetem LOD; die Anzahl sichtbarer Draw Calls bleibt gleich. Dies umfasst sämtliche sichtbare Dungeon-Geometrie unter der diagnostischen Viewporteinstellung, nicht allein die Figuren und nicht einen gemessenen Gewinn gegenüber 056. Der GL-Renderer meldet für `shadow_draw_calls` jeweils 0 bei positiven Schattenprimitiven; dieser rohe Zähler belegt keine Abwesenheit von Schattenpässen.

## Beleggrenzen und zurückgewiesene Versuche

Die Software-GL-Testumgebung und die Operationen liefern keine physische Android-Frametime-, Akku- oder Wärmemessung. Die neuen nativen Gegner sind geometrisch aufwendiger als die vorherigen einfachen Modelle. Belegt sind konkrete vermiedene Operationen, erhaltene Ressourcenstufen und tatsächlich ausgewählte native Geometrie; eine niedrigere Gesamtlast gegenüber 056 wird daraus nicht abgeleitet.

Der erste Versuch scheitert an einer fehlenden expliziten GDScript-Bool-Typangabe im zusätzlichen Test. Der zweite tatsächliche Headless-Lauf beendet sich korrekt mit Exit 1 und 287/3, weil die Fixture den anfänglichen `travel`-Zustand fälschlich als lebenden `combat`-Fall prüft. Der finale Test setzt den diagnostischen Zustand ausdrücklich und restauriert anschließend die ursprüngliche Phase. [Parserfehler](rejected-type-inference/headless-operations.log) und [abgewiesene Fixture-Prüfung](rejected-phase-fixture/headless-operations.log) samt Originalreceipts bleiben erhalten; Produktionslogik und physische Prüfgrenzen wurden für diese Fehler nicht abgeschwächt.

[Byte-/Hashinventar der Originalbelege](files-receipt.json), [unveränderter akzeptierter Headless-Log](headless-operations.log), [unveränderter nativer Log](native-gl-primitives.log) und [exakter sequenzieller Runner](run_budget_checks.py) erlauben die Nachprüfung. Die eigentliche Suite ist [`tests/render_budget_smoke.gd`](../../../../tests/render_budget_smoke.gd).
