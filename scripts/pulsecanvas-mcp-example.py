#!/usr/bin/env python3
"""Exercise a running PulseCanvas Studio host over its bundled STDIO bridge."""

import argparse
import itertools
import json
import subprocess
import sys
import time
import uuid
from typing import Any


class PulseCanvas:
    def __init__(self, executable: str) -> None:
        self.process = subprocess.Popen(
            [executable, "--mcp"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            text=True, encoding="utf-8",
        )
        self.ids = itertools.count(1)
        self.rpc("initialize", {
            "protocolVersion": "2025-11-25",
            "capabilities": {},
            "clientInfo": {"name": "pulsecanvas-examples", "version": "1"},
        })
        self.send({"jsonrpc": "2.0", "method": "notifications/initialized"})

    def send(self, request: dict[str, Any]) -> None:
        assert self.process.stdin is not None
        self.process.stdin.write(json.dumps(request) + "\n")
        self.process.stdin.flush()

    def rpc(self, method: str, params: dict[str, Any]) -> dict[str, Any]:
        request_id = next(self.ids)
        self.send({"jsonrpc": "2.0", "id": request_id, "method": method, "params": params})
        assert self.process.stdout is not None
        line = self.process.stdout.readline()
        if not line:
            raise RuntimeError("PulseCanvas closed its STDIO connection.")
        response = json.loads(line)
        if response.get("id") != request_id or "error" in response:
            raise RuntimeError(str(response.get("error", response)))
        return response["result"]

    def call(self, name: str, **arguments: Any) -> dict[str, Any]:
        result = self.rpc("tools/call", {"name": name, "arguments": arguments})
        if result.get("isError"):
            raise RuntimeError(result["content"][0]["text"])
        return result["structuredContent"]

    def close(self) -> None:
        assert self.process.stdin is not None
        self.process.stdin.close()
        self.process.wait(timeout=10)


def favorites(client: PulseCanvas, visualizer_id: str) -> None:
    kind = "visualizer"
    saved = client.call("list_favorites", kind=kind)
    original = any(item["id"] == visualizer_id for item in saved["favorites"])
    print(json.dumps(saved))
    try:
        print(client.call("set_favorite", kind=kind, id=visualizer_id, favorite=True))
        print(client.call("set_favorite", kind=kind, id=visualizer_id, favorite=False))
    finally:
        client.call("set_favorite", kind=kind, id=visualizer_id, favorite=original)


def playback(client: PulseCanvas, song: str) -> None:
    revision = client.call("get_playback_state")["revision"]
    loaded = client.call("load_song", path=song, expectedRevision=revision)
    print(loaded)
    print(client.call("set_playback_state", state="play"))
    time.sleep(1)
    print(client.call("set_playback_state", state="pause"))
    print(client.call("seek", seconds=loaded["durationSeconds"] / 2))


def video(client: PulseCanvas, song: str, project: str, output: str) -> None:
    revision = client.call("get_playback_state")["revision"]
    result = client.call("create_music_video", songPath=song, projectPath=project, outputPath=output,
                         aspect="wide", resolution=1080, fps=30, barsPerScene=4, fallback="metal",
                         strobeEnabled=False, requestKey=str(uuid.uuid4()), expectedRevision=revision)
    job_id = result["job"]["id"]
    print(f"Saved {result['projectPath']}. Export job {job_id}.", flush=True)
    while True:
        job = client.call("get_export_status", id=job_id)["job"]
        if job["phase"] == "completed":
            print(json.dumps(job, indent=2))
            return
        if job["phase"] in ("failed", "cancelled"):
            raise RuntimeError(str(job))
        print(f"{job['phase']}: {job['framesRendered']}/{job['totalFrames']} frames", flush=True)
        time.sleep(2)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", help="Absolute path to PulseCanvas in the installed Mac app bundle")
    examples = parser.add_subparsers(dest="example", required=True)
    examples.add_parser("favorites").add_argument("visualizer_id")
    examples.add_parser("playback").add_argument("song")
    video_args = examples.add_parser("video")
    video_args.add_argument("song")
    video_args.add_argument("project")
    video_args.add_argument("output")
    args = parser.parse_args()
    client = PulseCanvas(args.executable)
    try:
        status = client.call("get_app_status")
        if not status["enabled"]:
            raise RuntimeError("Open PulseCanvas and enable Settings → Agent access.")
        if args.example == "favorites":
            favorites(client, args.visualizer_id)
        elif args.example == "playback":
            playback(client, args.song)
        else:
            video(client, args.song, args.project, args.output)
    finally:
        client.close()


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as error:
        sys.exit(str(error))
