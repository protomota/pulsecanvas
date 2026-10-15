#!/usr/bin/env python3
"""Build a Finder-styled DMG, then inspect its real mounted resources/layout."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile

from dmgbuild import build_dmg
from ds_store import DSStore
from mac_alias import Alias

ROOT = Path(__file__).resolve().parent.parent
BACKGROUND = Path("Contents/Resources/PulseCanvasInstallerBackground.tiff")
APP_NAME = "PulseCanvas Studio.app"
DIRECT_CONFIG = json.loads((ROOT / "macOS/DirectRelease.json").read_text())


def bundle_inventory(app: Path) -> dict:
    inventory = {".": ("directory", app.stat().st_mode & 0o7777)}
    for path in app.rglob("*"):
        name = str(path.relative_to(app))
        if path.is_symlink():
            inventory[name] = ("symlink", path.lstat().st_mode & 0o7777, os.readlink(path))
        elif path.is_file():
            inventory[name] = ("file", path.stat().st_mode & 0o7777,
                               hashlib.sha256(path.read_bytes()).hexdigest())
        elif path.is_dir():
            inventory[name] = ("directory", path.stat().st_mode & 0o7777)
    return inventory


def install_background_reference(mount: Path) -> None:
    """Point Finder at signed bundle artwork without creating a root-level file."""
    with DSStore.open(str(mount / ".DS_Store"), "r+") as store:
        icons = store["."]["icvp"]
        icons["backgroundType"] = 2
        icons["backgroundImageAlias"] = Alias.for_file(str(mount / "PulseCanvas Studio.app" / BACKGROUND)).to_bytes()
        store["."]["icvp"] = icons


def verify(image: Path, source_app: Path, release_checks: bool = False) -> dict:
    if not __debug__:
        raise RuntimeError("Run the verifier without Python -O; assertions are required")
    with tempfile.TemporaryDirectory(prefix="pulsecanvas-dmg-inspection-") as temporary:
        mount = Path(temporary) / "volume"
        mount.mkdir()
        subprocess.run(["hdiutil", "attach", "-readonly", "-nobrowse", "-noautoopen",
                        "-mountpoint", str(mount), str(image)], check=True,
                       stdout=subprocess.DEVNULL)
        try:
            assert (mount / "PulseCanvas Studio.app").is_dir(), "App missing from installer"
            assert os.readlink(mount / "Applications") == "/Applications"
            visible = {path.name for path in mount.iterdir() if not path.name.startswith(".")}
            assert visible == {"PulseCanvas Studio.app", "Applications"}, visible
            root_items = sorted(path.name for path in mount.iterdir())
            allowed_metadata = {".DS_Store", ".Trashes", ".fseventsd", ".HFS+ Private Directory Data\r"}
            assert set(root_items) <= visible | allowed_metadata, root_items
            # Check Finder metadata in the final compressed image, not staging only.
            with DSStore.open(str(mount / ".DS_Store"), "r") as store:
                window = store["."]["bwsp"]
                icons = store["."]["icvp"]
                locations = {name: tuple(store[name]["Iloc"])
                             for name in ("PulseCanvas Studio.app", "Applications")}
                assert store["."]["icvl"] == (b"type", b"icnv")
            assert window["WindowBounds"] == "{{160, 160}, {720, 520}}", window
            for key in ("ShowToolbar", "ShowSidebar", "ShowStatusBar", "ShowPathbar", "ShowTabView"):
                assert not window[key], (key, window)
            assert icons["arrangeBy"] == "none"
            assert icons["iconSize"] == 104
            assert icons["textSize"] == 15
            assert icons["labelOnBottom"]
            assert (icons["scrollPositionX"], icons["scrollPositionY"]) == (0, 0)
            assert icons["backgroundType"] == 2
            assert locations == {"PulseCanvas Studio.app": (195, 230), "Applications": (525, 230)}
            assert not any(path.name.startswith(".background") for path in mount.iterdir())
            background = mount / "PulseCanvas Studio.app" / BACKGROUND
            assert background.is_file(), "Retina background missing"
            assert background.read_bytes() == (ROOT / "packaging/macos/background.tiff").read_bytes()
            alias = Alias.from_bytes(icons["backgroundImageAlias"])
            assert alias.target.filename == background.name, alias.target.filename
            assert alias.target.posix_path.lstrip("/") == str(Path(APP_NAME) / BACKGROUND), alias.target.posix_path
            # Compare links without following Sparkle framework directory aliases.
            assert bundle_inventory(source_app) == bundle_inventory(mount / "PulseCanvas Studio.app")
            subprocess.run(["codesign", "--verify", "--deep", "--strict", str(mount / "PulseCanvas Studio.app")], check=True)
            info = plistlib.loads((mount / "PulseCanvas Studio.app/Contents/Info.plist").read_bytes())
            assert info["CFBundleIdentifier"] == DIRECT_CONFIG["bundleIdentifier"]
            assert info["SUFeedURL"] == DIRECT_CONFIG["feedURL"]
            assert info["SUPublicEDKey"] == DIRECT_CONFIG["sparklePublicKey"]
            if release_checks:
                signature = subprocess.run(["codesign", "--display", "--verbose=4", str(mount / APP_NAME)],
                                           check=True, capture_output=True, text=True).stderr
                assert "TeamIdentifier=22HV69L32T" in signature, "Wrong signing team"
                assert "Authority=Developer ID Application: Protomota, LLC (22HV69L32T)" in signature, "Developer ID signature required"
                subprocess.run(["codesign", "--verify", "--strict", str(image)], check=True)
                subprocess.run(["xcrun", "stapler", "validate", str(image)], check=True)
                subprocess.run(["spctl", "--assess", "--type", "execute", "--verbose=2",
                                str(mount / APP_NAME)], check=True)
            return {"window_size": [720, 520], "icon_locations": locations,
                    "icon_size": 104, "text_size": 15, "scroll_position": [0, 0],
                    "background": str(Path("PulseCanvas Studio.app") / BACKGROUND),
                    "background_sha256": hashlib.sha256(background.read_bytes()).hexdigest(),
                    "root_items": root_items, "direct_updater_configuration_matches": True,
                    "release_checks_passed": release_checks,
                    "app_version": info.get("CFBundleShortVersionString"),
                    "app_build": info.get("CFBundleVersion"),
                    "app_bytes_match": True, "applications_target": "/Applications"}
        finally:
            subprocess.run(["hdiutil", "detach", str(mount)], check=True,
                           stdout=subprocess.DEVNULL)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--release-checks", action="store_true",
                        help="Also require DMG signature/staple and mounted app Gatekeeper acceptance")
    args = parser.parse_args()
    app, image = args.app.resolve(), args.output.resolve()
    if app.name != "PulseCanvas Studio.app" or not (app / "Contents/Info.plist").is_file():
        parser.error("--app must be an existing PulseCanvas Studio.app bundle")
    if not (app / BACKGROUND).is_file():
        parser.error("Embed packaging/macos/background.tiff in the app's Resources before signing")
    if (app / BACKGROUND).read_bytes() != (ROOT / "packaging/macos/background.tiff").read_bytes():
        parser.error("App background must match the committed installer artwork")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    if not args.verify_only:
        if image.exists():
            parser.error("--output already exists; choose a fresh output path")
        image.parent.mkdir(parents=True, exist_ok=True)
        mounted = {}
        def remember_mount(mount_point: str, options: dict) -> None:
            mounted["path"] = Path(mount_point)
        def finish_layout(event: dict) -> None:
            if event.get("type") == "operation::finished" and event.get("operation") == "dsstore::create":
                install_background_reference(mounted["path"])
        build_dmg(str(image), "PulseCanvas Studio", settings_file=str(ROOT / "packaging/macos/settings.py"),
                  defines={"app": str(app)},
                  settings={"create_hook": remember_mount}, callback=finish_layout)
    report = verify(image, app, args.release_checks)
    image.with_suffix(".layout.json").write_text(json.dumps(report, indent=2) + "\n")
    print("Installer layout verified:", json.dumps(report))


if __name__ == "__main__":
    main()
