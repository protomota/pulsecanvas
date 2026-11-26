#!/usr/bin/env python3
"""Offline fixtures only: no credentials, signing or Apple account calls."""
from datetime import datetime, timedelta, timezone
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("cloud_profile", Path(__file__).with_name("prepare-creators-icloud.py"))
cloud = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cloud)


class ProfileTests(unittest.TestCase):
    def setUp(self) -> None:
        self.profile = {
            "ExpirationDate": datetime.now(timezone.utc) + timedelta(days=1),
            "TeamIdentifier": [cloud.TEAM], "ProvisionsAllDevices": True,
            "Entitlements": {
                "com.apple.application-identifier": cloud.TEAM + ".com.protomota.pulsecanvas",
                "com.apple.developer.icloud-services": ["CloudDocuments"],
                "com.apple.developer.icloud-container-identifiers": [cloud.CONTAINER],
                "com.apple.developer.ubiquity-container-identifiers": [cloud.CONTAINER],
            },
        }

    def test_valid_profile(self) -> None:
        result = cloud.entitlements(self.profile, "com.protomota.pulsecanvas")
        self.assertEqual(result["com.apple.developer.icloud-services"], ["CloudDocuments"])
        self.assertNotIn("get-task-allow", result)

    def test_apple_service_wildcard_signs_only_cloud_documents(self) -> None:
        entitlements = self.profile["Entitlements"]
        entitlements["com.apple.developer.icloud-services"] = "*"
        result = cloud.entitlements(self.profile, "com.protomota.pulsecanvas")
        self.assertEqual(result["com.apple.developer.icloud-services"], ["CloudDocuments"])
        entitlements["com.apple.developer.icloud-container-identifiers"] = "*"
        with self.assertRaises(ValueError):
            cloud.entitlements(self.profile, "com.protomota.pulsecanvas")

    def test_invalid_identity_or_type(self) -> None:
        for key, value in [("TeamIdentifier", ["OTHERTEAM"]), ("ProvisionsAllDevices", False),
                           ("ExpirationDate", datetime.now(timezone.utc) - timedelta(days=1))]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                cloud.entitlements(dict(self.profile, **{key: value}), "com.protomota.pulsecanvas")
        with self.assertRaises(ValueError):
            cloud.entitlements(self.profile, "wrong.bundle")

    def test_missing_capability_or_debug(self) -> None:
        del self.profile["Entitlements"]["com.apple.developer.ubiquity-container-identifiers"]
        with self.assertRaises(ValueError):
            cloud.entitlements(self.profile, "com.protomota.pulsecanvas")
        self.setUp()
        self.profile["Entitlements"]["get-task-allow"] = True
        with self.assertRaises(ValueError):
            cloud.entitlements(self.profile, "com.protomota.pulsecanvas")


if __name__ == "__main__":
    unittest.main()
