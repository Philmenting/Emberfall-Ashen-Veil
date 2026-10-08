#!/usr/bin/env python3
"""Independent read-only final-CI verification against committed suite inventory."""
from __future__ import annotations

import argparse
import ast
from collections import Counter
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--directory", required=True, type=Path)
    parser.add_argument("--repo-directory", default="/workspace/Emberfall-Ashen-Veil", type=Path)
    parser.add_argument("--expected-gameplay-checks", default=12980, type=int)
    parser.add_argument("--expected-gameplay-python-tests", default=59, type=int)
    args = parser.parse_args()
    assert re.fullmatch(r"[a-f0-9]{40}", args.source)
    directory = args.directory

    def committed(path: str) -> str:
        return subprocess.run(["git", "show", f"{args.source}:{path}"], cwd=args.repo_directory,
                              capture_output=True, text=True, check=True).stdout

    def digest(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    collector_path = Path(__file__).with_name("collect_ci_receipts.py")
    spec = importlib.util.spec_from_file_location("ci_collector_verified", collector_path)
    assert spec and spec.loader
    collector = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(collector)
    module = ast.parse(committed("scripts/run_beta_checks.py"))
    suites = next(ast.literal_eval(node.value) for node in module.body
                  if isinstance(node, ast.Assign) and any(isinstance(target, ast.Name)
                  and target.id == "GODOT_SUITES" for target in node.targets))
    assert len(suites) == len(set(suites)) == 53
    labels = {}
    for suite in suites:
        matches = set(re.findall(r'"([A-Z][A-Z /]+ SMOKE|SOURCE AVATAR(?: GRIP| ATTACK)?):',
                                 committed(f"tests/{suite}_smoke.gd")))
        assert len(matches) == 1, (suite, matches)
        labels[suite] = next(iter(matches))
    assert len(set(labels.values())) == 53
    debug_suites = re.findall(r"tests/(\w+)_smoke\.gd", committed(".github/workflows/android-debug.yml"))
    assert len(debug_suites) == len(set(debug_suites)) == 32
    new_suites = {"native_motion_transition", "avatar_attire_quality", "native_hostile", "render_budget"}
    assert new_suites <= set(debug_suites)

    source_metadata = json.loads((directory / "source-commit-raw.json").read_bytes())
    local_tree = subprocess.run(["git", "rev-parse", f"{args.source}^{{tree}}"], cwd=args.repo_directory,
                                capture_output=True, text=True, check=True).stdout.strip()
    assert source_metadata["sha"] == args.source and source_metadata["tree"]["sha"] == local_tree
    combined = json.loads((directory / "all-three-ci-receipt.json").read_bytes())
    assert combined["source_commit"] == args.source and combined["source_tree"] == local_tree
    assert combined["all_three_actual_current_runs_success"] is True
    assert combined["binary_artifacts_downloaded"] is False and combined["older_source_results_used"] is False
    binding = json.loads((directory / "source-checkout-tree-binding.json").read_bytes())
    assert binding["all_three_exact_whole_tree_match"] is True and len(binding["bindings"]) == 3
    relevant_warning = re.compile(r"WARNING:.*(?:couldn.t resolve|shader|script|track|rendering|gpu|vulkan|opengl|uniform|material|parse)", re.I)
    results = []
    for key, (workflow_name, _, _) in collector.WORKFLOWS.items():
        raw = (directory / f"{key}-original-job.log").read_bytes()
        parsed = collector.parse_log(raw, key)
        receipt = json.loads((directory / f"{key}-receipt.json").read_bytes())
        assert receipt["source_commit"] == args.source and receipt["actual_current_source_success"] is True
        assert receipt["original_log_sha256"] == hashlib.sha256(raw).hexdigest()
        assert receipt["original_log_bytes"] == len(raw)
        assert receipt["summary_sha256"] == digest(directory / f"{key}-summary.log")
        assert not parsed["diagnostic_lines"]
        warnings = [line for line in collector.normalized_lines(raw) if relevant_warning.search(line)]
        assert not warnings, (key, warnings)
        if key == "gameplay":
            assert [value["suite"] for value in parsed["suites"]] == [labels[suite] for suite in suites]
            assert parsed["godot_suites"] == 53
            assert parsed["godot_checks"] == args.expected_gameplay_checks
            assert parsed["godot_failures"] == 0
            assert parsed["python_test_runs"] == [args.expected_gameplay_python_tests]
            assert next(value for value in parsed["suites"] if value["suite"] == "ANIMATION CRAFT SMOKE")["checks"] == 74
            assert parsed["exported_pck_results"] == [{"suite": "EXPORTED AVATAR SMOKE", "checks": 60, "failures": 0}]
        elif key == "android-debug":
            assert Counter(value["suite"] for value in parsed["suites"]) == Counter(labels[suite] for suite in debug_suites)
            assert parsed["godot_suites"] == 32
            assert len(parsed["apk_signature_verifications"]) == 2 and parsed["aab_verified"] is True
        elif key == "android-runtime":
            assert len(parsed["verified_android_markers"]) == 5
            assert {value["marker"]: value["launch"] for value in parsed["verified_android_markers"]} == collector.EXPECTED_MARKERS
        current_binding = next(value for value in binding["bindings"] if value["workflow"] == workflow_name)
        assert current_binding["source_commit"] == args.source
        assert current_binding["source_tree"] == current_binding["actual_checkout_tree"] == local_tree
        assert current_binding["exact_whole_tree_match"] is True and current_binding["source_is_checkout_or_parent"] is True
        results.append({"workflow": workflow_name, "run_url": receipt["run_url"], "original_log_sha256": hashlib.sha256(raw).hexdigest(),
                        "godot_suites": parsed.get("godot_suites"), "godot_checks": parsed.get("godot_checks"),
                        "python_test_runs": parsed["python_test_runs"], "relevant_engine_warnings": warnings,
                        "intentional_persistence_error_count": len(parsed["intentional_persistence_diagnostics"]),
                        "actual_checkout_commit": parsed["actual_checkout_commit"], "source_tree": local_tree})
    output = {"schema": 1, "observed_at": datetime.now(timezone.utc).isoformat(), "source_commit": args.source,
              "source_tree": local_tree, "actual_exit_code": 0, "all_verifications_passed": True,
              "scope": "Independent log inventory, original hashes, committed suite names, diagnostics, APK/AAB/runtime evidence and whole-tree source binding. No Engine, binary artifacts or physical-phone measurement.",
              "verifier_sha256": digest(Path(__file__)), "collector_sha256": digest(collector_path),
              "expected_gameplay_checks": args.expected_gameplay_checks,
              "expected_gameplay_python_tests": args.expected_gameplay_python_tests,
              "expected_gameplay_suites": labels, "expected_android_debug_suites": debug_suites, "verified_workflows": results}
    (directory / "independent-verification-receipt.json").write_text(json.dumps(output, indent=2) + "\n")
    print(json.dumps({key: value for key, value in output.items() if key not in ("expected_gameplay_suites", "expected_android_debug_suites")}, indent=2))


if __name__ == "__main__":
    main()
