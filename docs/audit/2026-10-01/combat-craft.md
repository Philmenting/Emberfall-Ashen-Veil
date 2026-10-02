# Kampflesbarkeit und Kampfstile – Prüfprotokoll

Stand: 1. Oktober 2026. Godot 4.7.2.stable.official.ed1daf0bf.

Der abschließende vollständige Lauf von `python3 scripts/run_beta_checks.py`
besteht **18 Godot-Suiten mit 1.355 Checks und 0 Fehlern**. Die Suiten verwenden
isolierte temporäre Spielstände. Node-Syntaxprüfung und Serverlaufzeitprüfung
bestehen ebenfalls.

| Suite | Checks | Ergebnis |
| --- | ---: | --- |
| COMBAT STANCES SMOKE | 140 | Bestanden |
| COMBAT MOVEMENT SMOKE | 8 | Bestanden |
| JOURNEY SMOKE | 413 | Bestanden |
| DUNGEON SMOKE | 55 | Bestanden |
| PERSISTENCE SMOKE | 89 | Bestanden |
| ARCANE TACTICS SMOKE | 29 | Bestanden |
| BOSS PATTERNS SMOKE | 114 | Bestanden |
| CLASS LOOT SMOKE | 29 | Bestanden |
| CONTRACTS SMOKE | 68 | Bestanden |
| GEAR / FORECAST SMOKE | 38 | Bestanden |
| REGIONS SMOKE | 36 | Bestanden |
| ONBOARDING SMOKE | 19 | Bestanden |
| OPTIONS SMOKE | 73 | Bestanden |
| SKILL ROTATION SMOKE | 135 | Bestanden |
| VISUALS SMOKE | 57 | Bestanden |
| FELLOWSHIP UI SMOKE | 11 | Bestanden |
| CLOUD IDENTITY SMOKE | 14 | Bestanden |
| MANA WARD SMOKE | 27 | Bestanden |

Die zehn [Grafikaufnahmen](../../previews/combat-craft/) wurden mit der realen
OpenGL-Kompatibilitätsdarstellung unter Linux/Mesa llvmpipe erzeugt und in zwei
begrenzten Kontrollrunden bei 1280×720 und 854×480 geprüft. Die Vorschau erreicht
die vier Bosswarnungen durch die tatsächliche Simulation; erhöhtes Leben hält
den visuellen Test unabhängig von der Etagenbalance. Die Aufnahmen sind kein
Balance- oder Leistungsnachweis.

Ein physischer Android-Gerätetest, mobile Leistungsmessungen und ein APK-Export
wurden in diesem Ausbau nicht durchgeführt. Die Startetage ist für alle drei
Klassen und Stile geprüft; eine breite Endgame-Balanceerhebung bleibt offen.

[Änderungen und Wiederholungsanleitung](../../COMBAT_CRAFT.md)
