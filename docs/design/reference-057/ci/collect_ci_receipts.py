#!/usr/bin/env python3
"""Read-only Actions collector and strict offline evidence parser.

Only GitHub metadata, commit objects and original completed job logs are read.
No artifacts, source edits, Engine processes, ref mutations or CI dispatches.
Exit 2 means the exact requested source still has unfinished/missing runs.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time

WORKFLOWS = {
    "gameplay": ("Gameplay Quality", "gameplay-quality.yml", "regression"),
    "android-debug": ("Android Debug APK", "android-debug.yml", "android-debug"),
    "android-runtime": ("Android Beta Runtime", "android-beta-runtime.yml", "offline-runtime"),
}
EXPECTED_MARKERS = {
    "ANDROID_BETA_PASS exact AFK ledger": 1,
    "ANDROID_BETA_PASS restart does not repeat": 2,
    "ANDROID_SUCCESS_PASS first descent, class relic and combined oath UI": 1,
    "ANDROID_SUCCESS_PASS restart preserves combined oaths": 2,
    "ANDROID_ART_PASS all four regions rendered": 1,
}
TIME_PREFIX = re.compile(r"^\ufeff?\d{4}-\d\d-\d\dT[\d:.]+Z ?")
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
SHA = re.compile(r"[a-f0-9]{40}\Z")
DIAGNOSTIC = re.compile(r"SCRIPT ERROR:|SHADER ERROR:|Shader compilation failed|Parse Error:|Compile Error:|(?:^|\s)ERROR:|Process completed with exit code [1-9]")
SCOPES = "Exact-source hosted CI, source/resource packaging, CI-only APK/AAB signature and manifest checks, and Android16 x86_64 emulator correctness. ARM64 probe packaging is separate from execution. No physical-phone frame-time, thermals, battery, touch or beta-readiness measurement."


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def api(repo: str, endpoint: str, destination: Path) -> bytes:
    # Positional arguments only: no interpolated shell command or auth output.
    command = ["gh", "api", f"repos/{repo}/{endpoint}"]
    for attempt in range(3):
        result = subprocess.run(command, capture_output=True, timeout=90)
        if result.returncode == 0:
            destination.write_bytes(result.stdout)
            return result.stdout
        if attempt == 2:
            raise RuntimeError(f"Read-only API failed for {endpoint}: {result.stderr.decode(errors='replace')}")
        time.sleep(10)
    raise AssertionError("unreachable")


def fetch_pages(repo: str, endpoint: str, destination: Path) -> dict:
    pages = []
    field = "jobs" if "jobs?" in endpoint else "workflow_runs"
    for page in range(1, 21):
        raw = api(repo, f"{endpoint}&page={page}", destination.with_name(destination.stem + f"-page-{page}.json"))
        payload = json.loads(raw)
        pages.append(payload)
        if len(payload[field]) < 100:
            break
    else:
        raise RuntimeError("API pagination exceeded collector limit")
    if len(pages) == 1:
        destination.write_bytes(raw)  # Keep the one actual API body intact.
        return pages[0]
    payload = {"total_count": sum(len(p[field]) for p in pages), field: [v for p in pages for v in p[field]], "collector_merged_pages": len(pages)}
    write_json(destination, payload)
    return payload


def normalized_lines(raw: bytes) -> list[str]:
    # Normalization is used only for derived parsing, never original log writes.
    return [ANSI.sub("", TIME_PREFIX.sub("", line)) for line in raw.decode("utf-8-sig").splitlines()]


def parse_log(raw: bytes, key: str) -> dict:
    lines = normalized_lines(raw)
    original_lines = raw.decode("utf-8-sig").splitlines()
    checkout = []
    for index, line in enumerate(lines[:-1]):
        if re.search(r"(?:^|/)git log -1 --format=%H$", line):
            if SHA.fullmatch(lines[index + 1].strip()):
                checkout.append(lines[index + 1].strip())
    if len(checkout) != 1:
        raise ValueError(f"{key}: actual checkout commit must occur exactly once after git log")
    python_results = [int(m[1]) for line in lines if (m := re.fullmatch(r"Ran (\d+) tests in .+", line))]
    suites = []
    integration = []
    exports = []
    beta = []
    markers = []
    signatures = []
    current_signature = None
    packages = []
    diagnostics = []
    intentional = []
    selected = []
    for index, line in enumerate(lines):
        if key == "gameplay":
            match = re.fullmatch(r"PASS ([A-Z0-9][A-Z0-9 /_-]+): (\d+) checks", line)
            if match:
                suites.append({"suite": match[1], "checks": int(match[2]), "failures": 0})
        else:
            match = re.fullmatch(r"([A-Z0-9][A-Z0-9 /_-]+): (\d+) checks, (?:\d+ actual poses, )?(\d+) failures", line)
            if match:
                value = {"suite": match[1], "checks": int(match[2]), "failures": int(match[3])}
                if match[1] == "EXPORTED AVATAR SMOKE":
                    exports.append(value)
                elif match[1] == "CLOUD TRANSFER E2E":
                    integration.append(value)
                else:
                    suites.append(value)
        if line.startswith("EXPORTED AVATAR SMOKE:") and key == "gameplay":
            match = re.fullmatch(r"EXPORTED AVATAR SMOKE: (\d+) checks, (\d+) failures", line)
            if not match:
                raise ValueError("Unexpected exported PCK summary")
            exports.append({"suite": "EXPORTED AVATAR SMOKE", "checks": int(match[1]), "failures": int(match[2])})
        if match := re.fullmatch(r"BETA CHECKS: (\d+) Godot suites, (\d+) checks, (\d+) failures", line):
            beta.append(dict(zip(("godot_suites", "godot_checks", "godot_failures"), map(int, match.groups()))))
        if match := re.fullmatch(r"ANDROID_RUNTIME_MARKER verified launch=(\d+) elapsed_seconds=([\d.]+) pids=(\[[^\]]*\]) marker=(.+)", line):
            markers.append({"launch": int(match[1]), "elapsed_seconds": float(match[2]), "pids": json.loads(match[3]), "marker": match[4], "original_line": original_lines[index]})
        if line == "Verifies":
            current_signature = {"verification_order": len(signatures) + 1, "schemes": {}, "original_lines": [line]}
            signatures.append(current_signature)
        elif current_signature and (match := re.fullmatch(r"Verified using (v[\d.]+) scheme \(.+\): (true|false)", line)):
            current_signature["schemes"][match[1]] = match[2] == "true"
            current_signature["original_lines"].append(line)
        if match := re.fullmatch(r"Exporting (res://tests/[^ ]+\.tscn) \(([^)]+)\) to (.+\.apk)", line):
            packages.append({"fixture": match[1], "abi": match[2], "path": match[3]})
        if DIAGNOSTIC.search(line):
            entry = {"line": line, "line_number": index + 1}
            # Narrow known deliberate corruption oracle: exact message and its
            # actual Persistence backtrace, with successful summary required.
            if line == "ERROR: ConfigFile parse error at <string>:0: Unexpected EOF while parsing simple tag." and any("res://tests/persistence_smoke.gd:" in following for following in lines[index + 1:index + 8]):
                intentional.append(entry)
            else:
                diagnostics.append(entry)
        if re.match(r"(?:PASS [A-Z0-9 /_-]+: \d+ checks|[A-Z0-9 /_-]+: \d+ checks|BETA CHECKS:|EXPORTED AVATAR SMOKE:|Ran \d+ tests|ANDROID_RUNTIME_MARKER|ANDROID AAB VERIFIED|Bundle structure and JAR signature:|ARM64 native libraries:|Verified using|Verifies$|Exporting res://tests/|package: name=|PROGRESSION RUNTIME:|Package:|Version:|SDK range:|Internet permission:|Release manifest:)", line) or DIAGNOSTIC.search(line):
            selected.append(original_lines[index])
    if intentional:
        persisted = [s for s in suites if s["suite"] == "PERSISTENCE SMOKE"]
        if len(intentional) != 2 or len(persisted) != 1 or persisted[0]["failures"]:
            raise ValueError(f"{key}: unexpected persistence-error inventory/context")
    if key == "gameplay":
        if len(beta) != 1:
            raise ValueError("Gameplay lacks exactly one actual beta summary")
        expected = {"godot_suites": len(suites), "godot_checks": sum(s["checks"] for s in suites), "godot_failures": sum(s["failures"] for s in suites)}
        if beta[0] != expected:
            raise ValueError(f"Gameplay summary does not match independent suite inventory: {beta} versus {expected}")
    result = {"actual_checkout_commit": checkout[0], "python_test_runs": python_results, "suites": suites,
              "integration_summaries": integration, "exported_pck_results": exports,
              "verified_android_markers": markers, "apk_signature_verifications": signatures,
              "isolated_qa_package_builds": packages,
              "aab_verified": "ANDROID AAB VERIFIED" in lines and "Bundle structure and JAR signature: valid" in lines,
              "bundle_identity_lines": [line for line in lines if re.match(r"^(?:Package:|Version:|SDK range:|Internet permission:|Release manifest:|ARM64 native libraries:)", line)],
              "server_progression_passed": any(line.startswith("PROGRESSION RUNTIME:") and line.endswith("passed.") for line in lines),
              "diagnostic_lines": diagnostics, "intentional_persistence_diagnostics": intentional,
              "original_log_sha256": sha256(raw), "original_log_bytes": len(raw),
              "summary": "\n".join(selected) + "\n"}
    if suites:
        result.update(godot_suites=len(suites), godot_checks=sum(s["checks"] for s in suites), godot_failures=sum(s["failures"] for s in suites))
    return result


def collect(args: argparse.Namespace) -> int:
    directory = args.directory
    directory.mkdir(parents=True, exist_ok=True)
    source = json.loads(api(args.repo, f"git/commits/{args.source}", directory / "source-commit-raw.json"))
    if source["sha"] != args.source:
        raise ValueError("Remote source commit identity mismatch")
    inventory = fetch_pages(args.repo, f"actions/runs?head_sha={args.source}&per_page=100", directory / "observed-runs.json")
    write_json(directory / ("runs-observed-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".json"), inventory)
    ready = True
    status = []
    for key, (name, filename, job_name) in WORKFLOWS.items():
        eligible = [run for run in inventory["workflow_runs"] if run["head_sha"] == args.source and run["name"] == name and run["path"].split("/")[-1] == filename]
        if not eligible:
            ready = False
            status.append({"workflow": name, "status": "not yet observed for exact source"})
            continue
        chosen = max(eligible, key=lambda run: (run["created_at"], run["id"]))
        metadata = json.loads(api(args.repo, f"actions/runs/{chosen['id']}", directory / f"{key}-run.json"))
        attempt = metadata.get("run_attempt", 1)
        jobs = fetch_pages(args.repo, f"actions/runs/{chosen['id']}/attempts/{attempt}/jobs?per_page=100", directory / f"{key}-jobs.json")
        api(args.repo, f"actions/runs/{chosen['id']}/artifacts?per_page=100", directory / f"{key}-artifacts.json")
        matches = [job for job in jobs["jobs"] if job["name"] == job_name]
        if not matches and metadata["status"] != "completed":
            ready = False
            status.append({"workflow": name, "run": chosen["id"], "attempt": attempt, "status": metadata["status"], "conclusion": metadata["conclusion"], "job_status": "not yet observed"})
            continue
        if len(matches) != 1:
            raise ValueError(f"{key}: unexpected main job inventory")
        job = matches[0]
        status.append({"workflow": name, "run": chosen["id"], "attempt": attempt, "status": metadata["status"], "conclusion": metadata["conclusion"], "job_status": job["status"], "job_conclusion": job["conclusion"]})
        if metadata["status"] != "completed" or job["status"] != "completed":
            ready = False
            continue
        log = api(args.repo, f"actions/jobs/{job['id']}/logs", directory / f"{key}-original-job.log")
        checkout = parse_log(log, key)["actual_checkout_commit"]
        api(args.repo, f"git/commits/{checkout}", directory / f"{key}-checkout-commit-raw.json")
    write_json(directory / "collection-status.json", {"observed_at": now(), "source_commit": args.source, "workflows": status, "binary_artifacts_downloaded": False})
    print(json.dumps(status, indent=2), flush=True)
    return summarize(args) if ready else 2


def summarize(args: argparse.Namespace) -> int:
    directory = args.directory
    source_raw = (directory / "source-commit-raw.json").read_bytes()
    source = json.loads(source_raw)
    if source["sha"] != args.source:
        raise ValueError("Source metadata does not match requested SHA")
    receipts = []
    bindings = []
    all_success = True
    for key, (name, _, job_name) in WORKFLOWS.items():
        metadata = json.loads((directory / f"{key}-run.json").read_bytes())
        jobs = json.loads((directory / f"{key}-jobs.json").read_bytes())["jobs"]
        if metadata["name"] != name or metadata["head_sha"] != args.source or metadata["status"] != "completed":
            raise ValueError(f"{key}: workflow is not completed for exact source")
        matches = [job for job in jobs if job["name"] == job_name]
        if len(matches) != 1 or matches[0]["status"] != "completed":
            raise ValueError(f"{key}: expected completed original job")
        job = matches[0]
        parsed = parse_log((directory / f"{key}-original-job.log").read_bytes(), key)
        checkout_raw = (directory / f"{key}-checkout-commit-raw.json").read_bytes()
        checkout = json.loads(checkout_raw)
        parents = [parent["sha"] for parent in checkout["parents"]]
        if checkout["sha"] != parsed["actual_checkout_commit"]:
            raise ValueError(f"{key}: checkout object differs from original log")
        whole_tree = source["tree"]["sha"] == checkout["tree"]["sha"]
        source_parent = checkout["sha"] == args.source or args.source in parents
        bindings.append({"workflow": name, "source_commit": args.source, "source_tree": source["tree"]["sha"], "actual_checkout_commit": checkout["sha"], "actual_checkout_tree": checkout["tree"]["sha"], "checkout_parents": parents, "source_is_checkout_or_parent": source_parent, "exact_whole_tree_match": whole_tree, "raw_source_commit_metadata_sha256": sha256(source_raw), "raw_checkout_metadata_sha256": sha256(checkout_raw)})
        run_ok = metadata["conclusion"] == "success" and job["conclusion"] == "success" and whole_tree and source_parent and bool(parsed["python_test_runs"]) and not parsed["diagnostic_lines"] and not parsed.get("godot_failures", 0) and all(not value["failures"] for value in parsed["integration_summaries"] + parsed["exported_pck_results"])
        if key == "gameplay":
            run_ok = run_ok and len(parsed["exported_pck_results"]) == 1 and bool(parsed["python_test_runs"]) and parsed["server_progression_passed"]
        if key == "android-debug":
            run_ok = run_ok and len(parsed["apk_signature_verifications"]) == 2 and all(value["schemes"].get("v2") and value["schemes"].get("v3") for value in parsed["apk_signature_verifications"]) and parsed["aab_verified"] and len(parsed["integration_summaries"]) == 1 and parsed["server_progression_passed"]
        if key == "android-runtime":
            marker_map = {marker["marker"]: marker["launch"] for marker in parsed["verified_android_markers"]}
            runtime_env = f"EMBERFALL_SOURCE_COMMIT: {args.source}" in (directory / f"{key}-original-job.log").read_text(encoding="utf-8-sig")
            packages = {(p["fixture"], p["abi"]) for p in parsed["isolated_qa_package_builds"]}
            expected_packages = {("res://tests/android_beta_flow.tscn", "x86_64"), ("res://tests/android_success_flow.tscn", "x86_64"), ("res://tests/android_art_flow.tscn", "x86_64"), ("res://tests/android_device_probe.tscn", "arm64-v8a")}
            run_ok = run_ok and marker_map == EXPECTED_MARKERS and len(parsed["verified_android_markers"]) == 5 and all(marker["pids"] and marker["elapsed_seconds"] > 0 for marker in parsed["verified_android_markers"]) and runtime_env and packages == expected_packages and len(parsed["isolated_qa_package_builds"]) == 4
        summary = parsed.pop("summary")
        summary_path = directory / f"{key}-summary.log"
        summary_path.write_text(summary, encoding="utf-8")
        receipt = {"schema": 2, "observed_at": now(), "source_commit": args.source, "workflow": name, "workflow_run": metadata["id"], "run_attempt": metadata.get("run_attempt", 1), "job_id": job["id"], "run_url": metadata["html_url"], "job_url": job.get("html_url"), "run_conclusion": metadata["conclusion"], "job_conclusion": job["conclusion"], "actual_current_source_success": bool(run_ok), "summary_sha256": sha256(summary_path.read_bytes()), "scope": SCOPES, **parsed}
        write_json(directory / f"{key}-receipt.json", receipt)
        receipts.append(receipt)
        all_success = all_success and bool(run_ok)
    write_json(directory / "source-checkout-tree-binding.json", {"schema": 2, "observed_at": now(), "bindings": bindings, "all_three_exact_whole_tree_match": all(b["exact_whole_tree_match"] for b in bindings)})
    write_json(directory / "all-three-ci-receipt.json", {"schema": 2, "source_commit": args.source, "source_tree": source["tree"]["sha"], "all_three_actual_current_runs_success": all_success, "binary_artifacts_downloaded": False, "older_source_results_used": False, "checks": receipts, "scope": SCOPES})
    print(json.dumps([{key: r.get(key) for key in ("workflow", "workflow_run", "job_id", "run_conclusion", "job_conclusion", "actual_current_source_success", "godot_suites", "godot_checks", "python_test_runs")} for r in receipts], indent=2))
    return 0 if all_success else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("collect", "summarize"))
    parser.add_argument("--source", required=True)
    parser.add_argument("--directory", required=True, type=Path)
    parser.add_argument("--repo", default="Philmenting/Emberfall-Ashen-Veil")
    args = parser.parse_args()
    if not SHA.fullmatch(args.source):
        parser.error("--source must be the exact lowercase 40-character commit SHA")
    return collect(args) if args.mode == "collect" else summarize(args)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        print(f"CI evidence rejected: {error}", file=sys.stderr)
        sys.exit(1)
