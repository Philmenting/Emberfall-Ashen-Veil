# 056 – aktuelle GitHub-CI

Alle drei neuen PR-CI-Läufe für Source **`5e72fc6fad38f7dc829d313d8df0de8289f52573`** wurden tatsächlich erfolgreich abgeschlossen. Diese Belege stammen aus 056; Ergebnisse aus 055 wurden nicht als aktuelle Ergebnisse verwendet.

| Tatsächlicher Workflow / Originaljob | Ergebnis aus dem unveränderten Original-Joblog |
| --- | --- |
| [Gameplay Quality / 112646109974](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37576383396/job/112646109974) | success; **49 Godot-Suiten, 7.734 Checks, 0 Fehler**; **48 Python-Tests**; exportierter Resource-PCK **32 Checks, 0 Fehler**; Node-Syntax und tatsächlicher Server-Progressionstest erfolgreich |
| [Android Debug APK / 112646109710](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37576383412/job/112646109710) | success; **28 Godot-Suiten, 3.298 Checks, 0 Fehler**; **34 Python-Tests**; Debug-/CI-Beta-APK-Signaturen v2/v3 und AAB-Struktur/JAR-Signatur validiert; isolierter Account-Transfer/Fellowship-Test erfolgreich |
| [Android Beta Runtime / 112646109906](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37576383459/job/112646109906) | success; **34 Python-Tests**; vier isolierte QA-APKs gebaut; **alle fünf tatsächlichen Android16-x86_64-Emulatormarker** bestätigt |

Die ursprünglichen Joblaufzeiten waren 900 s, 1.013 s und 1.761 s. Die Laufzeit dient der Zuordnung des Jobs und misst keine Spiel-FPS.

## Source und tatsächlicher Checkout

Die ursprünglichen Logs aller drei Jobs nennen unter `git log -1 --format=%H` denselben tatsächlichen PR-Merge-Checkout:

- Source-Head: `5e72fc6fad38f7dc829d313d8df0de8289f52573`
- tatsächlicher Checkout: `750cb2e6660623a60fc436ec732ce046b211253e`
- **exakt gleicher vollständiger Git-Tree:** `05754daf53dfaf28e12b0fdcf26572373a0c5585`
- Merge-Parents: `610c343073e7186589cba92c3fefb55a4db68e12` und der oben genannte Source-Head

Die Remote-Git-API hat beide Commitobjekte und die gleiche Tree-ID bestätigt. [source-checkout-tree-binding.json](source-checkout-tree-binding.json) bindet diese Metadaten an alle drei tatsächlichen Checkoutzeilen. Die unveränderten API-Commitobjekte stehen in [source-commit-raw.json](source-commit-raw.json) und [checkout-commit-raw.json](checkout-commit-raw.json).

## Tatsächliche Android-Runtime-Marker

| Originalmarker | Launch | Sekunden nach Start der jeweiligen Prüfung | tatsächlicher Prozess |
| --- | ---: | ---: | ---: |
| ANDROID_BETA_PASS exact AFK ledger | 1 | 712,161 | 2869 |
| ANDROID_BETA_PASS restart does not repeat | 2 | 13,177 | 6760 |
| ANDROID_SUCCESS_PASS first descent, class relic and combined oath UI | 1 | 68,159 | 6951 |
| ANDROID_SUCCESS_PASS restart preserves combined oaths | 2 | 12,831 | 7209 |
| ANDROID_ART_PASS all four regions rendered | 1 | 539,137 | 7356 |

Diese Werte sind die originalen Markerwartezeiten im CI-Emulator. Der Prüfumfang umfasst AFK-Rewards, kalte Neustarts ohne doppelte Auszahlung, Success-Loop und vier tatsächlich gerenderte Regionen. Der ARM64-Probe-APK wurde gebaut; ein physisches Telefon wurde hier nicht gemessen. Reale Geräte-Frametimes, Thermik, Akku und Touch bleiben außerhalb dieses CI-Belegs.

## Originale und Diagnosen

Die UTF-8-Original-Joblogs wurden unverändert gespeichert, einschließlich vorhandener UTF-8-BOM und originaler Zeilenenden:

- [gameplay-original-job.log](gameplay-original-job.log), [gameplay-receipt.json](gameplay-receipt.json), [gameplay-summary.log](gameplay-summary.log)
- [android-debug-original-job.log](android-debug-original-job.log), [android-debug-receipt.json](android-debug-receipt.json), [android-debug-summary.log](android-debug-summary.log)
- [android-runtime-original-job.log](android-runtime-original-job.log), [android-runtime-receipt.json](android-runtime-receipt.json), [android-runtime-summary.log](android-runtime-summary.log)

Gameplay und Runtime enthalten keine passenden Script-/Shader-/Parse-/Compile-/ERROR-Diagnosen. Android Debug enthält zwei absichtliche `ConfigFile parse error ... Unexpected EOF`-Zeilen: `tests/persistence_smoke.gd:173–176` schreibt beide Generationen gezielt als `[broken`, damit der Schutz vor dem Überschreiben korrupten Fortschritts geprüft wird. Derselbe tatsächliche Persistence-Lauf endet **89 Checks / 0 Fehler**. Weitere Engine-Diagnosen wurden im Original-Joblog nicht gefunden.

`*-run.json` und `*-jobs.json` sind die tatsächlichen API-Metadaten der abgeschlossenen Jobs. `*-artifacts.json` enthält ausschließlich die verfügbaren Artifact-Metadaten mit IDs/Größe/Digests; **keine APK/AABs oder anderen Binärartifacts wurden heruntergeladen**. [all-three-ci-receipt.json](all-three-ci-receipt.json) bündelt die Ergebnisse. [proof-manifest.json](proof-manifest.json) enthält Hashes und Bytezahlen der lokalen unveränderten Belege.

Der beigefügte Parser [prepare_ci_receipts.py](prepare_ci_receipts.py) wertet ausschließlich die lokal gespeicherten Originale aus; er startet keine Engine und kein Netzwerk. Reproduktion aus diesem Verzeichnis:

```sh
python3 prepare_ci_receipts.py --source 5e72fc6fad38f7dc829d313d8df0de8289f52573 --directory .
```
