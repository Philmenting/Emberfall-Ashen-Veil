"""Verify an Android App Bundle's structure, signing, identity, SDK range, and permissions."""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys
from android_native_check import verify_bundle_native


def command_output(command: list[str]) -> str:
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode:
        details = (result.stdout + "\n" + result.stderr).strip()
        raise RuntimeError(f"Command failed ({result.returncode}): {' '.join(command)}\n{details[-5000:]}")
    return result.stdout.strip()


def manifest_value(java: str, bundletool: Path, bundle: Path, xpath: str) -> str:
    value = command_output(
        [
            java,
            "-jar",
            str(bundletool),
            "dump",
            "manifest",
            f"--bundle={bundle}",
            "--module=base",
            f"--xpath={xpath}",
        ]
    )
    return value.strip().strip('"')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--bundletool", type=Path, required=True)
    parser.add_argument("--java", default="java")
    parser.add_argument("--jarsigner", default="jarsigner")
    parser.add_argument("--package", required=True)
    parser.add_argument("--version-code", type=int, required=True)
    parser.add_argument("--version-name", required=True)
    parser.add_argument("--min-sdk", type=int, required=True)
    parser.add_argument("--target-sdk", type=int, required=True)
    args = parser.parse_args()

    if not args.bundle.is_file():
        parser.error(f"App Bundle does not exist: {args.bundle}")
    if not args.bundletool.is_file():
        parser.error(f"Bundletool does not exist: {args.bundletool}")

    try:
        command_output([args.java, "-jar", str(args.bundletool), "validate", f"--bundle={args.bundle}"])
        signature = command_output([args.jarsigner, "-verify", str(args.bundle)])
        if "jar verified." not in signature.lower():
            raise RuntimeError("jarsigner did not report a valid signed bundle")

        actual = {
            "package": manifest_value(args.java, args.bundletool, args.bundle, "/manifest/@package"),
            "version code": manifest_value(args.java, args.bundletool, args.bundle, "/manifest/@android:versionCode"),
            "version name": manifest_value(args.java, args.bundletool, args.bundle, "/manifest/@android:versionName"),
            "min SDK": manifest_value(args.java, args.bundletool, args.bundle, "/manifest/uses-sdk/@android:minSdkVersion"),
            "target SDK": manifest_value(args.java, args.bundletool, args.bundle, "/manifest/uses-sdk/@android:targetSdkVersion"),
        }
        expected = {
            "package": args.package,
            "version code": str(args.version_code),
            "version name": args.version_name,
            "min SDK": str(args.min_sdk),
            "target SDK": str(args.target_sdk),
        }
        for field, expected_value in expected.items():
            if actual[field] != expected_value:
                raise RuntimeError(f"Unexpected {field}: expected {expected_value!r}, found {actual[field]!r}")

        permission_names: set[str] = set()
        for element in ("uses-permission", "uses-permission-sdk-23", "uses-permission-sdk-m"):
            permissions = manifest_value(
                args.java,
                args.bundletool,
                args.bundle,
                f"/manifest/{element}/@android:name",
            )
            permission_names.update(
                line.strip().lstrip("- ").strip('"')
                for line in permissions.splitlines()
                if line.strip()
            )
        if "android.permission.INTERNET" in permission_names:
            raise RuntimeError("The Google Play bundle unexpectedly requests android.permission.INTERNET")
        if permission_names != {"android.permission.VIBRATE"}:
            raise RuntimeError(f"Unexpected offline beta permissions: {sorted(permission_names)}; expected VIBRATE only")
        for xpath, expected_value, label in [
            ("/manifest/application/@android:debuggable", "false", "release debuggability"),
            ("/manifest/application/@android:allowBackup", "false", "automatic data backup"),
            ("/manifest/application/activity/@android:screenOrientation", "0", "landscape orientation"),
        ]:
            value = manifest_value(args.java, args.bundletool, args.bundle, xpath)
            if label == "release debuggability" and not value:
                continue  # Android defaults an omitted debuggable attribute to false.
            if value != expected_value:
                raise RuntimeError(f"Unexpected {label}: {value!r}")
        library_count = verify_bundle_native(args.bundle)

    except (OSError, RuntimeError, ValueError) as error:
        print(f"ANDROID AAB VERIFICATION FAILED: {error}", file=sys.stderr)
        return 1

    print("ANDROID AAB VERIFIED")
    print(f"Package: {actual['package']}")
    print(f"Version: {actual['version name']} ({actual['version code']})")
    print(f"SDK range: {actual['min SDK']}–{actual['target SDK']}")
    print("Internet permission: absent")
    print("Bundle structure and JAR signature: valid")
    print(f"ARM64 native libraries: {library_count}, all ELF LOAD segments support 16 KB pages")
    print("Release manifest: landscape, not debuggable, OS backup disabled, VIBRATE only (optional haptics)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
