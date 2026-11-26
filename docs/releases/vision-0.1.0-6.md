# Vision Pro 0.1.0 (6) — TestFlight

Delivered October 19, 2026 to the existing internal **PulseCanvas Mac Beta**
group. App Store Connect reports **VALID / IN_BETA_TESTING**. Tester notes were
read back exactly; all 20 previously assigned builds remain in the group (21 total).

- Archived source: `1cfaad2721e258f740d6ca6918ff4c737102a863`
- App: `6821642700`; bundle: `com.protomota.pulsecanvas`; platform: `VISION_OS`
- Build ID / delivery UUID: `97f4b4ec-d41f-4015-b03e-6effa48bf822`
- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/97f4b4ec-d41f-4015-b03e-6effa48bf822)
- Native effects: **336**, with no external engine, community assets or updater.

## Changes

Radio's main Play button is enabled before any audio has loaded. It starts the
selected station, waits for an in-flight station-directory request, shows progress
while preparing a song, and then becomes Pause. Repeated taps during loading do
not start duplicate requests; pausing and resuming retains the same song. The
immersive Radio control uses the same observed playback button. Play Radio's
text and icon use an explicit vertically centered horizontal label.

The Studio card picker now contains search, filters, effect rows and a single
**Surprise me** action. Its selected-effect heading, shuffle/style/favorite button
strip and style controls have been removed. A selection dismisses the picker;
Surprise me chooses from the visible results and preserves all saved looks.
The picker retains a stable target card while playback advances. Its accessible
container keeps each child control separately identifiable.

Concurrent main changes, including launch hooks and station-request coalescing,
were integrated before archiving. Existing user storage and unrelated mobile
work were preserved.

## Verification

- Transport regression suite: passed, including cold Radio startup, repeated
  taps, pause/resume, Play during station loading, song advancement, category
  filtering and byte-preserved independent Studio storage.
- Simulator UI test: Radio Play is enabled without a song, starts a live station,
  becomes Pause and pauses successfully.
- Simulator UI test: card picker opens, has no style sliders, and Surprise me
  selects and dismisses it. Initial picker test failures exposed inherited parent
  accessibility identifiers; the corrected grouping passed the targeted rerun.
- Simulator build and final Release device archive: passed.
- Actual signed IPA: passed native-resource byte comparison, effect count,
  icons, legal/privacy resources, distribution profile and strict signature checks.
- Apple package validation and upload: succeeded with no errors.
- Processing, group membership, preserved prior builds, notes and internal
  TestFlight availability: verified through App Store Connect's API.
- Radio layout inspected in the simulator, including centered label/icon and
  active Play at zero duration. No physical-headset UI check was performed.

Rendering, movie saving and project format were not changed. Their separate
encoding/save/interchange suites were not repeated for this UI/Radio release.
Mac 1.1.4 remains **WAITING_FOR_REVIEW**; no public review submission was replaced.

## Local evidence

Artifacts remain outside Git under
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/0.1.0-6/`:

- IPA: `vision-export/PulseCanvas Vision.ipa` — **10,521,844 bytes**
- SHA-256: `ef6876bc13224b2832ddc0ea5aefa216f1066c62f04cdc24be713123f8e10d6b`
- `vision-delivery-receipt.json`, `vision-bundle-verification.json`
- `vision-testing-final.json`, `group-before.json`, `group-after.json`
- `vision-test-notes.txt`, `logs/*`, `vision-radio-ready.png`

## Next release version

At the owner's request, the Vision Pro project's marketing version is now
**1.0** for the next release. This does not change the already uploaded
**0.1.0 (6)** binary. Increment the build number before the next upload.
