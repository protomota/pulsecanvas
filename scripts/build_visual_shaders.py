#!/usr/bin/env python3
"""Compile the project shader library from textual AIR source modules."""
import argparse
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
parser.add_argument("output", type=Path)
args = parser.parse_args()
args.output.parent.mkdir(parents=True, exist_ok=True)
build = args.output.parent / "air"
build.mkdir(exist_ok=True)
inputs = sorted(args.source.glob("*.ll"))
if not inputs:
    raise SystemExit("No textual LLVM AIR source modules found")
objects = []
for source in inputs:
    obj = build / (source.stem + ".air")
    subprocess.run(["xcrun", "metal", "-c", "-x", "ir", "-Wno-override-module", "-target",
                    "air64_v25-apple-macosx13.0.0", str(source), "-o", str(obj)], check=True)
    objects.append(str(obj))
subprocess.run(["xcrun", "metallib", *objects, "-o", str(args.output)], check=True)
print(f"Built {len(inputs)} visual shader functions from source: {args.output}")
