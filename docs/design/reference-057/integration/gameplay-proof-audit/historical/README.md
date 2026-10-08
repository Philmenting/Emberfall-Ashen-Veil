# Historischer Fehler der ersten Audit-Fassung

Die erste unabhängige Audit-Fassung endete tatsächlich mit **Exit 1**, weil ihr eigenes Skript `row['camera']` für jeden Frame voraussetzte. Originale Abschlussframes können dieses optionale Feld auslassen. Der erhaltene Bericht nennt ausschließlich `Audit execution exception: KeyError('camera')`; dies ist ein Fehler der Audit-Annahme und kein nachgewiesener Spiel-, Film- oder Quellenfehler.

Die spätere Fassung vergleicht `row.get('camera')` für beide Seiten, wie die ursprüngliche Vergleichsanalyse. Diese Korrektur betrifft ausschließlich das Scratch-Audit. Keine Spielquelle und kein ursprünglicher Capture-Nachweis wurde geändert. Die abschließend erfolgreiche Fassung liegt [eine Ebene höher](../README.md).

- [Ursprüngliches erstes Audit-Skript](audit.py)
- [Ursprünglicher Fehlerbericht](audit-report.json)
- [Ursprüngliches Fehlerlog](audit-execution.log)
- [Tatsächlicher Exit 1 und Original-Hashes](audit-execution.json)
- [Zusätzliche unveränderte SHA256-/Inode-Provenienz](../hardlink-staging-receipt.json)

Die erste Fassung ist unverändert erhalten und gilt ausdrücklich nicht als abgeschlossene technische Prüfung der sechs Filme.
