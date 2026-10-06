#!/usr/bin/env python3
"""Run the deterministic, offline beta regression suites with isolated saves."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


PROJECT_ROOT = Path(__file__).resolve().parents[1]
GODOT_SUITES = (
    "beta_flow",
    "combat_stances",
    "combat_movement",
    "journey",
    "dungeon",
    "persistence",
    "arcane_tactics",
    "boss_patterns",
    "class_loot",
    "contracts",
    "combined_oaths_phases",
    "main_combined_rules",
    "gear_forecast",
    "gear_goals",
    "regions",
    "onboarding",
    "success_loop",
    "recovery",
    "options",
    "skill_rotation",
    "visuals",
    "world_framing",
    "authored_art",
    "character_equipment",
    "native_equipment_finish",
    "presentation",
    "frame_metrics",
    "room_ground",
    "character_3d",
    "source_avatar",
    "source_avatar_grip",
    "source_avatar_attack",
    "source_avatar_style",
    "class_avatar_quality",
    "guardian_presentation",
    "hostile_quality",
    "dungeon_lighting",
    "combat_audio",
    "native_capture_audio",
    "animation_craft",
    "camp_hud",
    "combat_readability",
    "fellowship_ui",
    "cloud_identity",
    "mana_ward",
)
SUITE_TIMEOUT_SECONDS = {"journey": 600}
SUMMARY = re.compile(
    r"([A-Z][A-Z /]+ SMOKE|SOURCE AVATAR(?: GRIP| ATTACK)?):\s*(\d+)\s+checks,\s*"
    r"(?:\d+\s+actual poses,\s*)?(\d+)\s+failures"
)
ENGINE_ERROR = re.compile(
    r"(?:^|\n)\s*(?:(?:SCRIPT|SHADER)\s+)?ERROR:|Parse Error:", re.IGNORECASE
)


def report_failure(name: str, output: str) -> None:
    print(f"FAIL {name}")
    lines = output.rstrip().splitlines()
    print("\n".join(lines[-100:]) if lines else "(no output)")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--suite",
        action="append",
        choices=GODOT_SUITES,
        help="run only this Godot suite; can be repeated (server checks still run)",
    )
    args = parser.parse_args()
    godot = os.environ.get("GODOT_BIN") or shutil.which("godot")
    node = shutil.which("node")
    if not godot:
        print("Godot 4.7.2 was not found; set GODOT_BIN to its executable.", file=sys.stderr)
        return 2
    if not node:
        print("Node.js is required for the server progression checks.", file=sys.stderr)
        return 2
    version = subprocess.run([godot, "--version"], capture_output=True, text=True, check=False)
    if version.returncode or not version.stdout.strip().startswith("4.7.2"):
        print(f"Godot 4.7.2 is required; found {version.stdout.strip() or 'unknown version'}.", file=sys.stderr)
        return 2

    total_checks = 0
    failures: list[str] = []
    suites = tuple(args.suite) if args.suite else GODOT_SUITES
    with tempfile.TemporaryDirectory(prefix="emberfall-beta-checks-") as temp_name:
        temp_root = Path(temp_name)
        for suite in suites:
            suite_root = temp_root / suite
            env = os.environ.copy()
            env.update(
                {
                    "XDG_DATA_HOME": str(suite_root / "data"),
                    "XDG_CONFIG_HOME": str(suite_root / "config"),
                    "XDG_CACHE_HOME": str(suite_root / "cache"),
                }
            )
            print(f"RUN {suite}_smoke.gd", flush=True)
            timeout_seconds = SUITE_TIMEOUT_SECONDS.get(suite, 300)
            try:
                result = subprocess.run(
                    [
                        godot,
                        "--headless",
                        "--path",
                        str(PROJECT_ROOT),
                        "--fixed-fps",
                        "60",
                        "--script",
                        f"res://tests/{suite}_smoke.gd",
                    ],
                    cwd=PROJECT_ROOT,
                    env=env,
                    capture_output=True,
                    text=True,
                    check=False,
                    timeout=timeout_seconds,
                )
            except subprocess.TimeoutExpired as error:
                output = "\n".join(
                    chunk.decode(errors="replace") if isinstance(chunk, bytes) else (chunk or "")
                    for chunk in (error.stdout, error.stderr)
                )
                failures.append(suite)
                report_failure(f"{suite} (timeout after {timeout_seconds} seconds)", output)
                continue
            output = result.stdout + result.stderr
            matches = list(SUMMARY.finditer(output))
            # Legacy save-corruption suites deliberately exercise ConfigFile errors.
            # The new source-avatar suites must also reject other engine diagnostics.
            source_engine_error = (suite.startswith("source_avatar") or suite in (
                "guardian_presentation", "combat_audio", "class_avatar_quality",
                "hostile_quality", "dungeon_lighting", "native_capture_audio", "native_equipment_finish",
            )) and ENGINE_ERROR.search(output)
            if result.returncode != 0 or not matches or "SCRIPT ERROR:" in output or source_engine_error:
                failures.append(suite)
                report_failure(suite, output)
                continue
            label, raw_checks, raw_failures = matches[-1].groups()
            checks = int(raw_checks)
            suite_failures = int(raw_failures)
            total_checks += checks
            if suite_failures:
                failures.append(suite)
                report_failure(suite, output)
            else:
                print(f"PASS {label}: {checks} checks")

    commands = (
        [node, "--check", str(PROJECT_ROOT / "server/modules/emberfall.js")],
        [node, str(PROJECT_ROOT / "tests/progression_runtime_test.js")],
    )
    for command in commands:
        result = subprocess.run(command, cwd=PROJECT_ROOT, capture_output=True, text=True, check=False, timeout=30)
        output = result.stdout + result.stderr
        if result.returncode:
            name = " ".join(command[1:])
            failures.append(name)
            report_failure(name, output)
        else:
            print(f"PASS {Path(command[-1]).name}")
            if output.strip():
                print(output.strip())

    print(f"BETA CHECKS: {len(suites)} Godot suites, {total_checks} checks, {len(failures)} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
