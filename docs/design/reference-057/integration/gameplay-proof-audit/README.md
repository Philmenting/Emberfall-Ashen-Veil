# Unabhängiger technischer Gameplay-Nachweis

Die unabhängige Analyse des abgeschlossenen [Gameplay-Nachweises](../../gameplay/README.md) endete tatsächlich mit **Exit 0: 6.188 Integritätsprüfungen, 0 Abweichungen**. Der unveränderte Snapshot wurde am 8. Oktober 2026 von 00:14:11 bis 00:14:24 UTC geprüft; die technische Gameplay-README hatte dabei SHA256 `d3fcb0320848c02627f974901fd159484b1426400d22aa1ff3c2e8b9fe10509f`.

Geprüft wurden alle sechs gewöhnlichen Vorher-/Nachher-Expeditionen der drei Klassen, 355 ursprüngliche Nachweisdateien mit 607.570.867 logischen Bytes, 280 unveränderte native PNGs, die tatsächlichen ursprünglichen Prozess- und erneuten Analyseabschlüsse, der Supervisor-Wait-Exit und dessen Session-Hash. Sechs zusätzliche MP4-Container-Probes hatten jeweils Exit 0. Die vollständigen Frame-Uhren, autoritativen Zustände und optionalen Kameratransformationen stimmen je Klassenpaar überein; Cue-Inhalte stimmen außer dem ausdrücklich erhaltenen originalen `acceptance_wall_msec` überein. Die vollständigen Stereo-PCM-Archive wurden verlustfrei überprüft und sind je Paar bytegleich über ihre SHA256-Bindung. 1.059 eindeutige Git-Blobs, sämtliche 851 historischen Exportdateien mit genau zwei offengelegten Capture-GD-Overlays, 18 lokale technische README-Links und der Ausschluss von Runtime-Caches wurden ebenfalls geprüft. Alle 44 Dateien des unterbrochenen Altversuchs blieben erhalten; seine ungültige Aufnahme zählt ausdrücklich nicht zu den sechs erfolgreichen Filmen.

Der Nachher-Stand ist `1cc13152a83c6631590d4df32ca298700a417df7`, der Vorher-Stand `86cb1b8ec878b4ae06daba5e6c5a4fa583865dc5`. Das Audit startete keine Engine, änderte keine Spielquelle und führte keine vollständige Testsuite erneut aus. Seine technische Prüfung bestätigt ursprüngliche vollständige Decoder-Ergebnisse; die zusätzlichen Probes prüfen die Container unabhängig, ohne einen weiteren vollständigen Decoder-Lauf zu behaupten.

Die später ergänzte zeitliche Sichtprüfung ist außerhalb dieses Snapshots. Das Audit behauptet weder eine vollständige visuelle Filmsichtung noch ästhetische Freigabe, Beta- oder Veröffentlichungsreife oder Leistung auf einem physischen Telefon.

- [Unverändertes Audit-Skript](audit.py)
- [Vollständiger originaler Audit-Bericht](audit-report.json)
- [Ursprüngliches Ausführungslog](audit-execution.log)
- [Tatsächlicher Exit und Hash-Bindung](audit-execution.json)
- [SHA256- und Hardlink-Staging-Nachweis](hardlink-staging-receipt.json)
- [Erhaltene erste Audit-Fassung mit falscher Kamera-Annahme](historical/README.md)

Alle acht ursprünglichen Audit-Dateien sind im Workspace exakt hardgelinkt; ihre Scratch-Originale bleiben unverändert. Der Staging-Nachweis nennt jede Datei, ihren Originalpfad, SHA256, Größe und überprüfte Inode-Identität. Git speichert diese regulären Dateien unabhängig von lokalen Hardlinks.
