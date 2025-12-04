#!/usr/bin/env python

import hashlib
from base64 import urlsafe_b64encode
import sys
from pathlib import Path

if len(sys.argv) != 4:
    raise ValueError("no name/version/tag")
name, version, tag = sys.argv[1:]

bdist_dir = Path(".")
path = bdist_dir / f"{name}-{version}.dist-info" / "WHEEL"
with path.open("w") as wheel:
    wheel.write("Wheel-Version: 1.0\n")
    wheel.write("Generator: custom\n")
    wheel.write("Root-Is-Purelib: false\n")
    wheel.write(f"Tag: {tag}\n")

path = bdist_dir / f"{name}-{version}.dist-info" / "RECORD"
with path.open("w") as record:
    for path in bdist_dir.rglob("*"):
        relative_path = path.relative_to(bdist_dir)
        if path.is_file():
            if path.name == "RECORD":
                hash_ = ""
                size = ""
            else:
                data = path.open("rb").read()
                digest = hashlib.sha256(data).digest()
                sha256 = urlsafe_b64encode(digest).rstrip(b"=").decode("ascii")
                hash_ = f"sha256={sha256}"
                size = f"{len(data)}"
            record_path_ = relative_path.as_posix()
            record.write(f"{record_path_},{hash_},{size}\n")
