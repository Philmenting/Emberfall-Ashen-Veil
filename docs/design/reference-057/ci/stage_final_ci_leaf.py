#!/usr/bin/env python3
"""Stage accepted exact-source CI and distinct immutable historical evidence.

No Engine, network, Git, dispatch or binary artifact download. Existing evidence
is copied byte for byte. The destination must not already exist.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--directory", type=Path, required=True)
    parser.add_argument("--destination", type=Path, required=True)
    args = parser.parse_args()
    source = args.source
    directory = args.directory
    base = Path(__file__).parent
    combined = json.loads((directory / "all-three-ci-receipt.json").read_bytes())
    independent = json.loads((directory / "independent-verification-receipt.json").read_bytes())
    binding = json.loads((directory / "source-checkout-tree-binding.json").read_bytes())
    assert combined["source_commit"] == independent["source_commit"] == source
    assert combined["all_three_actual_current_runs_success"] is True
    assert independent["all_verifications_passed"] is True and independent["actual_exit_code"] == 0
    assert combined["binary_artifacts_downloaded"] is False and combined["older_source_results_used"] is False
    assert binding["all_three_exact_whole_tree_match"] is True
    assert len(binding["bindings"]) == len(combined["checks"]) == 3
    assert source not in {"02a3fc905e55a4e64cbece4eb6b07c65c1bf4afb", "f8b99a84b4c96a87c4ecedf42217f448a2988d81"}
    # Acceptance belongs to the saved bytes, not merely an earlier success flag.
    assert independent["collector_sha256"] == digest(base / "collect_ci_receipts.py")
    assert independent["verifier_sha256"] == digest(base / "verify_ci_leaf_inputs.py")
    spec = importlib.util.spec_from_file_location("ci_stage_parser", base / "collect_ci_receipts.py")
    assert spec and spec.loader
    collector = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(collector)
    source_metadata = json.loads((directory / "source-commit-raw.json").read_bytes())
    assert source_metadata["sha"] == source and source_metadata["tree"]["sha"] == combined["source_tree"]
    for key, (name, _, job_name) in collector.WORKFLOWS.items():
        raw = (directory / f"{key}-original-job.log").read_bytes()
        parsed = collector.parse_log(raw, key)
        receipt = json.loads((directory / f"{key}-receipt.json").read_bytes())
        run = json.loads((directory / f"{key}-run.json").read_bytes())
        jobs = json.loads((directory / f"{key}-jobs.json").read_bytes())["jobs"]
        job = [entry for entry in jobs if entry["name"] == job_name]
        assert len(job) == 1 and job[0]["status"] == "completed" and job[0]["conclusion"] == "success"
        assert run["name"] == name and run["head_sha"] == source
        assert run["status"] == "completed" and run["conclusion"] == "success"
        assert receipt["source_commit"] == source and receipt["workflow_run"] == run["id"]
        assert receipt["job_id"] == job[0]["id"] and receipt["actual_current_source_success"] is True
        combined_check = [entry for entry in combined["checks"] if entry["workflow"] == name]
        assert combined_check == [receipt]
        verified = [entry for entry in independent["verified_workflows"] if entry["workflow"] == name]
        assert len(verified) == 1 and verified[0]["original_log_sha256"] == digest(directory / f"{key}-original-job.log")
        assert receipt["summary_sha256"] == digest(directory / f"{key}-summary.log")
        assert (directory / f"{key}-summary.log").read_bytes() == parsed["summary"].encode("utf-8")
        for field, value in parsed.items():
            if field != "summary":
                assert receipt[field] == value, (key, field)
        transport = json.loads((directory / f"{key}-log-transport.json").read_bytes())
        assert transport["source_commit"] == source and transport["job_id"] == job[0]["id"]
        assert transport["log_sha256"] == digest(directory / f"{key}-original-job.log")
        assert transport["log_bytes"] == len(raw)
        current_binding = [entry for entry in binding["bindings"] if entry["workflow"] == name]
        assert len(current_binding) == 1
        current_binding = current_binding[0]
        checkout_path = directory / f"{key}-checkout-commit-raw.json"
        checkout_metadata = json.loads(checkout_path.read_bytes())
        assert current_binding["raw_source_commit_metadata_sha256"] == digest(directory / "source-commit-raw.json")
        assert current_binding["raw_checkout_metadata_sha256"] == digest(checkout_path)
        assert checkout_metadata["sha"] == parsed["actual_checkout_commit"]
        assert checkout_metadata["tree"]["sha"] == source_metadata["tree"]["sha"]
        assert checkout_metadata["sha"] == source or source in [entry["sha"] for entry in checkout_metadata["parents"]]
        assert current_binding["source_commit"] == source_metadata["sha"]
        assert current_binding["source_tree"] == source_metadata["tree"]["sha"]
        assert current_binding["actual_checkout_commit"] == checkout_metadata["sha"]
        assert current_binding["actual_checkout_tree"] == checkout_metadata["tree"]["sha"]
    checks = {entry["workflow"]: entry for entry in combined["checks"]}
    gameplay = checks["Gameplay Quality"]
    debug = checks["Android Debug APK"]
    runtime = checks["Android Beta Runtime"]
    assert independent["expected_gameplay_checks"] == gameplay["godot_checks"]
    assert independent["expected_gameplay_python_tests"] == gameplay["python_test_runs"][0]
    assert independent["expected_android_debug_checks"] == debug["godot_checks"]
    assert independent["expected_android_python_tests"] == debug["python_test_runs"][0] == runtime["python_test_runs"][0]
    destination = args.destination
    destination.mkdir(parents=True, exist_ok=False)
    entries = []

    def copy_file(original: Path, relative: str, scope: str) -> None:
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(original, target)
        assert digest(target) == digest(original)
        entries.append({"path": relative, "sha256": digest(target), "bytes": target.stat().st_size,
                        "original_path": str(original), "original_sha256": digest(original),
                        "copy_byte_identical": True, "scope": scope})

    def copy_directory(original: Path, prefix: str, scope: str) -> None:
        for path in sorted(original.iterdir()):
            if path.is_file() and path.suffix in {".json", ".jsonl", ".log", ".py"}:
                copy_file(path, str(Path(prefix) / path.name), scope)

    copy_directory(directory, "", "Accepted final source, three actual completed hosted CI runs")
    copy_directory(base / "final-timeout-fixed", "history/pre-evade-f8b99a8", "Historical source before the real lateral Evade correction; all three runs passed")
    copy_directory(base / "final-current", "history/original-02a3fc9/observations", "Historical API observations and the original timeout failure log")
    copy_directory(base / "historical-original-source-completion", "history/original-02a3fc9/completion", "Historical actual completion: Gameplay cancelled, Debug timeout failure, Runtime success")
    for name in ["workflow-only-equivalence.json", "workflow-timeout-fix-contracts.log"]:
        copy_file(base / name, "history/" + name, "Original single-line 120s to 300s CI allowance correction; not a game change")
    for name in ["collect_ci_receipts.py", "collect_with_connector_logs.py", "verify_ci_leaf_inputs.py", "stage_final_ci_leaf.py"]:
        copy_file(base / name, name, "Exact original read-only evidence tooling")

    checkout = {entry["actual_checkout_commit"] for entry in binding["bindings"]}
    assert len(checkout) == 1
    checkout_sha = next(iter(checkout))
    marker_rows = "\n".join(f"| {entry['marker']} | {entry['launch']} | {entry['elapsed_seconds']:.3f} | {', '.join(map(str, entry['pids']))} |"
                            for entry in runtime["verified_android_markers"])
    def url(value: dict) -> str:
        return value["run_url"] + "/job/" + str(value["job_id"])
    readme = f"""# 057 – tatsächliche CI auf dem finalen Source

Alle drei neuen CI-Läufe für **`{source}`** wurden tatsächlich erfolgreich abgeschlossen. Der vollständige Source-Tree ist **`{combined['source_tree']}`**. Die hier als aktuell ausgewiesenen Ergebnisse stammen ausschließlich aus diesen drei Läufen nach der Korrektur des seitlichen Ausweichschritts.

| Tatsächlicher Workflow / Originaljob | Ergebnis aus dem vollständigen Joblog |
| --- | --- |
| [Gameplay Quality / {gameplay['job_id']}]({url(gameplay)}) | success; **{gameplay['godot_suites']} Godot-Suiten, {gameplay['godot_checks']:,} Checks, 0 Fehler**; **{gameplay['python_test_runs'][0]} Python-Tests**; exportierter Resource-PCK **60/0**; Node-Syntax und tatsächlicher Server-Progressionstest erfolgreich |
| [Android Debug APK / {debug['job_id']}]({url(debug)}) | success; **{debug['godot_suites']} Godot-Suiten, {debug['godot_checks']:,} Checks, 0 Fehler**; **{debug['python_test_runs'][0]} Python-Tests**; Debug-/CI-Beta-APK-Signaturen v2/v3, AAB-Struktur/JAR-Signatur und isolierter Account-Transfer erfolgreich |
| [Android Beta Runtime / {runtime['job_id']}]({url(runtime)}) | success; **{runtime['python_test_runs'][0]} Python-Tests**; vier isolierte QA-APKs gebaut; **alle fünf Android16-x86_64-Emulatormarker** bestätigt |

## Source und tatsächlicher Checkout

Alle vollständigen Logs nennen unter `git log -1 --format=%H` denselben tatsächlichen PR-Merge-Checkout **`{checkout_sha}`**. Die Original-Commitobjekte und [source-checkout-tree-binding.json](source-checkout-tree-binding.json) bestätigen für alle drei Checkouts exakt den vollständigen Tree des oben genannten Source-Commits. Die abweichende Merge-Commit-ID wurde nicht als abweichende Spielquelle interpretiert.

[independent-verification-receipt.json](independent-verification-receipt.json) prüft zusätzlich die 53 eindeutig registrierten Suiten, ihre tatsächlichen Summen und Reihenfolgen, die 32 Android-Debug-Suiten, die Original-Loghashes, Diagnosezeilen, Signaturen und alle fünf Marker gegen den committed Source. Die vollständig gespeicherten API-Metadaten stehen in `*-run.json`, `*-jobs.json`, `*-artifacts.json` und den Source-/Checkout-Commitobjekten. Artifact-Dateien wurden nicht heruntergeladen.

## Tatsächliche Android-Runtime-Marker

| Originalmarker | Launch | Sekunden nach Prüfstart | tatsächliche PID |
| --- | ---: | ---: | ---: |
{marker_rows}

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
python3 collect_ci_receipts.py summarize --source {source} --directory /path/to/evidence-copy
```

Der unabhängige Inventarprüfer benötigt zusätzlich das Git-Repository mit dem oben genannten Source-Commit:

```sh
python3 verify_ci_leaf_inputs.py --source {source} --directory /path/to/evidence-copy --repo-directory /path/to/repository --expected-gameplay-checks {gameplay['godot_checks']} --expected-gameplay-python-tests {gameplay['python_test_runs'][0]} --expected-android-debug-checks {debug['godot_checks']} --expected-android-python-tests {debug['python_test_runs'][0]}
```
"""
    readme_path = destination / "README.md"
    readme_path.write_text(readme, encoding="utf-8")
    entries.append({"path": "README.md", "sha256": digest(readme_path), "bytes": readme_path.stat().st_size,
                    "scope": "Derived narrative; exact results and limitations from saved final and historical evidence"})
    manifest = {"schema": 1, "source_commit": source, "source_tree": combined["source_tree"],
                "all_final_runs_completed_successfully": True, "binary_artifacts_downloaded": False,
                "historical_results_contribute_to_current_quality": False,
                "files": entries}
    manifest_path = destination / "proof-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    receipt = {"schema": 1, "observed_at": datetime.now(timezone.utc).isoformat(), "source_commit": source,
               "actual_exit_code": 0, "copied_or_derived_files": len(entries), "copied_file_bytes": sum(x["bytes"] for x in entries),
               "all_original_copies_byte_identical": True, "proof_manifest_sha256": digest(manifest_path),
               "stage_tool_sha256": digest(Path(__file__)), "engine_run": False, "network_used": False,
               "git_mutated": False, "binary_artifacts_downloaded": False,
               "scope": "Final exact-source CI leaf and clearly separate immutable history. Manifest excludes itself and this staging receipt."}
    (destination / "staging-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()
