"""Package the signed closed-beta APK, checksum, and test guide reproducibly."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import re
import tempfile
import zipfile

from export_closed_beta_apk import PROJECT_ROOT, read_preset


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    preset = read_preset()
    version = preset["version_name"]
    match = re.fullmatch(r"0\.(\d+)\.0-beta\.1", version)
    if not match:
        raise SystemExit(f"Unexpected closed-beta version name: {version}")
    build_number = f"{int(match.group(1)):03d}"
    apk = PROJECT_ROOT / "build" / f"emberfall-{build_number}-closed-beta.apk"
    guide = PROJECT_ROOT / "docs" / "BETA_TESTING.md"
    checksum = apk.with_suffix(apk.suffix + ".sha256")
    archive = PROJECT_ROOT / "build" / f"emberfall-{version}-test-package.zip"
    archive_checksum = archive.with_suffix(archive.suffix + ".sha256")

    for path in (apk, guide, checksum):
        if not path.is_file():
            raise SystemExit(f"Required beta package file is missing: {path}")
    expected_line = f"{sha256(apk)}  {apk.name}\n"
    if checksum.read_text(encoding="ascii") != expected_line:
        raise SystemExit("APK checksum file does not match the current APK.")

    archive.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(prefix=archive.name, suffix=".tmp", dir=archive.parent, delete=False) as temp:
        temporary_archive = Path(temp.name)
    try:
        with zipfile.ZipFile(temporary_archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
            bundle.write(apk, apk.name)
            bundle.write(checksum, checksum.name)
            bundle.write(guide, "BETA_TESTING.md")
        with zipfile.ZipFile(temporary_archive, "r") as bundle:
            expected_members = {apk.name, checksum.name, "BETA_TESTING.md"}
            if set(bundle.namelist()) != expected_members or bundle.testzip() is not None:
                raise SystemExit("Packaged beta archive failed its member or CRC check.")
        os.replace(temporary_archive, archive)
    finally:
        temporary_archive.unlink(missing_ok=True)

    archive_checksum.write_text(f"{sha256(archive)}  {archive.name}\n", encoding="ascii")
    print(f"Created beta test package: {archive}")
    print(f"SHA-256: {archive_checksum}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
