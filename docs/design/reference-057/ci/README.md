# 057 – tatsächliche CI auf dem finalen Source

Alle drei neuen CI-Läufe für **`1cc13152a83c6631590d4df32ca298700a417df7`** wurden tatsächlich erfolgreich abgeschlossen. Der vollständige Source-Tree ist **`e491d100b89c7b9eae92885d28053086f77c8563`**. Die hier als aktuell ausgewiesenen Ergebnisse stammen ausschließlich aus diesen drei Läufen nach der Korrektur des seitlichen Ausweichschritts.

| Tatsächlicher Workflow / Originaljob | Ergebnis aus dem vollständigen Joblog |
| --- | --- |
| [Gameplay Quality / 113017205608](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37686979998/job/113017205608) | success; **53 Godot-Suiten, 13,424 Checks, 0 Fehler**; **59 Python-Tests**; exportierter Resource-PCK **60/0**; Node-Syntax und tatsächlicher Server-Progressionstest erfolgreich |
| [Android Debug APK / 113017204783](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37686979978/job/113017204783) | success; **32 Godot-Suiten, 8,503 Checks, 0 Fehler**; **39 Python-Tests**; Debug-/CI-Beta-APK-Signaturen v2/v3, AAB-Struktur/JAR-Signatur und isolierter Account-Transfer erfolgreich |
| [Android Beta Runtime / 113017205393](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37686980000/job/113017205393) | success; **39 Python-Tests**; vier isolierte QA-APKs gebaut; **alle fünf Android16-x86_64-Emulatormarker** bestätigt |

## Source und tatsächlicher Checkout

Alle vollständigen Logs nennen unter `git log -1 --format=%H` denselben tatsächlichen PR-Merge-Checkout **`46ba36f6cd0871ae469cdb4ce9c04f32b479f0f5`**. Die Original-Commitobjekte und [source-checkout-tree-binding.json](source-checkout-tree-binding.json) bestätigen für alle drei Checkouts exakt den vollständigen Tree des oben genannten Source-Commits. Die abweichende Merge-Commit-ID wurde nicht als abweichende Spielquelle interpretiert.

[independent-verification-receipt.json](independent-verification-receipt.json) prüft zusätzlich die 53 eindeutig registrierten Suiten, ihre tatsächlichen Summen und Reihenfolgen, die 32 Android-Debug-Suiten, die Original-Loghashes, Diagnosezeilen, Signaturen und alle fünf Marker gegen den committed Source. Die vollständig gespeicherten API-Metadaten stehen in `*-run.json`, `*-jobs.json`, `*-artifacts.json` und den Source-/Checkout-Commitobjekten. Artifact-Dateien wurden nicht heruntergeladen.

## Tatsächliche Android-Runtime-Marker

| Originalmarker | Launch | Sekunden nach Prüfstart | tatsächliche PID |
| --- | ---: | ---: | ---: |
| ANDROID_BETA_PASS exact AFK ledger | 1 | 643.322 | 2886 |
| ANDROID_BETA_PASS restart does not repeat | 2 | 13.066 | 6938 |
| ANDROID_SUCCESS_PASS first descent, class relic and combined oath UI | 1 | 71.705 | 7129 |
| ANDROID_SUCCESS_PASS restart preserves combined oaths | 2 | 12.753 | 7435 |
| ANDROID_ART_PASS all four regions rendered | 1 | 430.483 | 7587 |

Die Zeiten dienen zur Zuordnung tatsächlicher Emulatorprüfungen. Sie messen keine Spiel-FPS. Der ARM64-Probe-APK wurde gebaut. Physische Telefon-Frametimes, Thermik, Akku und Touch wurden nicht gemessen.

## Vollständige Logs und Transport

- [gameplay-original-job.log](gameplay-original-job.log), [gameplay-receipt.json](gameplay-receipt.json), [gameplay-summary.log](gameplay-summary.log)
- [android-debug-original-job.log](android-debug-original-job.log), [android-debug-receipt.json](android-debug-receipt.json), [android-debug-summary.log](android-debug-summary.log)
- [android-runtime-original-job.log](android-runtime-original-job.log), [android-runtime-receipt.json](android-runtime-receipt.json), [android-runtime-summary.log](android-runtime-summary.log)

Der GitHub-Connector liefert die vollständigen Joblogs als bereits decodierten UTF-8-Text. Dieser Text wurde ohne Textänderung als UTF-8 gespeichert; vorhandene BOM und Zeilenenden bleiben erhalten. Die jeweiligen `*-log-transport.json` belegen Tool, tatsächliche Job-ID, Bytezahl und SHA-256. Eine unabhängig nachgewiesene Gleichheit mit den HTTP-Transportbytes wird nicht behauptet.

Alle aktuellen Logs sind frei von unerwarteten Script-/Shader-/Parse-/Compile-/ERROR-Diagnosen und relevanten Engine-Warnungen. Die beiden gezielt erzeugten Persistence-EOF-Zeilen im Android-Debug-Log sind mit ihrem tatsächlichen Backtrace und erfolgreichem 89/0-Korruptionstest separat ausgewiesen. [all-three-ci-receipt.json](all-three-ci-receipt.json) bündelt die aktuellen Ergebnisse, [proof-manifest.json](proof-manifest.json) bindet die lokalen Belege an Hashes und Bytezahlen.

Die unveränderte 32-Suitenliste des Android-Debug-Workflows enthält `SourceAvatarEvade` nicht. Die 444 zusätzlichen Ausweichschritt-Checks werden im vollständigen 53-Suiten-Gameplay-Lauf ausgeführt. Eine frühere Scratch-Erwartung von 8.947 Android-Checks war deshalb falsch und wurde mit tatsächlichem Assertion-Exit 1 verworfen; kein Spieltest und kein Testkriterium wurde dafür geändert. [android-expected-total-correction.json](android-expected-total-correction.json) belegt die committed Inventarliste, [android-rejected-expectation-output-preservation.json](android-rejected-expectation-output-preservation.json) bewahrt den ursprünglichen Tool-Output mit seiner tatsächlichen Herkunft.

## Unveränderte frühere Versuche

`history/original-02a3fc9/` bewahrt die tatsächlichen früheren Beobachtungen und vollständigen Abschlusslogs: Gameplay 37680231176 wurde abgebrochen, Android Debug 37680231278 scheiterte mit tatsächlichem Timeout-Exit 124, Runtime 37680231428 war erfolgreich. `history/workflow-only-equivalence.json` bewahrt den damaligen Vergleich der einzigen Änderung von 120 auf 300 Sekunden Prozessbudget; Testinhalt und Spielquelle blieben dabei identisch. Die 26 damaligen Release-Contracttests bleiben ebenfalls erhalten.

`history/pre-evade-f8b99a8/` enthält die drei tatsächlich erfolgreichen Zwischenläufe mit **53 Suiten / 12.980 Checks** vor der später bestätigten und behobenen seitlichen Fußkreuzung. Diese Belege behalten ihre ursprüngliche Source-ID, Zeitstempel, Hashes und Prüfsummen; sie werden nicht zum aktuellen Source-Ergebnis umbenannt.

## Offline-Reproduktion

Der Parser braucht für `summarize` weder Netzwerk noch Engine. In einem separaten Arbeitsverzeichnis mit Kopien der JSON-/LOG-Dateien:

```sh
python3 collect_ci_receipts.py summarize --source 1cc13152a83c6631590d4df32ca298700a417df7 --directory /path/to/evidence-copy
```

Der unabhängige Inventarprüfer benötigt zusätzlich das Git-Repository mit dem oben genannten Source-Commit:

```sh
python3 verify_ci_leaf_inputs.py --source 1cc13152a83c6631590d4df32ca298700a417df7 --directory /path/to/evidence-copy --repo-directory /path/to/repository --expected-gameplay-checks 13424 --expected-gameplay-python-tests 59 --expected-android-debug-checks 8503 --expected-android-python-tests 39
```
