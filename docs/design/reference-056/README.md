# Nachweise zur Qualitätsüberarbeitung 056

Stand vom 7. Oktober 2026: Diese Sammlung dokumentiert vier konkrete Änderungen und ihre jeweils tatsächlich ausgeführten lokalen Prüfungen. Der [Gesamtbericht](../../QUALITY_056.md) erläutert Verhalten und Grenzen.

**Finaler 056-Source-SHA: [`5e72fc6fad38f7dc829d313d8df0de8289f52573`](https://github.com/Philmenting/Emberfall-Ashen-Veil/commit/5e72fc6fad38f7dc829d313d8df0de8289f52573).** Der geprüfte Quellstand ist auf GitHub bestätigt. Die lokalen Receipts binden originale Logs und Bilder; frühe Teilprüfungen werden ihrem damaligen Stand zugeordnet. Nach der letzten Raider-Korrektur bestehen vier betroffene Suiten mit 641 Prüfungen und das exportierte Paket mit 32 Prüfungen, jeweils null Fehler.

| Maßnahme | Vorhandener Beleg | Aussagegrenze |
| --- | --- | --- |
| Arcanist-Körpergewicht, Knie-/Hüft-/Schultertransfer | [Angriffe](attacks/README.md), [Receipt](attacks/receipt.json), 172/0 Attack, 295/0 zusätzlicher Kontakt, 296/0 Griff; sechs native Last-/Catchbilder mit 49/0; [normaler Kampf](gameplay/README.md) | Originale Stillposen und tatsächliche ausgewählte Spielbildfolgen; Signatur kurz, Starfall weiterhin moderat |
| Bekleideter nativer Raider und ursprüngliche Source-Axt | [Native Bilder und 324/0](raider/README.md), [Quellen und Wiederaufbau](../../../assets/models/raider056/README.md); 18.560 Körper- plus 1.098 Axtdreiecke | Tatsächliche Flächenkontakte an 15 Posen, drei Gegenkontakte, sechs Studiobilder; weitere sieben Gegner-/Wächtermodelle bleiben vorhanden |
| Gerichteter niedriger Schritt für Arcanist, Ranger und Vowkeeper | [Ausweichen](evade/README.md), [Receipt](evade/evade-proof-receipt.json), 1.729/0 sowie sechs akzeptierte native Bilder | Prozedurale anatomische Bewegung; begrenzte tatsächliche Warnungs-/World-Probe und Studioansichten, kein vollständiger Dungeon |
| Bossverdeckung mit opaken Modellen und separatem Hero-Akzent | [Verdeckung](combat-readability/README.md), [Receipt](combat-readability/receipt.json), 25/0 und vier originale UI-Bilder | Zusätzliche Life in Guardian-Inspektion, gezielte Renderer-Überlappung; konservativer Depth-Guard und keine Telefonkostenmessung |

Alle als angenommen gekennzeichneten nativen Bilder stammen direkt aus dem Godot-4.7.2-Renderer und behalten ihre ursprünglichen Pixel. Die Einzelreceipts speichern SHA-256, reale Prozessausgänge und Bildscope. Sie unterscheiden frühere Fehlversuche, unvollständige Bilder und nur scheinbare Exit-0-Läufe von gültigen Belegen. Checkzahlen ersetzen keine Sichtprüfung der Bewegung.

## Integration

Die [drei migrierten Suiten](integration/focused-tests-receipt.json) bestehen mit **317 Prüfungen, null Fehlern und tatsächlichem Exit 0**. Der [Originalrunnerlog](integration/focused-tests.log) enthält auch die erfolgreichen Serverprüfungen. Der Receipt hält ausdrücklich fest, dass dieser Lauf vor dem letzten Raider-Axtgriffstand liegt.

Weitere lokale Resultate sind **45 restliche Godot-Suiten / 7.093 Prüfungen / null Fehler** und **48 Python-Verträge / null Fehler**. Nach der letzten Raider-Korrektur wurden Character 3D, Presentation, Hostile Quality und Raider Native gemeinsam erneut geprüft: **641/0**. Ein erneuter Editorimport und der exportierte Ressourcencheck aus leerem externen Verzeichnis bestehen ebenfalls: **32/0**. [Originale lokale Logs und Receipt](local-verification/local-receipt.json) weisen die Reihenfolge und tatsächlichen Exitcodes aus. Die getrennten Teilresultate ersetzen nicht die aktuelle vollständige 49-Suiten-CI.

| Abschließender Nachweis | Status |
| --- | --- |
| Letzte Raider-Holzgriffkorrektur mit tatsächlichem Skin-/Facettenkontakt | **324/0**, 15 Posen, tatsächlicher Exit 0 |
| Unveränderliche komplette 056-Quelle und exakter Source-SHA | **5e72fc6fad38f7dc829d313d8df0de8289f52573**, remote bestätigt |
| Vollständige aktuelle Gameplay-CI | **49 Suiten / 7.734 Prüfungen / 0 Fehler**, Python **48/0**, Paket **32/0** |
| Exportiertes Figurenpaket aus leerem externen Verzeichnis: 32 Prüfungen | **32/0**, tatsächlicher Exit 0 |
| Finales gewöhnliches 30-Sekunden-Präfix mit Ton, realen Poseframes und vollständiger Source-/Autoritätsprüfung | **900 Frames**, Exit 0; [Filme und Receipts](gameplay/README.md) |
| Unabhängige Sichtung tatsächlicher Last-/Release-/Catch-/Ausweichfolgen | [Sichtbericht](gameplay/MOTION_REVIEW.md), ausgewählte tatsächliche Bilder |

## Scope der geprüften Spielaufnahme

Der tatsächliche Capture über `tools/capture_combat_quality.py` exportiert die chronologischen ersten **30 Sekunden / 900 Frames** einer gewöhnlichen Arcanist-Expedition mit normaler Ausrüstung, ursprünglicher HUD/Kamera und realen Simulationsereignissen. `frames.jsonl` protokolliert die tatsächlich sichtbaren Posen. Alle drei Arcanist-Phrasen, zwei echte Ausweichereignisse und ein früher Skillabbruch kommen vor. Der [Sichtbericht](gameplay/MOTION_REVIEW.md) beurteilt ausgewählte native Bildfolgen; der Präfix enthält keinen Guardian-Kampf.

Das Präfix ist ausdrücklich unvollständig; der tatsächliche Spielstand bleibt `won=false`. Source-/Bild-/Audiohashes, Launcher-Exit 0 und vollständige Dekodierung sind geprüft. Alle 900 Autoritäts- und Kameraframes stimmen zwischen 055 und 056 überein, die native Tonspur ist bitgleich. Bei den protokollierten Audioereignissen unterscheiden sich ausschließlich Prozess-Wandzeitstempel; dies ist separat dokumentiert. Die Präsentationsposen und Bilder zeigen die beabsichtigten Änderungen. Native Original-PNGs und verlustbehaftete H.264-Dekodierungen erhalten ihre korrekten Labels. Die Wiedergabeuhr ist keine Messung von Telefon-Frametimes.

Alle drei aktuellen CI-Läufe sind erfolgreich. [Originale Joblogs, Receipts und Git-Treebindung](ci/README.md) weisen Gameplay, Android-Build/-Bundle und Android-Laufzeit separat nach. Die abschließende Dokumentation verändert keine geprüften Produktions-, Test-, Tool- oder Workflowdateien. Die Sammlung begründet keine allgemeine visuelle Releasefreigabe.
