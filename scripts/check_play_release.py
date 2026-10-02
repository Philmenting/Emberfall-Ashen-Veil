"""Check beta source identity and listing limits; --strict also enforces unresolved publication gates."""
import argparse
import configparser
import json
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[1]


def validate(root: Path, strict: bool = False) -> list[str]:
    problems: list[str] = []
    store = json.loads((root / "docs/play/store.json").read_text())
    presets = configparser.ConfigParser(interpolation=None)
    presets.read(root / "export_presets.cfg")
    play = presets["preset.1.options"]
    for key, value in [("version/name", store["version_name"]), ("version/code", str(store["version_code"])), ("package/unique_name", store["package"]), ("gradle_build/min_sdk", "24"), ("gradle_build/target_sdk", "36"), ("permissions/internet", "false"), ("permissions/vibrate", "true"), ("user_data_backup/allow", "false")]:
        if play.get(key, "").strip('"') != value: problems.append(f"Play preset mismatch: {key}")
    if presets["preset.1"].get("custom_features", "").strip('"'): problems.append("Play build enables custom development features")
    release = (root / "scripts/release_info.gd").read_text()
    if f'const VERSION := "{store["version_name"]}"' not in release or f'const VERSION_CODE := {store["version_code"]}' not in release: problems.append("In-game beta identity differs from Play listing")
    for locale, listing in store["listing"].items():
        for field, limit in [("title", 30), ("short_description", 80), ("full_description", 4000), ("release_notes", 500)]:
            if not isinstance(listing.get(field), str) or not 1 <= len(listing[field]) <= limit: problems.append(f"{locale}: {field} exceeds its {limit}-character limit or is empty")
    for name, dimensions, rgb_only in [("feature-graphic.png", (1024, 500), True), ("icon-512.png", (512, 512), False)]:
        path = root / "docs/play/assets" / name
        if not path.is_file():
            problems.append(f"Store asset missing: {name}")
            continue
        header = path.read_bytes()[:26]
        if len(header)<26 or header[:8]!=b"\x89PNG\r\n\x1a\n" or struct.unpack(">II",header[16:24])!=dimensions or (rgb_only and header[25]!=2):
            problems.append(f"Store asset has incorrect size or PNG format: {name}")
    if strict:
        for field in ["developer_name", "support_email", "privacy_policy_url", "play_app_created", "device_test_report"]:
            if not store.get(field): problems.append(f"Publication gate missing: {field}")
        if store.get("support_email") and not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", store["support_email"]): problems.append("Support email is invalid")
        if store.get("privacy_policy_url") and not store["privacy_policy_url"].startswith("https://"): problems.append("Privacy policy must have a public HTTPS URL")
        report = store.get("device_test_report")
        if report and (not isinstance(report,str) or not (root / report).resolve().is_relative_to(root) or not (root / report).is_file()): problems.append("Physical device test report is missing")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    problems = validate(ROOT, args.strict)
    for problem in problems: print(f"BLOCKED: {problem}")
    if problems: return 2
    print("PLAY SOURCE / LISTING VERIFIED" + ("; declared publication gates present (Play Console review still required)" if args.strict else "; publication gates are checked separately with --strict"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
