#!/usr/bin/env python3
"""Verify the exact Suno takes and prepare AAC copies plus an R2-ready catalog.

Example:
  python3 scripts/prepare-radio-library.py --handoff /path/to/HANDOFF.md --output build/radio
Original audio is read only. No network requests or uploads are made.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import unicodedata


def probe(path):
    return json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", str(path)
    ]))


def prepare(handoff, output, downloads):
    text = handoff.read_text()
    entries = re.split(r"^## \d+\. ", text, flags=re.M)[1:]
    if not entries:
        raise ValueError("No numbered song entries in handoff")
    tracks = []
    audio_dir = output / "audio"
    audio_dir.mkdir(parents=True, exist_ok=True)
    for entry in entries:
        title = entry.splitlines()[0].strip()
        song_id = re.search(r"\*\*Suno song ID:\*\* `([a-f0-9-]+)`", entry)[1]
        genre = re.search(r"\*\*Genre:\*\* (.+)", entry)[1].strip()
        name = unicodedata.normalize("NFC", title + ".m4a")
        matches = [p for p in downloads.glob("*.m4a") if unicodedata.normalize("NFC", p.name) == name]
        if len(matches) != 1:
            raise ValueError(f"Expected exactly one original for {title}")
        source = matches[0]
        original = probe(source)
        comment = original["format"].get("tags", {}).get("comment", "")
        if f"id={song_id}" not in comment:
            raise ValueError(f"Suno take ID does not match handoff: {title}")
        temporary = audio_dir / (song_id + ".partial.m4a")
        try:
            subprocess.run([
                "ffmpeg", "-nostdin", "-v", "error", "-y", "-i", str(source),
                "-map", "0:a:0", "-map_metadata", "-1", "-c:a", "aac", "-b:a", "256k",
                "-ar", "48000", "-ac", "2", "-movflags", "+faststart",
                "-metadata", "title=" + title, "-metadata", "genre=" + genre, str(temporary)
            ], check=True)
            converted = probe(temporary)
            if len(converted["streams"]) != 1 or converted["streams"][0]["codec_name"] != "aac":
                raise ValueError(f"Expected one AAC audio stream: {title}")
            duration = float(converted["format"]["duration"])
            if abs(duration - float(original["format"]["duration"])) > 0.1:
                raise ValueError(f"Converted duration differs from original: {title}")
            data = temporary.read_bytes()
            digest = hashlib.sha256(data).hexdigest()
            filename = song_id + "-" + digest[:16] + ".m4a"
            temporary.replace(audio_dir / filename)
            tracks.append(dict(id=song_id, title=title, genre=genre, duration=duration,
                               audio="audio/" + filename, sha256=digest, byteCount=len(data)))
            print(f"Prepared {title}: {duration:.2f}s, {len(data):,} bytes", flush=True)
        finally:
            temporary.unlink(missing_ok=True)
    catalog = dict(version=1, title="PulseCanvas Radio", tracks=tracks)
    catalog_path = output / "catalog.json"
    pending = output / "catalog.partial.json"
    pending.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
    pending.replace(catalog_path)
    subprocess.run(["python3", str(Path(__file__).with_name("build-radio-stations.py")),
                    "--catalog", str(catalog_path), "--output", str(output)], check=True)
    print(f"Ready: {len(tracks)} tracks, {sum(t['duration'] for t in tracks) / 60:.1f} minutes")
    print(catalog_path.resolve())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--handoff", required=True, type=Path)
    parser.add_argument("--output", default=Path("build/radio"), type=Path)
    parser.add_argument("--downloads", default=Path.home() / "Downloads", type=Path)
    args = parser.parse_args()
    prepare(args.handoff, args.output, args.downloads)
