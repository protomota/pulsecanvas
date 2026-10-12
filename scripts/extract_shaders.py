#!/usr/bin/env python3
"""Recover textual Apple AIR from a supplied Metal library, without changing it."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("metallib", type=Path)
parser.add_argument("output", type=Path)
args = parser.parse_args()
data = args.metallib.read_bytes()
if data[:4] != b"MTLB":
    raise SystemExit("Input is not an MTLB library")
args.output.mkdir(parents=True, exist_ok=True)
records = []
magic = bytes.fromhex("dec0170b")
for index, match in enumerate(re.finditer(re.escape(magic), data)):
    offset = match.start()
    _, version, inner_offset, size, cpu = struct.unpack_from("<5I", data, offset)
    bitcode = data[offset + inner_offset:offset + inner_offset + size]
    if len(bitcode) != size or bitcode[:4] != b"BC\xc0\xde":
        continue
    temporary = args.output / f"module_{index:02}.bc"
    temporary.write_bytes(bitcode)
    ir = args.output / f"module_{index:02}.ll"
    subprocess.run(["xcrun", "air-opt", "-S", str(temporary), "-o", str(ir)], check=True)
    content = ir.read_text()
    names = re.findall(r"^define .*?@([^ (]+)", content, re.MULTILINE)
    if len(names) != 1:
        raise RuntimeError(f"Expected one shader in module {index}, found {names}")
    target = args.output / f"{names[0]}.ll"
    ir.rename(target)
    temporary.unlink()
    records.append({"index": index, "function": names[0], "wrapper_offset": offset,
                    "bitcode_offset": offset + inner_offset, "bitcode_size": size,
                    "bitcode_sha256": hashlib.sha256(bitcode).hexdigest(),
                    "source_file": target.name})
(args.output / "provenance.json").write_text(json.dumps({
    "input_path": str(args.metallib.resolve()),
    "input_sha256": hashlib.sha256(data).hexdigest(),
    "method": "Read MTLB bitcode wrappers; Apple air-opt -S emits textual LLVM AIR",
    "modules": records,
}, indent=2) + "\n")
print(f"Recovered {len(records)} shader source modules in {args.output}")
