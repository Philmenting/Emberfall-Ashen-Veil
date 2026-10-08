"""Inspect 64-bit native ELF segments for Android's 16 KB page-size requirement."""
from pathlib import Path
import struct
import zipfile


def verify_elf(data: bytes, label: str) -> int:
    if len(data) < 64 or data[:6] != b"\x7fELF\x02\x01":
        raise ValueError(f"{label}: expected a little-endian ELF64 library")
    offset = struct.unpack_from("<Q", data, 32)[0]
    size, count = struct.unpack_from("<HH", data, 54)
    if size < 56 or offset + size * count > len(data):
        raise ValueError(f"{label}: invalid ELF program headers")
    loads = 0
    for index in range(count):
        position = offset + index * size
        if struct.unpack_from("<I", data, position)[0] != 1:
            continue
        file_offset, address = struct.unpack_from("<QQ", data, position + 8)
        alignment = struct.unpack_from("<Q", data, position + 48)[0]
        if alignment < 16384 or alignment & (alignment - 1) or (address - file_offset) % alignment:
            raise ValueError(f"{label}: LOAD segment is not aligned to 16 KB (p_align={alignment})")
        loads += 1
    if not loads:
        raise ValueError(f"{label}: no loadable native segments")
    return loads


def verify_bundle_native(bundle: Path) -> int:
    with zipfile.ZipFile(bundle) as archive:
        libraries = [name for name in archive.namelist() if name.startswith("base/lib/arm64-v8a/") and name.endswith(".so")]
        if not libraries:
            raise ValueError("Bundle does not contain ARM64 libraries")
        for name in libraries:
            verify_elf(archive.read(name), name)
        return len(libraries)
