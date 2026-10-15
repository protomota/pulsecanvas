# Creators update indicator

Creators Edition uses the existing signed Sparkle feed at
https://pulsecanvas.si/appcast.xml. A tan, round download-tray icon appears next
to **Random visualizer** when Sparkle finds a compatible newer version. Hover
for the version number; click to open Sparkle's download/install window.

The app checks silently at launch, on returning to the app, and every 15 minutes,
with foreground checks throttled to the same interval. These probes respect
**Automatically check for updates** in Settings. Scheduled discoveries use
Sparkle's gentle reminders instead of interrupting the editor with a dialog.
Manual **Check for Updates…** remains in the application menu and Settings.

Choosing **Remind Me Later** keeps the icon available. Skipping a version hides
its indicator and lets Sparkle honor that skip. A failed network check does not
erase an update that was already found. Clicking the icon uses the same Sparkle
controller and pinned signing key as the existing update flow.

The App Store edition and local development builds do not include this control.
App Store updates continue to come from Apple.

## Verification

Run `bash scripts/test-updater.sh` with the pinned Sparkle framework prepared.
The test starts a loopback-only fixture feed and exercises the real Sparkle
delegate flow in three isolated app bundles: a newer version is found, an
already-current app has no indicator, and automatic checks switched off send
no request. No fixture update is installed or published. Production preferences,
the live feed, and the signing key are untouched.

Also typecheck both editions and verify the control in an isolated Creators app:
confirm the tan icon beside the randomizer, open the update dialog, dismiss it,
and skip the test version. The App Store resource/dependency validation must
continue to exclude Sparkle.

## TestFlight assignment

Uploading to App Store Connect does not assign testers automatically. After
processing, add each new Store build to **PulseCanvas Mac Beta** and verify that
the group's build list says **Testing**. Creators website releases are separate
from that Apple-managed test channel.
