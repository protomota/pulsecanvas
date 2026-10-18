#!/usr/bin/env python3
"""Upload a prepared radio library via the R2 S3 API. Requires no Python packages.

Credentials are read only from environment variables, never written into the catalog:
R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET.
Use a token scoped to Object Read & Write on the radio bucket.
Uploads immutable audio first, then catalogs, and publishes stations.json last.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
from urllib.parse import quote
from urllib.request import Request, urlopen


def upload(directory, prefix):
    names = ["R2_ACCOUNT_ID", "R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY", "R2_BUCKET"]
    missing = [key for key in names if not os.environ.get(key)]
    if missing:
        raise SystemExit("Missing environment variables: " + ", ".join(missing))
    account, access, secret, bucket = (os.environ[key] for key in names)
    if not re.fullmatch(r"[a-fA-F0-9]{32}", account) or not re.fullmatch(r"[a-z0-9][a-z0-9.-]+", bucket):
        raise SystemExit("Invalid R2 account ID or bucket name")
    host = account + ".r2.cloudflarestorage.com"
    catalog = json.loads((directory / "catalog.json").read_text())
    files = []
    for track in catalog["tracks"]:
        path = (directory / track["audio"]).resolve()
        if not path.is_relative_to(directory.resolve()):
            raise SystemExit("Audio path escapes library")
        data = path.read_bytes()
        if len(data) != track["byteCount"] or hashlib.sha256(data).hexdigest() != track["sha256"]:
            raise SystemExit("Audio integrity mismatch: " + track["title"])
        files.append((track["audio"], data, "audio/mp4", "public, max-age=31536000, immutable"))
    if (directory / "stations.json").exists():
        station_index = json.loads((directory / "stations.json").read_text())
        for name in dict.fromkeys(station["catalog"] for station in station_index["stations"]):
            if name == "catalog.json":
                continue
            if not re.fullmatch(r"station-[a-z0-9-]+\.json", name):
                raise SystemExit("Invalid station catalog path")
            path = directory / name
            files.append((name, path.read_bytes(), "application/json; charset=utf-8", "public, max-age=60"))
    files.append(("catalog.json", (directory / "catalog.json").read_bytes(), "application/json; charset=utf-8", "public, max-age=60"))
    if (directory / "stations.json").exists():
        files.append(("stations.json", (directory / "stations.json").read_bytes(), "application/json; charset=utf-8", "public, max-age=60"))
    for name, data, content_type, cache in files:
        stamp = datetime.now(timezone.utc)
        date, moment = stamp.strftime("%Y%m%d"), stamp.strftime("%Y%m%dT%H%M%SZ")
        path = "/" + quote(bucket + "/" + "/".join(filter(None, [prefix.strip("/"), name])), safe="/~")
        digest = hashlib.sha256(data).hexdigest()
        headers = {"cache-control": cache, "content-type": content_type, "host": host,
                   "x-amz-content-sha256": digest, "x-amz-date": moment}
        signed = ";".join(sorted(headers))
        canonical_headers = "".join(key + ":" + headers[key] + "\n" for key in sorted(headers))
        request = "\n".join(["PUT", path, "", canonical_headers, signed, digest])
        scope = date + "/auto/s3/aws4_request"
        message = "AWS4-HMAC-SHA256\n" + moment + "\n" + scope + "\n" + hashlib.sha256(request.encode()).hexdigest()
        signing = ("AWS4" + secret).encode()
        for part in [date, "auto", "s3", "aws4_request"]:
            signing = hmac.new(signing, part.encode(), hashlib.sha256).digest()
        signature = hmac.new(signing, message.encode(), hashlib.sha256).hexdigest()
        headers["Authorization"] = f"AWS4-HMAC-SHA256 Credential={access}/{scope}, SignedHeaders={signed}, Signature={signature}"
        with urlopen(Request("https://" + host + path, data=data, headers=headers, method="PUT"), timeout=120) as response:
            if response.status not in [200, 201]:
                raise SystemExit(f"Upload failed: HTTP {response.status}")
        print("Uploaded " + name, flush=True)
    print("Published catalog after all audio uploads completed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--library", default=Path("build/radio"), type=Path)
    parser.add_argument("--prefix", default="")
    args = parser.parse_args()
    upload(args.library, args.prefix)
