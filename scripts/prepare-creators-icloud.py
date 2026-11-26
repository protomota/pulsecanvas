#!/usr/bin/env python3
"""Validate a Developer ID profile before attaching iCloud signing entitlements."""
from datetime import datetime, timezone
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys

CONTAINER = "iCloud.com.protomota.pulsecanvas"
TEAM = "22HV69L32T"


def entitlements(profile: dict, bundle_id: str) -> dict:
    """Return only the capabilities needed by this app; fail before changing files."""
    expiry = profile.get("ExpirationDate")
    if not isinstance(expiry, datetime) or expiry.replace(tzinfo=timezone.utc) <= datetime.now(timezone.utc):
        raise ValueError("The Developer ID provisioning profile has expired.")
    if profile.get("TeamIdentifier") != [TEAM] or profile.get("ProvisionsAllDevices") is not True:
        raise ValueError("Use a Protomota Developer ID distribution profile, not a development or App Store profile.")
    allowed = profile.get("Entitlements", {})
    app_key = next((key for key in ("com.apple.application-identifier", "application-identifier") if key in allowed), None)
    if app_key is None or allowed[app_key] != TEAM + "." + bundle_id or allowed.get("get-task-allow") is True:
        raise ValueError("The profile must match the exact release bundle ID and disable debugging.")
    result = {app_key: allowed[app_key], "com.apple.developer.team-identifier": TEAM}
    required = {
        "com.apple.developer.ubiquity-container-identifiers": [CONTAINER],
        "com.apple.developer.icloud-container-identifiers": [CONTAINER],
        "com.apple.developer.icloud-services": ["CloudDocuments"],
    }
    for key, values in required.items():
        grant = allowed.get(key)
        # Apple may authorize the service name with a wildcard. Sign only CloudDocuments.
        services_wildcard = key == "com.apple.developer.icloud-services" and grant == "*"
        if not services_wildcard and (not isinstance(grant, list) or not set(values).issubset(grant)):
            raise ValueError("The profile is missing the PulseCanvas iCloud Documents capability: " + key)
        result[key] = values
    environment = allowed.get("com.apple.developer.icloud-container-environment")
    if environment:
        if environment != "Production" and "Production" not in environment:
            raise ValueError("The distribution profile must permit the Production iCloud environment.")
        result["com.apple.developer.icloud-container-environment"] = "Production"
    return result


def main() -> None:
    app, profile_path, output = map(Path, sys.argv[1:])
    info_path = app / "Contents/Info.plist"
    info = plistlib.loads(info_path.read_bytes())
    decoded = subprocess.run(["security", "cms", "-D", "-i", str(profile_path)], check=True, capture_output=True).stdout
    signing = entitlements(plistlib.loads(decoded), info["CFBundleIdentifier"])
    template = Path(__file__).resolve().parents[1] / "macOS/Info.plist"
    info["NSUbiquitousContainers"] = plistlib.loads(template.read_bytes())["NSUbiquitousContainers"]
    output.write_bytes(plistlib.dumps(signing))
    shutil.copyfile(profile_path, app / "Contents/embedded.provisionprofile")
    info_path.write_bytes(plistlib.dumps(info))
    print("Validated Creators iCloud profile and prepared signing entitlements.")


if __name__ == "__main__":
    main()
