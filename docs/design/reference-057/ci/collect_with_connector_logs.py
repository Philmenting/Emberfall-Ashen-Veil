#!/usr/bin/env python3
"""Read-only metadata collection; completed connector logs are explicit inputs.

The original strict parser is unchanged. Connector logs are decoded UTF-8 text
re-encoded without edits, with BOM/newlines and a transport/hash receipt. This
does not claim independently established HTTP byte equivalence. No binary
artifacts, Engine, workflow dispatch or Git/source writes.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--directory", required=True, type=Path)
    parser.add_argument("--repo", default="Philmenting/Emberfall-Ashen-Veil")
    args = parser.parse_args()
    assert re.fullmatch(r"[a-f0-9]{40}", args.source)
    module_path = Path(__file__).with_name("collect_ci_receipts.py")
    spec = importlib.util.spec_from_file_location("strict_ci_parser", module_path)
    assert spec and spec.loader
    collector = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(collector)
    directory = args.directory
    directory.mkdir(parents=True, exist_ok=True)
    source = json.loads(collector.api(args.repo, f"git/commits/{args.source}", directory / "source-commit-raw.json"))
    assert source["sha"] == args.source
    inventory = collector.fetch_pages(args.repo, f"actions/runs?head_sha={args.source}&per_page=100", directory / "observed-runs.json")
    collector.write_json(directory / ("runs-observed-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".json"), inventory)
    ready = True
    failure = False
    status = []
    completed = []
    for key, (name, filename, job_name) in collector.WORKFLOWS.items():
        eligible = [run for run in inventory["workflow_runs"] if run["head_sha"] == args.source
                    and run["name"] == name and run["path"].split("/")[-1] == filename]
        if not eligible:
            ready = False
            status.append({"workflow": name, "status": "not yet observed for exact source"})
            continue
        chosen = max(eligible, key=lambda value: (value["created_at"], value["id"]))
        metadata = json.loads(collector.api(args.repo, f"actions/runs/{chosen['id']}", directory / f"{key}-run.json"))
        attempt = metadata.get("run_attempt", 1)
        jobs = collector.fetch_pages(args.repo, f"actions/runs/{chosen['id']}/attempts/{attempt}/jobs?per_page=100", directory / f"{key}-jobs.json")
        collector.api(args.repo, f"actions/runs/{chosen['id']}/artifacts?per_page=100", directory / f"{key}-artifacts.json")
        matches = [job for job in jobs["jobs"] if job["name"] == job_name]
        if not matches and metadata["status"] != "completed":
            ready = False
            status.append({"workflow": name, "run": chosen["id"], "attempt": attempt, "status": metadata["status"],
                           "conclusion": metadata["conclusion"], "job_status": "not yet observed"})
            continue
        assert len(matches) == 1
        job = matches[0]
        row = {"workflow": name, "run": chosen["id"], "attempt": attempt, "status": metadata["status"],
               "conclusion": metadata["conclusion"], "job_id": job["id"], "job_status": job["status"],
               "job_conclusion": job["conclusion"]}
        status.append(row)
        if metadata["status"] != "completed" or job["status"] != "completed":
            ready = False
            continue
        if metadata["conclusion"] != "success" or job["conclusion"] != "success":
            failure = True
        completed.append((key, job))
    receipt = {"observed_at": collector.now(), "source_commit": args.source, "workflows": status,
               "binary_artifacts_downloaded": False, "original_log_transport": "GitHub connector decoded UTF-8 with explicit transport receipts"}
    collector.write_json(directory / "collection-status.json", receipt)
    collector.write_json(directory / ("collection-status-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".json"), receipt)
    print(json.dumps(status, indent=2), flush=True)
    if failure:
        return 1
    if not ready:
        return 2
    logs_ready = True
    for key, job in completed:
        path = directory / f"{key}-original-job.log"
        transport_path = directory / f"{key}-log-transport.json"
        if not path.is_file() or not transport_path.is_file():
            print(f"Completed original log still required: {key}, actual job {job['id']}", flush=True)
            logs_ready = False
            continue
        raw = path.read_bytes()
        transport = json.loads(transport_path.read_bytes())
        assert transport["source_commit"] == args.source and transport["job_id"] == job["id"]
        assert transport["log_sha256"] == hashlib.sha256(raw).hexdigest() and transport["log_bytes"] == len(raw)
        checkout = collector.parse_log(raw, key)["actual_checkout_commit"]
        collector.api(args.repo, f"git/commits/{checkout}", directory / f"{key}-checkout-commit-raw.json")
    if not logs_ready:
        return 2
    return collector.summarize(args)


if __name__ == "__main__":
    sys.exit(main())
